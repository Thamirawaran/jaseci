"""Implementation of MCP client and tool wrapper.

Uses the official mcp Python library for protocol-correct communication
across all transports. Bridges async MCP calls into byllm's synchronous
ReAct loop via a background thread running an anyio event loop.
"""

import asyncio;
import json;
import logging;
import threading;
import from typing { Any }
import from byllm.exceptions { McpError }

glob logger = logging.getLogger("byllm.mcp");

# ─── Async bridge helpers ────────────────────────────────────────────────────
# byllm is fully synchronous. The mcp library is fully async (anyio).
# We bridge by running a dedicated event loop in a background daemon thread.
# Sync methods post coroutines to this loop and block on the result.

"""Start a new event loop in the current thread (used as thread target)."""
def _run_loop(loop: asyncio.AbstractEventLoop) -> None {
    asyncio.set_event_loop(loop);
    loop.run_forever();
}

"""Run an async coroutine from sync code via the background loop."""
def _run_in_loop(loop: asyncio.AbstractEventLoop, coro: object) -> object {
    future = asyncio.run_coroutine_threadsafe(coro, loop);
    return future.result(timeout=120);
}

# ─── McpClient Implementation ───────────────────────────────────────────────

impl McpClient.connect -> None {
    if self._connected {
        return;
    }
    try {
        import from mcp.client.session { ClientSession }
    } except ImportError as e {
        raise McpError(
            message="MCP support requires the 'mcp' package. "
            "Install it with: pip install byllm[mcp]"
        );
    }
    # Resolve transport type
    transport_type = self.transport;
    if transport_type == "auto" {
        if self.command {
            transport_type = "stdio";
        } elif self.url {
            transport_type = "streamable-http";
        } else {
            raise McpError(
                message="McpClient requires either 'command' (stdio) or 'url' (HTTP). "
                "Neither was provided."
            );
        }
    }
    # Create background event loop
    self._loop = asyncio.new_event_loop();
    self._loop_thread = threading.Thread(
        target=_run_loop, args=(self._loop,), daemon=True
    );
    self._loop_thread.start();
    try {
        _run_in_loop(self._loop, self._async_connect(transport_type));
    } except Exception as e {
        self._shutdown_loop();
        if isinstance(e, McpError) {
            raise;
        }
        raise McpError(message=f"Failed to connect to MCP server: {e}");
    }
}

impl McpClient.get_tools(names: list[str] | None = None) -> list {
    if not self._connected {
        self.connect();
    }
    if names is None {
        return list(self._tools_cache);
    }
    names_set = set(names);
    return [t for t in self._tools_cache if t.name in names_set];
}

impl McpClient.call_tool(name: str, arguments: dict[str, Any]) -> str {
    if not self._connected {
        self.connect();
    }
    try {
        return _run_in_loop(
            self._loop, self._async_call_tool(name, arguments)
        );
    } except McpError {
        raise;
    } except Exception as e {
        raise McpError(message=f"MCP tool '{name}' call failed: {e}");
    }
}

impl McpClient.close -> None {
    if not self._connected {
        return;
    }
    try {
        _run_in_loop(self._loop, self._async_close());
    } except Exception as e {
        logger.debug(f"Error during MCP close: {e}");
    }
    self._shutdown_loop();
    self._connected = False;
    self._tools_cache = [];
    self._session = None;
    self._transport_ctx = None;
    self._session_ctx = None;
}

# ─── McpClient async internals ──────────────────────────────────────────────
# These are module-level async functions that McpClient delegates to.

"""Async connect: create transport, session, initialize, discover tools."""
async def _mcp_async_connect(client: McpClient, transport_type: str) -> None {
    import from mcp.client.session { ClientSession }
    import from datetime { timedelta }

    # Create transport based on type
    if transport_type == "stdio" {
        import from mcp.client.stdio { StdioServerParameters, stdio_client }
        env = client.env if client.env else None;
        server_params = StdioServerParameters(
            command=client.command, args=client.args, env=env
        );
        client._transport_ctx = stdio_client(server_params);
        streams = await client._transport_ctx.__aenter__();
        read_stream = streams[0];
        write_stream = streams[1];
    } elif transport_type == "sse" {
        import from mcp.client.sse { sse_client }
        client._transport_ctx = sse_client(
            client.url, headers=client.headers or None,
            timeout=float(client.timeout)
        );
        streams = await client._transport_ctx.__aenter__();
        read_stream = streams[0];
        write_stream = streams[1];
    } elif transport_type == "streamable-http" {
        import from mcp.client.streamable_http { streamable_http_client }
        client._transport_ctx = streamable_http_client(
            client.url, headers=client.headers or None
        );
        streams = await client._transport_ctx.__aenter__();
        read_stream = streams[0];
        write_stream = streams[1];
    } else {
        raise McpError(
            message=f"Unknown transport type: '{transport_type}'. "
            "Use 'stdio', 'sse', or 'streamable-http'."
        );
    }
    # Create and initialize session
    client._session_ctx = ClientSession(
        read_stream, write_stream,
        read_timeout_seconds=timedelta(seconds=client.timeout)
    );
    client._session = await client._session_ctx.__aenter__();
    await client._session.initialize();

    # Discover tools
    tools_result = await client._session.list_tools();
    import from byllm.mcp { McpTool }
    client._tools_cache = [
        McpTool(
            name=t.name,
            description=t.description or "",
            input_schema=t.inputSchema if hasattr(t, 'inputSchema') else {},
            _client=client
        )
        for t in tools_result.tools
    ];
    client._connected = True;
    logger.info(
        f"[MCP] Connected via {transport_type} — "
        f"{len(client._tools_cache)} tool(s) discovered."
    );
}

"""Async call_tool: delegate to session."""
async def _mcp_async_call_tool(
    client: McpClient, name: str, arguments: dict[str, Any]
) -> str {
    result = await client._session.call_tool(name, arguments);
    parts: list[str] = [];
    for item in (result.content or []) {
        if hasattr(item, 'text') {
            parts.append(item.text);
        } else {
            parts.append(str(item));
        }
    }
    return "\n".join(parts) if parts else "MCP tool returned no content.";
}

"""Async close: tear down session and transport."""
async def _mcp_async_close(client: McpClient) -> None {
    if client._session_ctx is not None {
        try {
            await client._session_ctx.__aexit__(None, None, None);
        } except Exception as e {
            logger.debug(f"Session close error: {e}");
        }
    }
    if client._transport_ctx is not None {
        try {
            await client._transport_ctx.__aexit__(None, None, None);
        } except Exception as e {
            logger.debug(f"Transport close error: {e}");
        }
    }
}

"""Shut down the background event loop and thread."""
def _mcp_shutdown_loop(client: McpClient) -> None {
    if client._loop is not None and client._loop.is_running() {
        client._loop.call_soon_threadsafe(client._loop.stop);
    }
    if client._loop_thread is not None and client._loop_thread.is_alive() {
        client._loop_thread.join(timeout=5);
    }
    if client._loop is not None and not client._loop.is_closed() {
        client._loop.close();
    }
    client._loop = None;
    client._loop_thread = None;
}

# Wire async helpers as bound methods on McpClient.
# Jac impl blocks can only implement methods declared in the type.
# These are internal helpers called via the declared public methods.

:py:
def _async_connect_bound(self, transport_type):
    return _mcp_async_connect(self, transport_type)

def _async_call_tool_bound(self, name, arguments):
    return _mcp_async_call_tool(self, name, arguments)

def _async_close_bound(self):
    return _mcp_async_close(self)

def _shutdown_loop_bound(self):
    return _mcp_shutdown_loop(self)

McpClient._async_connect = _async_connect_bound
McpClient._async_call_tool = _async_call_tool_bound
McpClient._async_close = _async_close_bound
McpClient._shutdown_loop = _shutdown_loop_bound
:py:

# ─── McpTool Implementation ─────────────────────────────────────────────────

impl McpTool.__call__(**kwargs: Any) -> str {
    try {
        return self._client.call_tool(self.name, kwargs);
    } except Exception as e {
        logger.exception("MCP tool execution failed");
        return f"Tool error: {e}";
    }
}

impl McpTool.get_name -> str {
    return self.name;
}

impl McpTool.get_json_schema -> dict[str, Any] {
    return {
        "type": "function",
        "function": {
            "name": self.name,
            "description": self.description,
            "parameters": self.input_schema
        }
    };
}

impl McpTool.parse_arguments(args_json: dict) -> dict {
    return args_json;
}

impl McpTool.is_finish_tool -> bool {
    return False;
}
