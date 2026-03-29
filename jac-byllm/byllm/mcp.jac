"""MCP (Model Context Protocol) integration for byLLM.

Provides McpTool and McpClient for using remote MCP server tools
in by llm() calls, alongside local tools.

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

Supports three transports:
  - stdio: Local subprocess (set command + args)
  - sse: Remote SSE server (set url, transport="sse")
  - streamable-http: Remote HTTP (set url, default for HTTP)

Internally runs one background event loop thread to keep MCP
transport alive between connect() and close().
"""
obj McpClient {
    has command: str = "",
        args: list[str] = [],
        env: dict[str, str] = {},
        url: str = "",
        headers: dict[str, str] = {},
        transport: str = "auto",
        timeout: int = 30;

    def connect -> None;
    def get_tools(names: list[str] | None = None) -> list;
    def call_tool(name: str, arguments: dict[str, Any]) -> str;
    def close -> None;
}

"""MCP tool wrapper with the same interface as byllm's Tool."""
obj McpTool {
    has name: str,
        description: str,
        input_schema: dict,
        _client: McpClient;

    def __call__(**kwargs: Any) -> str;
    def get_name -> str;
    def get_json_schema -> dict[str, Any];
    def parse_arguments(args_json: dict) -> dict;
    def is_finish_tool -> bool;
}
