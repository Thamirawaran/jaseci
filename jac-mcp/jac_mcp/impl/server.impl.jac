"""Implementation of MCP Server core."""

import from typing { Any }
import asyncio;
import sys;
import logging;

glob logger = logging.getLogger("jac_mcp");

"""Start the MCP server with configured transport."""
impl JacMcpServer.start -> None {
    asyncio.run(_async_start(self));
}

"""Stop the MCP server gracefully."""
impl JacMcpServer.stop -> None {
    return;
}

"""Server instructions for minimal profile (small models like Haiku)."""
glob SERVER_INSTRUCTIONS_MINIMAL: str = """You are connected to jac-mcp - the source of truth for the Jac programming language.

Jac is its OWN language - NOT Python. Do not guess syntax from training data.

WORKFLOW:
1. Write code, then call fix_error to validate and get fix suggestions
2. Use get_doc_section for specific syntax questions (lighter than full docs)
3. Do not present code to the user until fix_error returns valid=true""";

"""Server instructions for standard profile (mid-range models like Sonnet)."""
glob SERVER_INSTRUCTIONS_STANDARD: str = """You are connected to jac-mcp - the source of truth for the Jac programming language.

Jac is its OWN language - NOT Python, not JavaScript. Do not guess syntax from training data.

WORKFLOW:
1. Call recommend_workflow(task="<your task>") to get recommended steps and resources
2. Use get_doc_section to read relevant sections (lighter than full docs)
3. Use get_example_file to read specific example files
4. Write code, then call fix_error to validate and fix issues
5. Do not present code to the user until it passes validation

AVAILABLE PROMPT TEMPLATES (use get_prompt):
- write_client_component: generates cl {} component with reactive state and JSX
- write_walker_endpoint: generates walker:pub or walker:priv HTTP endpoint
- write_auth_flow: generates login/signup pages with built-in auth
- write_fullstack_feature: generates coordinated server walkers + client UI""";

"""Server instructions for full profile (large models like Opus)."""
glob SERVER_INSTRUCTIONS_FULL: str = """You are connected to the jac-mcp server - the source of truth for the Jac programming language.

Jac is its OWN language - not Python, not JavaScript. Do not guess syntax from training data.

WORKFLOW:
1. Call recommend_workflow(task="<your task>") to get recommended steps, resources, and tools
2. Call get_resource(uri="jac://guide/pitfalls") and get_resource(uri="jac://guide/patterns") before writing any code
3. Fetch task-specific resources recommended by step 1 (e.g. pitfalls_client, patterns_fullstack)
4. Use get_doc_section to read only the relevant section of large docs instead of the full document
5. Use get_example_file to read specific example files instead of entire categories
6. Write code, then call validate_jac to verify it compiles
7. If validation fails, use fix_error (combines validate + explain in one call) or inspect_validation (groups errors by root cause)
8. Do not present code to the user until it passes validation

AVAILABLE PROMPT TEMPLATES (use get_prompt):
- write_client_component: generates cl {} component with reactive state and JSX
- write_walker_endpoint: generates walker:pub or walker:priv HTTP endpoint
- write_auth_flow: generates login/signup pages with built-in auth
- write_fullstack_feature: generates coordinated server walkers + client UI""";

"""Get server instructions based on profile."""
def _get_server_instructions(profile: str) -> str {
    if profile == "minimal" {
        return SERVER_INSTRUCTIONS_MINIMAL;
    } elif profile == "standard" {
        return SERVER_INSTRUCTIONS_STANDARD;
    }
    return SERVER_INSTRUCTIONS_FULL;
}

"""Internal async server startup."""
async def _async_start(srv: JacMcpServer) {
    import from mcp.server { Server }
    import from mcp.types {
        Resource,
        Tool,
        TextContent,
        Prompt,
        PromptMessage,
        PromptArgument,
        GetPromptResult
    }
    import from jac_mcp.resources { ResourceProvider }
    import from jac_mcp.tools { ToolProvider }
    import from jac_mcp.prompts { PromptProvider }
    import json;

    # Determine profile for instructions
    import os;
    _srv_profile = os.environ.get("JAC_MCP_PROFILE", "");
    if not _srv_profile {
        try {
            import from jaclang.project.config { get_config }
            _jac_cfg = get_config();
            if _jac_cfg {
                _srv_profile = str(
                    _jac_cfg.get_plugin_config("mcp").get("profile", "full")
                );
            } else {
                _srv_profile = "full";
            }
        } except Exception {
            _srv_profile = "full";
        }
    }
    server = Server("jac-mcp", instructions=_get_server_instructions(_srv_profile));

    # Initialize providers
    rp = ResourceProvider();
    rp.index_resources();
    tp = ToolProvider();
    pp = PromptProvider();

    @server.list_resources()
    async def handle_list_resources -> list {
        items = rp.list_resources();
        result: list = [];
        for item in items {
            result.append(
                Resource(
                    uri=item["uri"],
                    name=item["name"],
                    description=item.get("description", ""),
                    mimeType=item.get("mimeType", "text/plain")
                )
            );
        }
        return result;
    }

    @server.read_resource()
    async def handle_read_resource(uri: object) -> str {
        uri_str = str(uri);
        content = rp.read_resource(uri_str);
        return content;
    }

    @server.list_tools()
    async def handle_list_tools -> list {
        items = tp.list_tools();
        result: list = [];
        for item in items {
            result.append(
                Tool(
                    name=item["name"],
                    description=item["description"],
                    inputSchema=item.get(
                        "inputSchema", {"type": "object", "properties": {}}
                    )
                )
            );
        }
        return result;
    }

    @server.call_tool()
    async def handle_call_tool(name: str, arguments: dict | None = None) -> list {
        args = arguments or {};
        tool_result = tp.call_tool(name, args);
        return [TextContent(type="text", text=json.dumps(tool_result, indent=2))];
    }

    @server.list_prompts()
    async def handle_list_prompts -> list {
        items = pp.list_prompts();
        result: list = [];
        for item in items {
            prompt_args: list = [];
            for arg in item.get("arguments", []) {
                prompt_args.append(
                    PromptArgument(
                        name=arg["name"],
                        description=arg.get("description", ""),
                        required=arg.get("required", False)
                    )
                );
            }
            result.append(
                Prompt(
                    name=item["name"],
                    description=item["description"],
                    arguments=prompt_args
                )
            );
        }
        return result;
    }

    @server.get_prompt()
    async def handle_get_prompt(
        name: str, arguments: dict | None = None
    ) -> GetPromptResult {
        args = arguments or {};
        prompt_result = pp.get_prompt(name, args);
        messages: list = [];
        for msg in prompt_result.get("messages", []) {
            messages.append(
                PromptMessage(
                    role=msg["role"],
                    content=TextContent(type="text", text=msg["content"])
                )
            );
        }
        return GetPromptResult(
            description=prompt_result.get("description", ""), messages=messages
        );
    }

    # Start transport
    if srv.transport == "stdio" {
        import from mcp.server.stdio { stdio_server }
        async with stdio_server() as (read_stream, write_stream) {
            await server.run(
                read_stream, write_stream, server.create_initialization_options()
            );
        }
    } elif srv.transport == "sse" {
        try {
            import from mcp.server.sse { SseServerTransport }
            import from starlette.applications { Starlette }
            import from starlette.routing { Mount, Route }
            import from starlette.responses { Response }
            import uvicorn;

            sse = SseServerTransport("/messages/");

            async def handle_sse(request: object) -> object {
                async with sse.connect_sse(
                    request.scope, request.receive, request._send
                ) as streams {
                    await server.run(
                        streams[0], streams[1], server.create_initialization_options()
                    );
                }
                return Response();
            }

            starlette_app = Starlette(
                routes=[
                    Route("/sse", endpoint=handle_sse),
                    Mount("/messages", app=sse.handle_post_message)
                ]
            );

            config = uvicorn.Config(
                starlette_app, host=srv.host, port=srv.port, log_level="info"
            );
            uvi_srv = uvicorn.Server(config);
            await uvi_srv.serve();
        } except ImportError as e {
            logger.error(f"SSE transport requires uvicorn and starlette: {e}");
            logger.error("Install with: pip install uvicorn starlette");
            sys.exit(1);
        }
    } elif srv.transport == "streamable-http" {
        try {
            import from mcp.server.streamable_http_manager {
                StreamableHTTPSessionManager
            }
            import from starlette.applications { Starlette }
            import from starlette.routing { Mount }
            import contextlib;
            import uvicorn;

            session_manager = StreamableHTTPSessionManager(
                app=server, json_response=True, stateless=False
            );

            @contextlib.asynccontextmanager
            async def lifespan(app: object) -> object {
                async with session_manager.run() {
                    yield ;
                }
            }

            starlette_app = Starlette(
                lifespan=lifespan,
                routes=[Mount("/mcp", app=session_manager.handle_request)]
            );

            config = uvicorn.Config(
                starlette_app, host=srv.host, port=srv.port, log_level="info"
            );
            uvi_srv = uvicorn.Server(config);
            await uvi_srv.serve();
        } except ImportError as e {
            logger.error(
                f"Streamable HTTP transport requires uvicorn and starlette: {e}"
            );
            logger.error("Install with: pip install uvicorn starlette");
            sys.exit(1);
        }
    } else {
        logger.error(f"Unknown transport: {srv.transport}");
        sys.exit(1);
    }
}
