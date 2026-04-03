"""Implementation of MCP tools."""

import from typing { Any }
import re;

"""Read MCP plugin config from jac.toml [plugins.mcp] section."""
def _get_mcp_config -> dict[str, object] {
    try {
        import from jaclang.project.config { get_config }
        jac_cfg = get_config();
        if jac_cfg {
            return jac_cfg.get_plugin_config("mcp");
        }
    } except Exception { }
    return {};
}

"""Return list of available tools with schemas, filtered by [plugins.mcp] config."""
impl ToolProvider.list_tools -> list[dict[str, Any]] {
    all_tools: list[dict[str, Any]] = [
        {
            "name": "validate_jac",
            "description": "Validate Jac code with full type checking. Returns structured errors and warnings.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "code": {
                        "type": "string",
                        "description": "Jac source code to validate"
                    },
                    "filename": {
                        "type": "string",
                        "description": "Optional filename for error messages",
                        "default": "snippet.jac"
                    }
                },
                "required": ["code"]
            }
        },
        {
            "name": "check_syntax",
            "description": "Parse-only syntax check (no type checking). Faster than validate_jac.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "code": {
                        "type": "string",
                        "description": "Jac source code to check"
                    }
                },
                "required": ["code"]
            }
        },
        {
            "name": "format_jac",
            "description": "Format Jac code to standard style.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "code": {
                        "type": "string",
                        "description": "Jac source code to format"
                    }
                },
                "required": ["code"]
            }
        },
        {
            "name": "py_to_jac",
            "description": "Transpile Python code to Jac. Output may need manual refinement.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "python_code": {
                        "type": "string",
                        "description": "Python source code to convert"
                    }
                },
                "required": ["python_code"]
            }
        },
        {
            "name": "explain_error",
            "description": "Explain a Jac compiler error with category, root cause, and fix example.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "error_message": {
                        "type": "string",
                        "description": "The error message to explain"
                    }
                },
                "required": ["error_message"]
            }
        },
        {
            "name": "list_examples",
            "description": "List available Jac example categories with descriptions.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "category": {
                        "type": "string",
                        "description": "Optional category filter"
                    }
                }
            }
        },
        {
            "name": "get_example",
            "description": "Get all .jac files from an example category. Call list_examples first to see valid names.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "name": {
                        "type": "string",
                        "description": "Example category name. Valid: chess, data_spatial, guess_game, littleX, manual_code, medical, micro, plugins, rpg_game, shopping_cart",
                        "enum": [
                            "chess",
                            "data_spatial",
                            "guess_game",
                            "littleX",
                            "manual_code",
                            "medical",
                            "micro",
                            "plugins",
                            "rpg_game",
                            "shopping_cart"
                        ]
                    }
                },
                "required": ["name"]
            }
        },
        {
            "name": "search_docs",
            "description": "Search Jac docs by keyword. Returns ranked snippets with resource URIs.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "query": {"type": "string", "description": "Search query keywords"},
                    "limit": {
                        "type": "integer",
                        "description": "Maximum number of results",
                        "default": 5
                    }
                },
                "required": ["query"]
            }
        },
        {
            "name": "get_ast",
            "description": "Parse Jac code and return AST as tree or JSON.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "code": {
                        "type": "string",
                        "description": "Jac source code to parse"
                    },
                    "format": {
                        "type": "string",
                        "description": "Output format: tree or json",
                        "default": "tree",
                        "enum": ["tree", "json"]
                    }
                },
                "required": ["code"]
            }
        },
        {
            "name": "lint_jac",
            "description": "Lint Jac code for style violations and unused symbols. Supports auto_fix.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "code": {
                        "type": "string",
                        "description": "Jac source code to lint"
                    },
                    "auto_fix": {
                        "type": "boolean",
                        "description": "Auto-fix lint violations and return corrected code",
                        "default": False
                    }
                },
                "required": ["code"]
            }
        },
        {
            "name": "jac_to_py",
            "description": "Transpile Jac code to Python. Shows generated Python output.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "code": {
                        "type": "string",
                        "description": "Jac source code to convert to Python"
                    }
                },
                "required": ["code"]
            }
        },
        {
            "name": "jac_to_js",
            "description": "Transpile Jac code to JavaScript. Shows generated JS from .cl.jac code.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "code": {
                        "type": "string",
                        "description": "Jac source code to convert to JavaScript"
                    }
                },
                "required": ["code"]
            }
        },
        {
            "name": "run_jac",
            "description": "Execute Jac code and return stdout/stderr. Supports optional entrypoint.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "code": {
                        "type": "string",
                        "description": "Jac source code to execute"
                    },
                    "entrypoint": {
                        "type": "string",
                        "description": "Optional specific walker or function to invoke (like jac enter)",
                        "default": ""
                    },
                    "timeout": {
                        "type": "integer",
                        "description": "Max execution time in seconds",
                        "default": 10
                    }
                },
                "required": ["code"]
            }
        },
        {
            "name": "graph_visualize",
            "description": "Run Jac code and visualize the resulting graph as DOT or JSON.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "code": {
                        "type": "string",
                        "description": "Jac source code that builds a graph"
                    },
                    "format": {
                        "type": "string",
                        "description": "Output format: dot or json",
                        "default": "dot",
                        "enum": ["dot", "json"]
                    },
                    "depth": {
                        "type": "integer",
                        "description": "Max traversal depth (-1 for unlimited)",
                        "default": -1
                    },
                    "bfs": {
                        "type": "boolean",
                        "description": "Use breadth-first search (true) or depth-first (false)",
                        "default": True
                    },
                    "edge_limit": {
                        "type": "integer",
                        "description": "Max edges to include",
                        "default": 512
                    },
                    "node_limit": {
                        "type": "integer",
                        "description": "Max nodes to include",
                        "default": 512
                    }
                },
                "required": ["code"]
            }
        },
        {
            "name": "list_commands",
            "description": "List all jac CLI commands including plugin-provided ones.",
            "inputSchema": {"type": "object", "properties": {}}
        },
        {
            "name": "get_command",
            "description": "Get full argument details for a specific jac CLI command.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "name": {
                        "type": "string",
                        "description": "The command name (e.g. 'run', 'check', 'add')"
                    }
                },
                "required": ["name"]
            }
        },
        {
            "name": "execute_command",
            "description": "Execute a jac CLI command with arguments (e.g. ['hello.jac', '--no-cache']).",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "command": {
                        "type": "string",
                        "description": "The jac command to run (e.g. 'run', 'check', 'format', 'test')"
                    },
                    "args": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "Arguments to pass to the command, as a list of strings (e.g. ['hello.jac', '--no-cache'])",
                        "default": []
                    },
                    "timeout": {
                        "type": "integer",
                        "description": "Max execution time in seconds",
                        "default": 30
                    }
                },
                "required": ["command"]
            }
        },
        {
            "name": "understand_jac_and_jaseci",
            "description": "Get the Jac & Jaseci knowledge map with resource URIs for each topic.",
            "inputSchema": {"type": "object", "properties": {}}
        },
        {
            "name": "get_resource",
            "description": "Fetch a Jac/Jaseci doc resource by URI (e.g. jac://guide/pitfalls, jac://docs/osp).",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "uri": {
                        "type": "string",
                        "description": "Resource URI to fetch, e.g. jac://guide/pitfalls or jac://docs/osp"
                    }
                },
                "required": ["uri"]
            }
        },
        {
            "name": "list_templates",
            "description": "List available Jac project templates for scaffolding new projects.",
            "inputSchema": {"type": "object", "properties": {}}
        },
        {
            "name": "create_project",
            "description": "Create a new Jac project from a template. Returns project path and files created.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "name": {
                        "type": "string",
                        "description": "Project name (used as directory name)"
                    },
                    "template": {
                        "type": "string",
                        "description": "Template to use (call list_templates to see options)",
                        "default": "default"
                    },
                    "directory": {
                        "type": "string",
                        "description": "Parent directory to create project in (default: current directory)",
                        "default": ""
                    }
                },
                "required": ["name"]
            }
        },
        {
            "name": "preview_endpoints",
            "description": "Preview HTTP endpoints a Jac file would expose without starting a server. Shows walker:pub and def:pub routes.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "filename": {
                        "type": "string",
                        "description": "Path to the .jac file to analyze"
                    },
                    "port": {
                        "type": "integer",
                        "description": "Port for endpoint URLs (default: 8000)",
                        "default": 8000
                    }
                },
                "required": ["filename"]
            }
        },
        {
            "name": "list_example_files",
            "description": "List .jac files in an example category with sizes. Call before get_example_file to see what's available.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "category": {
                        "type": "string",
                        "description": "Example category name (e.g. 'data_spatial', 'littleX')"
                    }
                },
                "required": ["category"]
            }
        },
        {
            "name": "get_example_file",
            "description": "Get a single .jac file from an example category. Much lighter than get_example which returns all files.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "category": {
                        "type": "string",
                        "description": "Example category name (e.g. 'data_spatial')"
                    },
                    "file_path": {
                        "type": "string",
                        "description": "Relative path of the file within the category (from list_example_files)"
                    }
                },
                "required": ["category", "file_path"]
            }
        },
        {
            "name": "get_doc_section",
            "description": "Get a specific section from a doc resource by heading match. Much lighter than get_resource which returns the full document.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "uri": {
                        "type": "string",
                        "description": "Resource URI (e.g. 'jac://docs/osp', 'jac://docs/foundation')"
                    },
                    "section": {
                        "type": "string",
                        "description": "Section heading or keyword to match (e.g. 'walker', 'graph construction', 'import')"
                    }
                },
                "required": ["uri", "section"]
            }
        },
        {
            "name": "recommend_workflow",
            "description": "Given a task description, recommend which resources to fetch, which tools to use, and in what order. Call this FIRST when starting a new task.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "task": {
                        "type": "string",
                        "description": "Description of what you want to build or do (e.g. 'build a todo app with auth', 'create a walker endpoint')"
                    }
                },
                "required": ["task"]
            }
        },
        {
            "name": "recommend_docs",
            "description": "Given a task description, recommend the 2-5 most relevant doc resources with URIs and reasons.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "task": {
                        "type": "string",
                        "description": "Description of what you want to build or do"
                    }
                },
                "required": ["task"]
            }
        },
        {
            "name": "find_example",
            "description": "Given a task description, find the most relevant example categories and specific files.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "task": {
                        "type": "string",
                        "description": "Description of what you want to build or do"
                    }
                },
                "required": ["task"]
            }
        },

    ];

    # Filter tools based on [plugins.mcp] config toggles and profile
    cfg = _get_mcp_config();
    profile = str(cfg.get("profile", "full"));

    # Build effective flags: profile sets defaults, explicit config overrides
    # minimal = hide advanced/transpile/cli, standard = hide advanced/cli, full = show all
    disabled: set[str] = set();

    if not cfg.get("enable_validate", True) {
        disabled.add("validate_jac");
        disabled.add("check_syntax");
    }
    if not cfg.get("enable_format", True) {
        disabled.add("format_jac");
        disabled.add("lint_jac");
    }
    # py2jac: on by default in standard/full, off in minimal
    if not cfg.get("enable_py2jac", profile != "minimal") {
        disabled.add("py_to_jac");
    }
    # AST: off by default except in full
    if not cfg.get("enable_ast", profile == "full") {
        disabled.add("get_ast");
    }
    # Transpile (jac_to_py, jac_to_js): only in full
    if not cfg.get("enable_transpile", profile == "full") {
        disabled.add("jac_to_py");
        disabled.add("jac_to_js");
    }
    # CLI tools (list_commands, get_command, execute_command): only in full
    if not cfg.get("enable_cli_tools", profile == "full") {
        disabled.add("list_commands");
        disabled.add("get_command");
        disabled.add("execute_command");
    }
    # Project tools: on by default in all profiles
    if not cfg.get("enable_project", True) {
        disabled.add("list_templates");
        disabled.add("create_project");
        disabled.add("preview_endpoints");
    }
    if disabled {
        return [
            t
            for t in all_tools
            if t["name"] not in disabled
        ];
    }
    return all_tools;
}

"""Call a tool by name with arguments."""
impl ToolProvider.call_tool(name: str, arguments: dict[str, Any]) -> dict[str, Any] {
    import from jac_mcp.compiler_bridge { CompilerBridge }
    try {
        if name == "validate_jac" {
            code = arguments.get("code", "");
            filename = arguments.get("filename", "snippet.jac");
            if not code {
                return {"error": "Missing required argument: code"};
            }
            return CompilerBridge.typecheck_snippet(code, filename);
        } elif name == "check_syntax" {
            code = arguments.get("code", "");
            if not code {
                return {"error": "Missing required argument: code"};
            }
            return CompilerBridge.parse_snippet(code);
        } elif name == "format_jac" {
            code = arguments.get("code", "");
            if not code {
                return {"error": "Missing required argument: code"};
            }
            return CompilerBridge.format_snippet(code);
        } elif name == "py_to_jac" {
            python_code = arguments.get("python_code", "");
            if not python_code {
                return {"error": "Missing required argument: python_code"};
            }
            return CompilerBridge.py_to_jac(python_code);
        } elif name == "explain_error" {
            error_message = arguments.get("error_message", "");
            if not error_message {
                return {"error": "Missing required argument: error_message"};
            }
            return explain_error(error_message);
        } elif name == "list_examples" {
            category = arguments.get("category");
            return list_examples(category);
        } elif name == "get_example" {
            example_name = arguments.get("name", "");
            if not example_name {
                return {"error": "Missing required argument: name"};
            }
            return get_example(example_name);
        } elif name == "search_docs" {
            query = arguments.get("query", "");
            limit = arguments.get("limit", 5);
            if not query {
                return {"error": "Missing required argument: query"};
            }
            return search_docs(query, limit);
        } elif name == "get_ast" {
            code = arguments.get("code", "");
            fmt = arguments.get("format", "tree");
            if not code {
                return {"error": "Missing required argument: code"};
            }
            return get_ast(code, fmt);
        } elif name == "lint_jac" {
            code = arguments.get("code", "");
            auto_fix = arguments.get("auto_fix", False);
            if not code {
                return {"error": "Missing required argument: code"};
            }
            return lint_jac(code, auto_fix);
        } elif name == "jac_to_py" {
            code = arguments.get("code", "");
            if not code {
                return {"error": "Missing required argument: code"};
            }
            return jac_to_py(code);
        } elif name == "jac_to_js" {
            code = arguments.get("code", "");
            if not code {
                return {"error": "Missing required argument: code"};
            }
            return jac_to_js(code);
        } elif name == "run_jac" {
            code = arguments.get("code", "");
            entrypoint = arguments.get("entrypoint", "");
            timeout = arguments.get("timeout", 10);
            if not code {
                return {"error": "Missing required argument: code"};
            }
            return run_jac(code, entrypoint, timeout);
        } elif name == "graph_visualize" {
            code = arguments.get("code", "");
            fmt = arguments.get("format", "dot");
            depth = arguments.get("depth", -1);
            bfs = arguments.get("bfs", True);
            edge_limit = arguments.get("edge_limit", 512);
            node_limit = arguments.get("node_limit", 512);
            if not code {
                return {"error": "Missing required argument: code"};
            }
            return graph_visualize(code, fmt, depth, bfs, edge_limit, node_limit);
        } elif name == "list_commands" {
            return list_commands();
        } elif name == "get_command" {
            cmd_name = arguments.get("name", "");
            if not cmd_name {
                return {"error": "Missing required argument: name"};
            }
            return get_command(cmd_name);
        } elif name == "execute_command" {
            cmd_name = arguments.get("command", "");
            cmd_args = arguments.get("args", []);
            cmd_timeout = arguments.get("timeout", 30);
            if not cmd_name {
                return {"error": "Missing required argument: command"};
            }
            return execute_command(cmd_name, cmd_args, cmd_timeout);
        } elif name == "understand_jac_and_jaseci" {
            return understand_jac_and_jaseci();
        } elif name == "get_resource" {
            uri = arguments.get("uri", "");
            if not uri {
                return {"error": "Missing required argument: uri"};
            }
            return get_resource(uri);
        } elif name == "list_templates" {
            return CompilerBridge.list_templates();
        } elif name == "create_project" {
            proj_name = arguments.get("name", "");
            if not proj_name {
                return {"error": "Missing required argument: name"};
            }
            template = arguments.get("template", "default");
            directory = arguments.get("directory", "");
            return CompilerBridge.create_project(proj_name, template, directory);
        } elif name == "preview_endpoints" {
            filename = arguments.get("filename", "");
            if not filename {
                return {"error": "Missing required argument: filename"};
            }
            port = arguments.get("port", 8000);
            return CompilerBridge.start_server(filename, port, faux=True);
        } elif name == "list_example_files" {
            category = arguments.get("category", "");
            if not category {
                return {"error": "Missing required argument: category"};
            }
            return list_example_files(category);
        } elif name == "get_example_file" {
            category = arguments.get("category", "");
            file_path = arguments.get("file_path", "");
            if not category or not file_path {
                return {"error": "Missing required arguments: category and file_path"};
            }
            return get_example_file(category, file_path);
        } elif name == "get_doc_section" {
            uri = arguments.get("uri", "");
            section = arguments.get("section", "");
            if not uri or not section {
                return {"error": "Missing required arguments: uri and section"};
            }
            return get_doc_section(uri, section);
        } elif name == "recommend_workflow" {
            task = arguments.get("task", "");
            if not task {
                return {"error": "Missing required argument: task"};
            }
            return recommend_workflow(task);
        } elif name == "recommend_docs" {
            task = arguments.get("task", "");
            if not task {
                return {"error": "Missing required argument: task"};
            }
            return recommend_docs(task);
        } elif name == "find_example" {
            task = arguments.get("task", "");
            if not task {
                return {"error": "Missing required argument: task"};
            }
            return find_example(task);
        } else {
            return {"error": f"Unknown tool: {name}"};
        }
    } except Exception as e {
        return {"error": f"Tool execution failed: {str(e)}"};
    }
}

"""Explain a compiler error with suggestions and examples."""
impl explain_error(error_message: str) -> dict[str, Any] {
    msg_lower = error_message.lower();
    error_patterns: list[tuple] = [
        (
            r"unexpected token|expected.*got|syntax error",
            "Syntax Error",
            "The code contains a syntax error. Common causes: missing semicolons, missing braces, or using Python syntax instead of Jac syntax.",
            "# Jac requires semicolons and braces:\nobj Foo {\n    has x: int = 5;\n}"
        ),
        (
            r"undefined name|not defined|name.*is not defined",
            "Undefined Name",
            "A variable or symbol is referenced but not defined. Check imports, spelling, and scope.",
            "# Import what you need:\nimport from os { path }"
        ),
        (
            r"type.*mismatch|incompatible.*type|cannot assign.*to",
            "Type Mismatch",
            "Types don't match. Ensure assignments, arguments, and returns match declared types.",
            "has x: int = 5;  # OK\n# has z: int = \"oops\";  # ERROR"
        ),
        (
            r"cannot find module|no module|module not found|import error",
            "Import Error",
            "Module not found. Use Jac import syntax: 'import from module { name }'.",
            "import from os { path }\nimport from typing { Any }"
        ),
        (
            r"has no attribute|attribute.*not found|no member",
            "Attribute Error",
            "Object doesn't have the attribute. Check archetype definition.",
            "obj Foo {\n    has x: int = 5;\n}"
        ),
        (
            r"class|def __init__|self\.",
            "Python Syntax Detected",
            "Detected Python syntax. Use 'obj' not 'class', 'has' not 'self.x', 'can' for methods.",
            "# obj Foo { has x: int = 5; }  # NOT: class Foo: ..."
        ),

    ];
    for (pattern, title, explanation, example) in error_patterns {
        if re.search(pattern, msg_lower) {
            return {
                "title": title,
                "explanation": explanation,
                "suggestion": "Review the error and apply the pattern shown in the example.",
                "example": example,
                "docs_uri": "jac://guide/pitfalls"
            };
        }
    }
    return {
        "title": "Compilation Error",
        "explanation": f"The compiler reported: {error_message}",
        "suggestion": "Check Jac syntax reference. Common issues: missing semicolons, wrong import syntax.",
        "example": "",
        "docs_uri": "jac://guide/pitfalls"
    };
}

"""List available example categories."""
impl list_examples(category: str | None = None) -> dict[str, Any] {
    import from jac_mcp.resources { ResourceProvider }
    rp = ResourceProvider();
    rp.index_resources();
    examples: list[dict[str, str]] = [];
    for (uri, info) in rp._resources.items() {
        if uri.startswith("jac://examples/") and uri != "jac://examples/index" {
            cat_name = uri.split("/")[-1];
            if category is None or category == cat_name {
                examples.append(
                    {
                        "name": cat_name,
                        "uri": uri,
                        "description": info.get("description", "")
                    }
                );
            }
        }
    }
    # If no individual examples found, try lazy GitHub fetch (PyPI install)
    if not examples and "jac://examples/index" in rp._resources {
        categories = rp._fetch_github_categories();
        for cat_name in categories {
            if category is None or category == cat_name {
                examples.append(
                    {
                        "name": cat_name,
                        "uri": f"jac://examples/{cat_name}",
                        "description": f"Example Jac code for {cat_name}"
                    }
                );
            }
        }
    }
    return {"examples": sorted(examples, key=lambda x : x["name"])};
}

"""Get all files from an example category."""
impl get_example(name: str) -> dict[str, Any] {
    import from jac_mcp.resources { ResourceProvider }
    rp = ResourceProvider();
    rp.index_resources();
    uri = f"jac://examples/{name}";
    content = rp.read_resource(uri);
    if content.startswith("Error:") {
        return {"error": content};
    }
    return {"name": name, "content": content};
}

"""Search documentation by keywords."""
impl search_docs(query: str, limit: int = 5) -> dict[str, Any] {
    import from jac_mcp.resources { ResourceProvider }
    rp = ResourceProvider();
    rp.index_resources();
    keywords = [
        w.lower()
        for w in query.split()
        if len(w) > 2
    ];
    if not keywords {
        return {"results": []};
    }
    scored: list[tuple] = [];
    for (uri, info) in rp._resources.items() {
        if info.get("_is_dir") or uri == "jac://examples/index" {
            continue;
        }

        file_path = info.get("path");
        if not file_path {
            continue;
        }

        try {
            with open(file_path, "r") as f {
                content = f.read().lower();
            }
        } except Exception {
            continue;
        }

        score = 0.0;
        for kw in keywords {
            count = content.count(kw);
            if count > 0 {
                score += count;
            }
        }

        if score > 0 {
            snippet = "";
            for kw in keywords {
                idx = content.find(kw);
                if idx >= 0 {
                    start = max(0, idx - 100);
                    end = min(len(content), idx + 100);
                    snippet = content[start:end].strip();
                    break;
                }
            }
            scored.append(
                (
                    score,
                    {
                        "uri": uri,
                        "title": info.get("name", ""),
                        "description": info.get("description", ""),
                        "snippet": snippet[:200],
                        "score": score
                    }
                )
            );
        }
    }
    scored.sort(key=lambda x : -x[0]);
    results = [item[1] for item in scored[:limit]];
    return {"results": results};
}

"""Parse code and return AST info."""
impl get_ast(code: str, fmt: str = "tree") -> dict[str, Any] {
    import from jac_mcp.compiler_bridge { CompilerBridge }
    return CompilerBridge.get_ast_snippet(code, fmt);
}

"""Lint Jac code with optional auto-fix."""
impl lint_jac(code: str, auto_fix: bool = False) -> dict[str, Any] {
    import from jac_mcp.compiler_bridge { CompilerBridge }
    return CompilerBridge.lint_snippet(code, auto_fix);
}

"""Convert Jac code to Python."""
impl jac_to_py(code: str) -> dict[str, Any] {
    import from jac_mcp.compiler_bridge { CompilerBridge }
    return CompilerBridge.jac_to_py(code);
}

"""Convert Jac code to JavaScript."""
impl jac_to_js(code: str) -> dict[str, Any] {
    import from jac_mcp.compiler_bridge { CompilerBridge }
    return CompilerBridge.jac_to_js(code);
}

"""Execute Jac code and return output."""
impl run_jac(code: str, entrypoint: str = "", timeout: int = 10) -> dict[str, Any] {
    import from jac_mcp.compiler_bridge { CompilerBridge }
    return CompilerBridge.run_snippet(code, entrypoint, timeout);
}

"""Generate graph visualization from Jac code."""
impl graph_visualize(
    code: str,
    format: str = "dot",
    depth: int = -1,
    bfs: bool = True,
    edge_limit: int = 512,
    node_limit: int = 512
) -> dict[str, Any] {
    import from jac_mcp.compiler_bridge { CompilerBridge }
    return CompilerBridge.graph_viz_snippet(
        code, format, depth, bfs, edge_limit, node_limit
    );
}

"""List all available jac CLI commands including those from installed plugins."""
impl list_commands -> dict[str, Any] {
    try {
        import from jaclang.jac0core.runtime { JacRuntime as Jac }
        import from jaclang.cli.registry { get_registry }
        import jaclang.cli.commands;

        # Trigger plugin command registrations, same hook the CLI calls at startup
        Jac.create_cmd();

        registry = get_registry();
        if not registry._finalized {
            registry.finalize();
        }

        commands: list[dict[str, Any]] = [];
        for spec in registry.get_all() {
            # Collect unique plugin sources that extend this command
            extensions: list[str] = [];
            seen_ext: set = set();
            for arg in spec.extra_args {
                if arg.source != spec.source and arg.source not in seen_ext {
                    seen_ext.add(arg.source);
                    extensions.append(arg.source);
                }
            }

            cmd: dict[str, Any] = {
                "name": spec.name,
                "help": spec.help,
                "group": spec.group,
                "source": spec.source
            };
            if extensions {
                cmd["extended_by"] = extensions;
            }
            commands.append(cmd);
        }

        commands.sort(key=lambda c : (c["group"], c["name"]));

        return {
            "commands": commands,
            "groups": registry.get_groups(),
            "total": len(commands)
        };
    } except Exception as e {
        return {"error": f"Failed to list commands: {str(e)}"};
    }
}

"""Get full argument details for a specific jac CLI command."""
impl get_command(name: str) -> dict[str, Any] {
    try {
        import from jaclang.jac0core.runtime { JacRuntime as Jac }
        import from jaclang.cli.registry { get_registry }
        import jaclang.cli.commands;

        Jac.create_cmd();
        registry = get_registry();
        if not registry._finalized {
            registry.finalize();
        }

        spec = registry.get(name);
        if spec is None {
            return {"error": f"Command not found: {name}"};
        }

        args: list[dict[str, Any]] = [];
        seen_args: set = set();
        for arg in spec.get_all_args() {
            if arg.name in seen_args {
                continue;
            }
            seen_args.add(arg.name);
            type_name: str;
            if hasattr(arg.typ, "__name__") {
                type_name = arg.typ.__name__;
            } else {
                type_name = str(arg.typ);
            }
            arg_info: dict[str, Any] = {
                "name": arg.name,
                "kind": arg.kind.name,
                "type": type_name,
                "required": arg.required,
                "default": arg.default,
                "help": arg.help,
                "source": arg.source
            };
            if arg.short is not None {
                arg_info["short"] = arg.short;
            }
            if arg.choices is not None {
                arg_info["choices"] = arg.choices;
            }
            args.append(arg_info);
        }

        extensions: list[str] = [];
        seen_ext: set = set();
        for arg in spec.extra_args {
            if arg.source != spec.source and arg.source not in seen_ext {
                seen_ext.add(arg.source);
                extensions.append(arg.source);
            }
        }

        result: dict[str, Any] = {
            "name": spec.name,
            "help": spec.help,
            "group": spec.group,
            "source": spec.source,
            "args": args
        };
        if extensions {
            result["extended_by"] = extensions;
        }
        return result;
    } except Exception as e {
        return {"error": f"Failed to get command: {str(e)}"};
    }
}

"""Execute a jac CLI command by name with optional arguments."""
impl execute_command(
    command: str, args: list[str] | None = None, timeout: int = 30
) -> dict[str, Any] {
    import subprocess;
    import sys;

    cmd_args: list[str] = [sys.executable, "-m", "jaclang", command] + (args or []);
    try {
        result = subprocess.run(
            cmd_args, capture_output=True, text=True, timeout=timeout
        );
        return {
            "success": result.returncode == 0,
            "exit_code": result.returncode,
            "stdout": result.stdout,
            "stderr": result.stderr,
            "command": f"jac {command} {' '.join(args or [])}"
        };
    } except subprocess.TimeoutExpired {
        return {
            "success": False,
            "exit_code": -1,
            "error": f"Command timed out after {timeout}s",
            "command": f"jac {command} {' '.join(args or [])}"
        };
    } except Exception as e {
        return {
            "success": False,
            "exit_code": -1,
            "error": f"Failed to execute command: {str(e)}",
            "command": f"jac {command} {' '.join(args or [])}"
        };
    }
}

"""Get the Jac & Jaseci knowledge map with resource URIs for any task."""
impl understand_jac_and_jaseci -> dict[str, Any] {
    import from jac_mcp.resources { ResourceProvider }
    rp = ResourceProvider();
    rp.index_resources();
    content = rp.read_resource("jac://guide/understand");
    if content.startswith("Error:") {
        return {"error": content};
    }
    return {"knowledge_map": content};
}

"""Fetch a Jac/Jaseci doc resource by URI."""
impl get_resource(uri: str) -> dict[str, Any] {
    import from jac_mcp.resources { ResourceProvider }
    rp = ResourceProvider();
    rp.index_resources();
    content = rp.read_resource(uri);
    if content.startswith("Error:") {
        return {"error": content, "uri": uri};
    }
    return {"uri": uri, "content": content};
}

"""List .jac files in an example category with sizes."""
impl list_example_files(category: str) -> dict[str, Any] {
    import from jac_mcp.resources { ResourceProvider, find_repo_root }
    import from pathlib { Path }

    # Try local repo first
    repo_root = find_repo_root();
    if repo_root {
        examples_dir = Path(repo_root) / "jac" / "examples" / category;
        if examples_dir.exists() and examples_dir.is_dir() {
            files: list[dict[str, Any]] = [];
            for jac_file in sorted(examples_dir.rglob("*.jac")) {
                rel = str(jac_file.relative_to(examples_dir));
                try {
                    line_count = len(jac_file.read_text().splitlines());
                } except Exception {
                    line_count = 0;
                }
                files.append({"file": rel, "lines": line_count});
            }
            if not files {
                return {"error": f"No .jac files found in category '{category}'"};
            }
            return {"category": category, "files": files};
        }
    }
    # Fall back: use ResourceProvider to list the category, then parse file names
    import from jac_mcp.resources { ResourceProvider }
    rp = ResourceProvider();
    rp.index_resources();
    content = rp.read_resource(f"jac://examples/{category}");
    if content.startswith("Error:") or content.startswith("No .jac") {
        return {"error": f"Category '{category}' not found"};
    }
    # Parse concatenated output format: "--- filename ---\n<content>\n\n--- filename2 ---\n..."
    files: list[dict[str, Any]] = [];
    for block in content.split("\n--- ") {
        if not block.strip() {
            continue;
        }
        header = block.split(" ---")[0].strip().lstrip("-").strip();
        if header {
            line_count = len(block.split("\n")) - 1;
            files.append({"file": header, "lines": line_count});
        }
    }
    return {"category": category, "files": files};
}

"""Get a single .jac file from an example category."""
impl get_example_file(category: str, file_path: str) -> dict[str, Any] {
    import from jac_mcp.resources { find_repo_root }
    import from pathlib { Path }

    # Try local repo first
    repo_root = find_repo_root();
    if repo_root {
        full_path = Path(repo_root) / "jac" / "examples" / category / file_path;
        if full_path.exists() and full_path.is_file() {
            try {
                content = full_path.read_text();
                return {"category": category, "file": file_path, "content": content};
            } except Exception as e {
                return {"error": f"Failed to read file: {e}"};
            }
        }
    }
    # Fall back: use ResourceProvider to get the full category, then extract the file
    import from jac_mcp.resources { ResourceProvider }
    rp = ResourceProvider();
    rp.index_resources();
    content = rp.read_resource(f"jac://examples/{category}");
    if content.startswith("Error:") or content.startswith("No .jac") {
        return {"error": f"Category '{category}' not found"};
    }
    # Parse concatenated output to find the specific file
    marker = f"--- {file_path} ---";
    idx = content.find(marker);
    if idx < 0 {
        return {"error": f"File '{file_path}' not found in category '{category}'"};
    }
    # Extract content between this marker and the next one
    start = idx + len(marker) + 1;
    next_marker = content.find("\n--- ", start);
    if next_marker > 0 {
        file_content = content[start:next_marker].strip();
    } else {
        file_content = content[start:].strip();
    }
    return {"category": category, "file": file_path, "content": file_content};
}

"""Get a specific section from a doc resource by heading match."""
impl get_doc_section(uri: str, section: str) -> dict[str, Any] {
    import from jac_mcp.resources { ResourceProvider }
    rp = ResourceProvider();
    rp.index_resources();
    content = rp.read_resource(uri);
    if content.startswith("Error:") {
        return {"error": content, "uri": uri};
    }

    # Split content into top-level sections by ## headings
    # Each section includes all its ### subsections
    lines = content.split("\n");
    sections: list[dict[str, str]] = [];
    current_heading = "";
    current_lines: list[str] = [];

    for line in lines {
        if line.startswith("## ") and not line.startswith("### ") {
            # Save previous section
            if current_heading {
                sections.append(
                    {"heading": current_heading, "content": "\n".join(current_lines)}
                );
            }
            current_heading = line.lstrip("#").strip();
            current_lines = [line];
        } else {
            current_lines.append(line);
        }
    }
    # Save last section
    if current_heading {
        sections.append(
            {"heading": current_heading, "content": "\n".join(current_lines)}
        );
    }

    if not sections {
        return {
            "uri": uri,
            "section": section,
            "content": content,
            "note": "No sections found, returning full content"
        };
    }

    # Find best matching section(s) by keyword
    query = section.lower();
    matches: list[dict[str, str]] = [];
    for sec in sections {
        heading_lower = sec["heading"].lower();
        if query in heading_lower {
            matches.append(sec);
        }
    }
    # If no heading match, try content match
    if not matches {
        for sec in sections {
            if query in sec["content"].lower()[:500] {
                matches.append(sec);
            }
        }
    }

    if not matches {
        headings = [s["heading"] for s in sections];
        return {
            "uri": uri,
            "section": section,
            "error": "No matching section found",
            "available_sections": headings
        };
    }

    best = matches[0];
    return {
        "uri": uri,
        "section": best["heading"],
        "content": best["content"],
        "total_matches": len(matches)
    };
}

# ── Keyword rules for task classification ──
glob _TASK_KEYWORDS: list[tuple] = [
         # (keywords, category, docs, examples, pitfalls, workflow_steps)
         (
             [
                 "client",
                 "ui",
                 "component",
                 "jsx",
                 "frontend",
                 "react",
                 "page",
                 "button",
                 "form",
                 "input"
             ],
             "client_ui",
             [
                 "jac://guide/pitfalls_client",
                 "jac://guide/patterns_client",
                 "jac://docs/tutorial-fullstack-components",
                 "jac://docs/tutorial-fullstack-state"
             ],
             ["littleX", "micro"],
             ["jac://guide/pitfalls_client"],
             [
                 "Fetch jac://guide/pitfalls + jac://guide/patterns (core syntax)",
                 "Fetch jac://guide/pitfalls_client + jac://guide/patterns_client",
                 "Read jac://docs/tutorial-fullstack-components",
                 "Write code inside cl { } blocks",
                 "Validate with validate_jac"
             ]
         ),
         (
             [
                 "walker",
                 "node",
                 "edge",
                 "graph",
                 "traverse",
                 "osp",
                 "spawn",
                 "visit",
                 "report"
             ],
             "osp",
             [
                 "jac://guide/pitfalls",
                 "jac://guide/patterns",
                 "jac://docs/osp",
                 "jac://docs/walker-responses"
             ],
             ["data_spatial", "medical"],
             ["jac://guide/pitfalls"],
             [
                 "Fetch jac://guide/pitfalls + jac://guide/patterns",
                 "Read jac://docs/osp",
                 "Write walker/node/edge code",
                 "Validate with validate_jac"
             ]
         ),
         (
             ["endpoint", "api", "rest", "http", "server", "pub", "priv", "route"],
             "api_endpoint",
             [
                 "jac://guide/pitfalls_api",
                 "jac://guide/patterns_fullstack",
                 "jac://docs/osp",
                 "jac://docs/tutorial-production-local"
             ],
             ["data_spatial", "plugins"],
             ["jac://guide/pitfalls_api"],
             [
                 "Fetch jac://guide/pitfalls + jac://guide/pitfalls_api",
                 "Read jac://guide/patterns_fullstack for CRUD walker examples",
                 "Write walker:pub or def:pub endpoints",
                 "Use preview_endpoints to check routes",
                 "Validate with validate_jac"
             ]
         ),
         (
             [
                 "auth",
                 "login",
                 "signup",
                 "logout",
                 "user",
                 "password",
                 "jwt",
                 "priv",
                 "private"
             ],
             "auth",
             [
                 "jac://guide/pitfalls_api",
                 "jac://guide/pitfalls_client",
                 "jac://docs/tutorial-fullstack-auth"
             ],
             ["littleX"],
             ["jac://guide/pitfalls_api", "jac://guide/pitfalls_client"],
             [
                 "Fetch jac://guide/pitfalls + jac://guide/pitfalls_api + jac://guide/pitfalls_client",
                 "Read jac://docs/tutorial-fullstack-auth",
                 "Use walker:priv for per-user isolated endpoints",
                 "Import jacLogin/jacSignup from @jac/runtime in client",
                 "Validate with validate_jac"
             ]
         ),
         (
             [
                 "fullstack",
                 "full-stack",
                 "full stack",
                 "sv import",
                 "root spawn",
                 "client server",
                 "server client"
             ],
             "fullstack",
             [
                 "jac://guide/pitfalls_client",
                 "jac://guide/pitfalls_fullstack",
                 "jac://guide/pitfalls_api",
                 "jac://guide/patterns_fullstack",
                 "jac://docs/tutorial-fullstack-backend"
             ],
             ["littleX"],
             [
                 "jac://guide/pitfalls_client",
                 "jac://guide/pitfalls_fullstack",
                 "jac://guide/pitfalls_api"
             ],
             [
                 "Fetch jac://guide/pitfalls + jac://guide/pitfalls_client + jac://guide/pitfalls_fullstack + jac://guide/pitfalls_api",
                 "Read jac://guide/patterns_fullstack",
                 "Write server walkers (walker:pub) in main.jac",
                 "Write client UI (cl { }) with sv import + root spawn",
                 "Validate with validate_jac"
             ]
         ),
         (
             [
                 "llm",
                 "ai",
                 "by llm",
                 "byllm",
                 "semantic",
                 "sem",
                 "gpt",
                 "model",
                 "prompt"
             ],
             "ai_byllm",
             [
                 "jac://docs/byllm",
                 "jac://docs/tutorial-ai-quickstart",
                 "jac://docs/tutorial-ai-agentic"
             ],
             ["guess_game"],
             ["jac://guide/pitfalls"],
             [
                 "Fetch jac://guide/pitfalls + jac://guide/patterns",
                 "Read jac://docs/byllm for by llm syntax",
                 "Write def ... by llm() functions",
                 "Validate with validate_jac"
             ]
         ),
         (
             ["test", "testing", "assert", "test block"],
             "testing",
             ["jac://docs/testing", "jac://guide/patterns"],
             ["manual_code"],
             ["jac://guide/pitfalls"],
             [
                 "Fetch jac://guide/pitfalls + jac://guide/patterns",
                 "Read jac://docs/testing",
                 "Write test blocks: test \"name\" { assert ...; }",
                 "Run with execute_command('test', [...])"
             ]
         ),
         (
             ["routing", "pages", "navigate", "link", "url", "param"],
             "routing",
             ["jac://guide/pitfalls_client", "jac://docs/tutorial-fullstack-routing"],
             ["littleX"],
             ["jac://guide/pitfalls_client"],
             [
                 "Fetch jac://guide/pitfalls + jac://guide/pitfalls_client",
                 "Read jac://docs/tutorial-fullstack-routing",
                 "Create pages/ directory with .jac files",
                 "Use useParams() for dynamic routes, Outlet for layouts",
                 "Validate with validate_jac"
             ]
         ),
         (
             ["deploy", "production", "kubernetes", "k8s", "scale", "docker"],
             "deployment",
             ["jac://docs/jac-scale", "jac://docs/tutorial-production-local"],
             [],
             [],
             [
                 "Read jac://docs/tutorial-production-local",
                 "Use jac start app.jac to test locally",
                 "Read jac://docs/jac-scale for Kubernetes deployment"
             ]
         ),
         (
             ["convert", "migrate", "python", "py2jac", "port"],
             "migration",
             [
                 "jac://guide/pitfalls",
                 "jac://guide/patterns",
                 "jac://docs/python-integration"
             ],
             ["manual_code"],
             ["jac://guide/pitfalls"],
             [
                 "Fetch jac://guide/pitfalls + jac://guide/patterns",
                 "Use py_to_jac tool for automatic conversion",
                 "Review and fix output using pitfalls guide",
                 "Validate with validate_jac"
             ]
         ),

     ];

"""Classify a task description and return matching keyword rules."""
def _classify_task(task: str) -> list[tuple] {
    task_lower = task.lower();
    scored: list[tuple] = [];
    for rule in _TASK_KEYWORDS {
        (keywords, category, docs, examples, pitfalls, steps) = rule;
        score = sum(
            [
                1
                for kw in keywords
                if kw in task_lower
            ]
        );
        if score > 0 {
            scored.append((score, category, docs, examples, pitfalls, steps));
        }
    }
    scored.sort(key=lambda x : -x[0]);
    return scored;
}

"""Recommend workflow steps, resources, and tools for a task."""
impl recommend_workflow(task: str) -> dict[str, Any] {
    matches = _classify_task(task);
    if not matches {
        return {
            "task": task,
            "category": "general",
            "steps": [
                "Fetch jac://guide/pitfalls + jac://guide/patterns (always read these first)",
                "Call understand_jac_and_jaseci for the full knowledge map",
                "Use search_docs to find task-specific documentation",
                "Write code, then validate with validate_jac",
                "If errors, use explain_error and fix"
            ],
            "resources": ["jac://guide/pitfalls", "jac://guide/patterns"],
            "tools_to_use": [
                "understand_jac_and_jaseci",
                "get_resource",
                "search_docs",
                "validate_jac",
                "explain_error"
            ]
        };
    }
    (score, category, docs, examples, pitfalls, steps) = matches[0];
    # Always prepend core pitfalls/patterns
    all_resources = ["jac://guide/pitfalls", "jac://guide/patterns"];
    for d in docs {
        if d not in all_resources {
            all_resources.append(d);
        }
    }
    tools_to_use = ["get_resource", "validate_jac", "explain_error"];
    if examples {
        tools_to_use.append("get_example_file");
    }
    return {
        "task": task,
        "category": category,
        "steps": steps,
        "resources": all_resources,
        "examples": examples,
        "tools_to_use": tools_to_use
    };
}

"""Recommend the most relevant doc resources for a task."""
impl recommend_docs(task: str) -> dict[str, Any] {
    matches = _classify_task(task);
    recommendations: list[dict[str, str]] = [];
    seen: set[str] = set();
    # Always recommend core
    recommendations.append(
        {
            "uri": "jac://guide/pitfalls",
            "reason": "Core syntax pitfalls - always read before writing Jac"
        }
    );
    seen.add("jac://guide/pitfalls");
    recommendations.append(
        {"uri": "jac://guide/patterns", "reason": "Core working code patterns"}
    );
    seen.add("jac://guide/patterns");

    for match in matches {
        (score, category, docs, examples, pitfalls, steps) = match;
        for doc_uri in docs {
            if doc_uri not in seen {
                seen.add(doc_uri);
                recommendations.append(
                    {"uri": doc_uri, "reason": f"Relevant to {category} tasks"}
                );
            }
        }
    }
    return {"task": task, "recommendations": recommendations[:7]};
}

"""Find the most relevant example categories and files for a task."""
impl find_example(task: str) -> dict[str, Any] {
    # Match against example descriptions
    EXAMPLE_DESCRIPTIONS: dict[str, str] = {
        "chess": "Native chess engine, declaration/impl separation, enums, obj inheritance, type system",
        "data_spatial": "Core OSP: nodes, edges, walkers, entry/exit abilities, edge filtering, graph programming",
        "guess_game": "Progressive guessing game, plain obj to walker-based OSP, then LLM hints, step by step learning",
        "littleX": "Full-stack social app, OSP graph, user profiles, NLP search, real-world data-spatial",
        "manual_code": "Circle class, declaration/impl separation, unit tests, clean OOP",
        "medical": "Graph-based medical domain, Person nodes, typed role edges, healthcare data modelling",
        "micro": "Micro-snippets, individual language features, access modifiers, comprehensions, syntax reference",
        "plugins": "Plugin development, CLI command extension, walker REST API, jac-scale",
        "rpg_game": "2D RPG game, library mode, Python interop, pygame, native integration",
        "shopping_cart": "E-commerce shopping cart, obj-based domain model, OOP-style Jac"
    };
    task_lower = task.lower();
    scored: list[tuple] = [];
    for (cat, desc) in EXAMPLE_DESCRIPTIONS.items() {
        desc_lower = desc.lower();
        score = sum(
            [
                1
                for word in task_lower.split()
                if len(word) > 2 and word in desc_lower
            ]
        );
        if score > 0 {
            scored.append((score, cat, desc));
        }
    }
    scored.sort(key=lambda x : -x[0]);

    # Also check task keyword rules for example recommendations
    matches = _classify_task(task);
    keyword_examples: list[str] = [];
    for match in matches {
        for ex in match[3] {
            if ex not in keyword_examples {
                keyword_examples.append(ex);
            }
        }
    }

    # Merge: keyword matches first, then description matches
    results: list[dict[str, str]] = [];
    seen: set[str] = set();
    for ex in keyword_examples {
        if ex not in seen {
            seen.add(ex);
            desc = EXAMPLE_DESCRIPTIONS.get(ex, "");
            results.append({"category": ex, "description": desc, "match": "keyword"});
        }
    }
    for (score, cat, desc) in scored {
        if cat not in seen {
            seen.add(cat);
            results.append(
                {"category": cat, "description": desc, "match": "description"}
            );
        }
    }
    return {"task": task, "examples": results[:5]};
}
