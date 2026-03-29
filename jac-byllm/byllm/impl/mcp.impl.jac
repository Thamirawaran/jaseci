"""Implementation of MCP client and tool wrapper."""

import asyncio;
import logging;
import from typing { Any }
import from byllm.exceptions { McpError }

glob logger = logging.getLogger("byllm.mcp");

# ─── Async internals ────────────────────────────────────────────────────────
# byllm is currently synchronous. We use asyncio.run() to bridge.
# This will be replaced when byllm adds native async support.

async def _async_connect(client: McpClient, transport_type: str) -> None {
    import from mcp.client.session { ClientSession }
    import from mcp.client.stdio { StdioServerParameters, stdio_client }
    import from mcp.client.sse { sse_client }
    import from mcp.client.streamable_http { streamable_http_client }
    import from datetime { timedelta }
    import from byllm.mcp { McpTool }

    (read_stream, write_stream) = await _open_transport(
        client, transport_type,
        StdioServerParameters, stdio_client,
        sse_client, streamable_http_client
    );

    session_ctx = ClientSession(
        read_stream, write_stream,
        read_timeout_seconds=timedelta(seconds=client.timeout)
    );
    client._session = await session_ctx.__aenter__();
    client._cleanup_fns.append(session_ctx.__aexit__);
    await client._session.initialize();

    tools_result = await client._session.list_tools();
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

async def _async_call_tool(
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

async def _async_close(client: McpClient) -> None {
    for cleanup_fn in reversed(client._cleanup_fns) {
        try {
            await cleanup_fn(None, None, None);
        } except Exception as e {
            logger.debug(f"Cleanup error: {e}");
        }
    }
}

"""Open an MCP transport and return (read_stream, write_stream)."""
async def _open_transport(
    client: McpClient,
    transport_type: str,
    StdioServerParameters: type,
    stdio_client: object,
    sse_client: object,
    streamable_http_client: object
) -> tuple {
    ctx: object = None;
    if transport_type == "stdio" {
        env = client.env if client.env else None;
        params = StdioServerParameters(
            command=client.command, args=client.args, env=env
        );
        ctx = stdio_client(params);
    } elif transport_type == "sse" {
        ctx = sse_client(
            client.url, headers=client.headers or None,
            timeout=float(client.timeout)
        );
    } elif transport_type == "streamable-http" {
        ctx = streamable_http_client(
            client.url, headers=client.headers or None
        );
    } else {
        raise McpError(
            message=f"Unknown transport: '{transport_type}'. "
            "Use 'stdio', 'sse', or 'streamable-http'."
        );
    }
    streams = await ctx.__aenter__();
    client._cleanup_fns.append(ctx.__aexit__);
    return (streams[0], streams[1]);
}

# ─── McpClient sync methods ─────────────────────────────────────────────────

impl McpClient.connect -> None {
    if self._connected {
        return;
    }
    try {
        import from mcp.client.session { ClientSession }
    } except ImportError {
        raise McpError(
            message="MCP support requires the 'mcp' package. "
            "Install it with: pip install byllm[mcp]"
        );
    }
    transport_type = self.transport;
    if transport_type == "auto" {
        if self.command {
            transport_type = "stdio";
        } elif self.url {
            transport_type = "streamable-http";
        } else {
            raise McpError(
                message="McpClient requires either 'command' (stdio) or 'url' (HTTP)."
            );
        }
    }
    try {
        asyncio.run(_async_connect(self, transport_type));
    } except McpError {
        raise;
    } except Exception as e {
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
        return asyncio.run(_async_call_tool(self, name, arguments));
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
        asyncio.run(_async_close(self));
    } except Exception as e {
        logger.debug(f"Error during MCP close: {e}");
    }
    self._connected = False;
    self._tools_cache = [];
    self._session = None;
    self._cleanup_fns = [];
}

# ─── McpTool ────────────────────────────────────────────────────────────────

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
