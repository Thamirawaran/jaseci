"""MCP (Model Context Protocol) integration for byLLM.

Provides McpTool — a Tool-compatible wrapper that executes tools on a
remote MCP server instead of calling a local function — and McpClient,
a connection manager that handles MCP server lifecycle across all
transports (stdio, SSE, Streamable HTTP).

Usage:
    import from byllm.lib { Model, McpClient }

    glob llm = Model(model_name="gpt-4o");
    glob mcp = McpClient(command="jac", args=["mcp"]);

    def answer(q: str) -> str by llm(
        tools=[*mcp.get_tools()]
    );
"""

import from typing { Any }

"""MCP server connection manager.

Connects to an MCP server via any supported transport, manages the
session lifecycle, and provides synchronous access to tool discovery
and invocation. Uses a background thread with an anyio event loop
to bridge byllm's synchronous ReAct loop with the async MCP protocol.

Supports three connection modes:
  - stdio: Local subprocess (set command + args)
  - sse: Remote Server-Sent Events (set url, transport="sse")
  - streamable-http: Remote HTTP (set url, default for HTTP)
"""
obj McpClient {
    # Stdio transport (local subprocess)
    has command: str = "",
        args: list[str] = [],
        env: dict[str, str] = {};

    # HTTP transports (remote servers)
    has url: str = "",
        headers: dict[str, str] = {};

    # Shared config
    has transport: str = "auto",
        timeout: int = 30;

    # Internal state (managed by implementation)
    has _connected: bool = False,
        _tools_cache: list = [],
        _loop_thread: object = None,
        _loop: object = None,
        _session: object = None,
        _transport_ctx: object = None,
        _session_ctx: object = None;

    """Connect to the MCP server and discover tools."""
    def connect -> None;

    """Return cached McpTool list, optionally filtered by name."""
    def get_tools(names: list[str] | None = None) -> list;

    """Call a tool by name. Returns the result as a string."""
    def call_tool(name: str, arguments: dict[str, Any]) -> str;

    """Disconnect and clean up all resources."""
    def close -> None;
}

"""An MCP-backed tool that wraps a remote MCP server tool as a local callable.

Implements the same interface as byllm's Tool so it can be used
interchangeably in the ReAct loop. The key difference: __call__
sends a JSON-RPC tools/call request to the MCP server instead of
invoking a local Python function.

The JSON schema from MCP's tools/list response is passed through
directly to the LLM — no type introspection needed.
"""
obj McpTool {
    has name: str,
        description: str,
        input_schema: dict,
        _client: McpClient;

    """Execute the tool on the MCP server."""
    def __call__(**kwargs: Any) -> str;

    """Return the tool name."""
    def get_name -> str;

    """Return the OpenAI-format function schema."""
    def get_json_schema -> dict[str, Any];

    """Parse arguments from the LLM's JSON response."""
    def parse_arguments(args_json: dict) -> dict;

    """MCP tools are never finish tools."""
    def is_finish_tool -> bool;
}
