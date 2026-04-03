"""Implementation of MCP prompt templates."""

import from typing { Any }

"""Load a resource's content, returning empty string if unavailable."""
impl load_resource_content(uri: str) -> str {
    import from jac_mcp.resources { ResourceProvider }
    rp = ResourceProvider();
    rp.index_resources();
    content = rp.read_resource(uri);
    if content.startswith("Error:") {
        return "";
    }
    return content;
}

"""Build system prompt with pitfalls and optional extra resources."""
impl build_system_prompt(extra_uris: list[str] = []) -> str {
    parts: list[str] = [
        "You are an expert Jac programmer. You MUST follow the syntax rules and patterns provided below EXACTLY.",
        "",
        "CRITICAL: Jac is its own language — it is NOT Python. It evolves rapidly and your training data is almost certainly out of date.",
        "The reference material below is the ONLY source of truth you should use. If it contradicts your prior knowledge, the reference material is correct and your prior knowledge is wrong.",
        "Do NOT guess syntax. Do NOT interpolate from Python. Use ONLY what the reference material shows.",
        "",
        "After generating Jac code, you MUST validate it using the `validate_jac` tool. Do NOT present code to the user until it passes validation.",
        "",
        "## Common Mistakes AI Models Make with Jac (READ CAREFULLY — THIS MEANS YOU)",
        load_resource_content("jac://guide/pitfalls"),

    ];
    for uri in extra_uris {
        content = load_resource_content(uri);
        if content {
            parts.append(f"\n## Reference: {uri}\n{content}");
        }
    }
    return "\n".join(parts);
}

"""Return list of available prompts."""
impl PromptProvider.list_prompts -> list[dict[str, Any]] {
    return [
        {
            "name": "write_module",
            "description": "Generate a new Jac module with optional .impl.jac file",
            "arguments": [
                {"name": "name", "description": "Module name", "required": True},
                {
                    "name": "purpose",
                    "description": "What the module does",
                    "required": True
                },
                {
                    "name": "has_impl",
                    "description": "Include .impl.jac (true/false)",
                    "required": False
                },

            ]
        },
        {
            "name": "write_impl",
            "description": "Generate .impl.jac file for existing declarations",
            "arguments": [
                {
                    "name": "declarations",
                    "description": "Content of the .jac declaration file",
                    "required": True
                },

            ]
        },
        {
            "name": "write_walker",
            "description": "Generate a walker with visit logic",
            "arguments": [
                {"name": "name", "description": "Walker name", "required": True},
                {
                    "name": "purpose",
                    "description": "What the walker does",
                    "required": True
                },
                {
                    "name": "node_types",
                    "description": "Node types to traverse",
                    "required": True
                },

            ]
        },
        {
            "name": "write_node",
            "description": "Generate a node archetype with has declarations",
            "arguments": [
                {"name": "name", "description": "Node name", "required": True},
                {
                    "name": "fields",
                    "description": "Field definitions",
                    "required": True
                },

            ]
        },
        {
            "name": "write_test",
            "description": "Generate test blocks for a module",
            "arguments": [
                {
                    "name": "module_name",
                    "description": "Module to test",
                    "required": True
                },
                {
                    "name": "functions_to_test",
                    "description": "Functions/abilities to test",
                    "required": True
                },

            ]
        },
        {
            "name": "write_ability",
            "description": "Generate an ability (method) implementation",
            "arguments": [
                {"name": "name", "description": "Ability name", "required": True},
                {
                    "name": "signature",
                    "description": "Type signature",
                    "required": True
                },
                {"name": "purpose", "description": "What it does", "required": True},

            ]
        },
        {
            "name": "debug_error",
            "description": "Debug a Jac compilation error",
            "arguments": [
                {
                    "name": "error_output",
                    "description": "The error message(s)",
                    "required": True
                },
                {
                    "name": "code",
                    "description": "The code that caused the error",
                    "required": True
                },

            ]
        },
        {
            "name": "fix_type_error",
            "description": "Fix a type checking error in Jac code",
            "arguments": [
                {
                    "name": "error_output",
                    "description": "The type error message",
                    "required": True
                },
                {
                    "name": "code",
                    "description": "The code with the type error",
                    "required": True
                },

            ]
        },
        {
            "name": "migrate_python",
            "description": "Convert Python code to idiomatic Jac",
            "arguments": [
                {
                    "name": "python_code",
                    "description": "Python source code to convert",
                    "required": True
                },

            ]
        },
        {
            "name": "write_client_component",
            "description": "Generate a Jac client-side component with reactive state and JSX",
            "arguments": [
                {"name": "name", "description": "Component name", "required": True},
                {
                    "name": "purpose",
                    "description": "What the component does",
                    "required": True
                },
                {
                    "name": "props",
                    "description": "Props the component accepts (e.g. 'title: str, items: list')",
                    "required": False
                },

            ]
        },
        {
            "name": "write_walker_endpoint",
            "description": "Generate a walker:pub or walker:priv HTTP endpoint with has fields and report",
            "arguments": [
                {"name": "name", "description": "Walker name", "required": True},
                {
                    "name": "purpose",
                    "description": "What the endpoint does",
                    "required": True
                },
                {
                    "name": "visibility",
                    "description": "pub (public, no auth) or priv (private, per-user auth)",
                    "required": True
                },
                {
                    "name": "fields",
                    "description": "Request body fields (walker has declarations)",
                    "required": False
                },

            ]
        },
        {
            "name": "write_auth_flow",
            "description": "Generate login/signup/logout UI with Jac built-in auth functions",
            "arguments": [
                {
                    "name": "pages",
                    "description": "Which pages to generate: login, signup, or both",
                    "required": True
                },
                {
                    "name": "redirect_to",
                    "description": "Where to redirect after successful login (e.g. '/', '/dashboard')",
                    "required": False
                },

            ]
        },
        {
            "name": "write_fullstack_feature",
            "description": "Generate a coordinated server + client feature with walker endpoints and UI",
            "arguments": [
                {"name": "name", "description": "Feature name", "required": True},
                {
                    "name": "purpose",
                    "description": "What the feature does end-to-end",
                    "required": True
                },
                {
                    "name": "data_model",
                    "description": "Node types and fields for the data (e.g. 'Task with title: str, completed: bool')",
                    "required": True
                },
                {
                    "name": "operations",
                    "description": "CRUD operations needed (e.g. 'list, create, update, delete')",
                    "required": False
                },

            ]
        },

    ];
}

"""Get a prompt by name with arguments."""
impl PromptProvider.get_prompt(name: str, arguments: dict[str, str]) -> dict[str, Any] {
    if name == "write_module" {
        return _prompt_write_module(arguments);
    } elif name == "write_impl" {
        return _prompt_write_impl(arguments);
    } elif name == "write_walker" {
        return _prompt_write_walker(arguments);
    } elif name == "write_node" {
        return _prompt_write_node(arguments);
    } elif name == "write_test" {
        return _prompt_write_test(arguments);
    } elif name == "write_ability" {
        return _prompt_write_ability(arguments);
    } elif name == "debug_error" {
        return _prompt_debug_error(arguments);
    } elif name == "fix_type_error" {
        return _prompt_fix_type_error(arguments);
    } elif name == "migrate_python" {
        return _prompt_migrate_python(arguments);
    } elif name == "write_client_component" {
        return _prompt_write_client_component(arguments);
    } elif name == "write_walker_endpoint" {
        return _prompt_write_walker_endpoint(arguments);
    } elif name == "write_auth_flow" {
        return _prompt_write_auth_flow(arguments);
    } elif name == "write_fullstack_feature" {
        return _prompt_write_fullstack_feature(arguments);
    } else {
        return {
            "description": f"Unknown prompt: {name}",
            "messages": [
                {"role": "user", "content": f"Unknown prompt template: {name}"}
            ]
        };
    }
}

"""Helper to build a prompt result with proper system/user role separation."""
def _make_prompt(description: str, system: str, user_msg: str) -> dict[str, Any] {
    return {
        "description": description,
        "messages": [
            {"role": "assistant", "content": system},
            {"role": "user", "content": user_msg}
        ]
    };
}

def _prompt_write_module(args: dict[str, str]) -> dict[str, Any] {
    mod_name = args.get("name", "module");
    purpose = args.get("purpose", "");
    has_impl = args.get("has_impl", "true").lower() in ("true", "1", "yes");

    system = build_system_prompt(["jac://guide/patterns"]);
    user_msg = f"Generate a Jac module named '{mod_name}' that {purpose}.";
    if has_impl {
        user_msg += "\nInclude both the declaration file (.jac) and the implementation file (.impl.jac).";
        user_msg += "\nIn the .jac file, method signatures should end with ';'.";
        user_msg += "\nIn the .impl.jac file, use 'impl ClassName.method(...) { body }' syntax.";
    }
    user_msg += "\nAfter generating, validate the code using the validate_jac tool.";

    return _make_prompt(f"Generate Jac module: {mod_name}", system, user_msg);
}

def _prompt_write_impl(args: dict[str, str]) -> dict[str, Any] {
    declarations = args.get("declarations", "");
    system = build_system_prompt(["jac://guide/patterns"]);
    user_msg = f"Generate the .impl.jac file for these declarations:\n\n```jac\n{declarations}\n```";
    user_msg += "\n\nUse 'impl ClassName.method(...) {{ body }}' syntax for each method.";
    user_msg += "\nAfter generating, validate the code using the validate_jac tool.";

    return _make_prompt("Generate .impl.jac implementation", system, user_msg);
}

def _prompt_write_walker(args: dict[str, str]) -> dict[str, Any] {
    name = args.get("name", "my_walker");
    purpose = args.get("purpose", "");
    node_types = args.get("node_types", "");

    system = build_system_prompt(["jac://docs/osp", "jac://guide/patterns"]);
    user_msg = f"Generate a walker named '{name}' that {purpose}, traversing node types: {node_types}.";
    user_msg += "\nUse 'visit [-->]' for traversal and proper Jac walker syntax.";
    user_msg += "\nAfter generating, validate the code using the validate_jac tool.";

    return _make_prompt(f"Generate walker: {name}", system, user_msg);
}

def _prompt_write_node(args: dict[str, str]) -> dict[str, Any] {
    name = args.get("name", "MyNode");
    fields = args.get("fields", "");

    system = build_system_prompt(["jac://docs/osp"]);
    user_msg = f"Generate a node archetype named '{name}' with fields: {fields}.";
    user_msg += "\nUse 'has' declarations with type annotations.";
    user_msg += "\nAfter generating, validate the code using the validate_jac tool.";

    return _make_prompt(f"Generate node: {name}", system, user_msg);
}

def _prompt_write_test(args: dict[str, str]) -> dict[str, Any] {
    module_name = args.get("module_name", "");
    functions_to_test = args.get("functions_to_test", "");

    system = build_system_prompt(["jac://guide/patterns"]);
    user_msg = f"Generate test blocks for module '{module_name}' covering: {functions_to_test}.";
    user_msg += '\nUse Jac test block syntax: test "description" {{ assertions; }}';
    user_msg += "\nAfter generating, validate the code using the validate_jac tool.";

    return _make_prompt(f"Generate tests for: {module_name}", system, user_msg);
}

def _prompt_write_ability(args: dict[str, str]) -> dict[str, Any] {
    name = args.get("name", "");
    signature = args.get("signature", "");
    purpose = args.get("purpose", "");

    system = build_system_prompt(["jac://docs/functions-objects"]);
    user_msg = f"Generate an ability named '{name}' with signature '{signature}' that {purpose}.";
    user_msg += "\nAfter generating, validate the code using the validate_jac tool.";

    return _make_prompt(f"Generate ability: {name}", system, user_msg);
}

def _prompt_debug_error(args: dict[str, str]) -> dict[str, Any] {
    error_output = args.get("error_output", "");
    code = args.get("code", "");

    system = build_system_prompt();
    user_msg = f"Debug this Jac compilation error:\n\n```\n{error_output}\n```";
    user_msg += f"\n\nIn this code:\n\n```jac\n{code}\n```";
    user_msg += "\n\nExplain the error, identify the root cause, and provide the corrected code.";
    user_msg += "\nValidate the corrected code using the validate_jac tool before presenting it.";

    return _make_prompt("Debug compilation error", system, user_msg);
}

def _prompt_fix_type_error(args: dict[str, str]) -> dict[str, Any] {
    error_output = args.get("error_output", "");
    code = args.get("code", "");

    system = build_system_prompt(["jac://docs/primitives"]);
    user_msg = f"Fix this type error:\n\n```\n{error_output}\n```";
    user_msg += f"\n\nIn this code:\n\n```jac\n{code}\n```";
    user_msg += "\n\nExplain the type mismatch and provide corrected code.";
    user_msg += "\nValidate the corrected code using the validate_jac tool before presenting it.";

    return _make_prompt("Fix type error", system, user_msg);
}

def _prompt_migrate_python(args: dict[str, str]) -> dict[str, Any] {
    python_code = args.get("python_code", "");

    system = build_system_prompt(
        ["jac://docs/python-integration", "jac://guide/patterns"]
    );
    user_msg = f"Convert this Python code to idiomatic Jac:\n\n```python\n{python_code}\n```";
    user_msg += "\n\nUse obj instead of class, has instead of self.x, can for methods, semicolons, braces, and Jac import syntax.";
    user_msg += "\nAfter converting, validate the code using the validate_jac tool.";

    return _make_prompt("Migrate Python to Jac", system, user_msg);
}

def _prompt_write_client_component(args: dict[str, str]) -> dict[str, Any] {
    name = args.get("name", "MyComponent");
    purpose = args.get("purpose", "");
    props = args.get("props", "");

    system = build_system_prompt(
        [
            "jac://guide/pitfalls_client",
            "jac://guide/patterns_client",
            "jac://docs/tutorial-fullstack-components",
            "jac://docs/tutorial-fullstack-state"
        ]
    );
    user_msg = f"Generate a Jac client component named '{name}' that {purpose}.";
    user_msg += "\nThe component MUST be inside a cl {{ }} block and return JsxElement.";
    user_msg += "\nUse 'has' for reactive state (NOT useState), 'className' (NOT class).";
    user_msg += "\nEvent handlers need type annotations: lambda e: any -> None {{ ... }}";
    user_msg += "\nUse list comprehensions for rendering lists: {{[<Item /> for item in items]}}";
    if props {
        user_msg += f"\nComponent props: {props}";
    }
    user_msg += "\nFor state updates on lists/dicts, create new references (items = items + [x], NOT items.append(x)).";
    user_msg += "\nAfter generating, validate the code using the validate_jac tool.";

    return _make_prompt(f"Generate client component: {name}", system, user_msg);
}

def _prompt_write_walker_endpoint(args: dict[str, str]) -> dict[str, Any] {
    name = args.get("name", "my_endpoint");
    purpose = args.get("purpose", "");
    visibility = args.get("visibility", "pub");
    fields = args.get("fields", "");

    system = build_system_prompt(
        [
            "jac://guide/pitfalls_api",
            "jac://guide/patterns_fullstack",
            "jac://docs/osp"
        ]
    );
    vis = "pub" if "pub" in visibility.lower() else "priv";
    user_msg = f"Generate a walker:{vis} endpoint named '{name}' that {purpose}.";
    user_msg += f"\nUse 'walker:{vis} {name} {{ ... }}' syntax.";
    user_msg += "\nWalker 'has' fields become the HTTP request body automatically.";
    user_msg += "\nUse 'report' to return data — it becomes the HTTP response body.";
    user_msg += "\nUse 'can ... with Root entry {{ }}' for the entry ability.";
    if vis == "priv" {
        user_msg += "\nWith :priv, each user gets isolated data automatically — no need for user ID filtering.";
    }
    if fields {
        user_msg += f"\nRequest body fields: {fields}";
    }
    user_msg += "\nAfter generating, validate the code using the validate_jac tool.";

    return _make_prompt(f"Generate walker endpoint: {name}", system, user_msg);
}

def _prompt_write_auth_flow(args: dict[str, str]) -> dict[str, Any] {
    pages = args.get("pages", "both");
    redirect_to = args.get("redirect_to", "/");

    system = build_system_prompt(
        [
            "jac://guide/pitfalls_client",
            "jac://guide/pitfalls_api",
            "jac://docs/tutorial-fullstack-auth"
        ]
    );
    user_msg = "Generate Jac authentication pages.";
    if "both" in pages.lower()
    or ("login" in pages.lower() and "signup" in pages.lower()) {
        user_msg += "\nGenerate BOTH a login page and a signup page.";
    } elif "login" in pages.lower() {
        user_msg += "\nGenerate a login page.";
    } elif "signup" in pages.lower() {
        user_msg += "\nGenerate a signup page.";
    }
    user_msg += "\n\nIMPORTANT rules:";
    user_msg += "\n- Import auth functions from @jac/runtime: jacLogin, jacSignup, jacLogout, jacIsLoggedIn, useNavigate";
    user_msg += "\n- Use 'has' for form state (username, password, error, loading)";
    user_msg += "\n- Use 'await jacLogin(username, password)' which returns bool";
    user_msg += "\n- Use 'await jacSignup(username, password)' which returns dict with 'success' key";
    user_msg += f"\n- Redirect to '{redirect_to}' after successful login/signup using navigate()";
    user_msg += "\n- All event handlers need type annotations: lambda e: any -> None {{ ... }}";
    user_msg += "\n- Everything must be inside cl {{ }} blocks";
    user_msg += "\nAfter generating, validate the code using the validate_jac tool.";

    return _make_prompt("Generate auth flow", system, user_msg);
}

def _prompt_write_fullstack_feature(args: dict[str, str]) -> dict[str, Any] {
    name = args.get("name", "feature");
    purpose = args.get("purpose", "");
    data_model = args.get("data_model", "");
    operations = args.get("operations", "list, create");

    system = build_system_prompt(
        [
            "jac://guide/pitfalls_client",
            "jac://guide/pitfalls_fullstack",
            "jac://guide/pitfalls_api",
            "jac://guide/patterns_fullstack",
            "jac://guide/patterns_client",
            "jac://docs/tutorial-fullstack-backend"
        ]
    );
    user_msg = f"Generate a full-stack Jac feature named '{name}' that {purpose}.";
    user_msg += "\n\nGenerate these files:";
    user_msg += "\n1. Server-side: node types + walker:pub endpoints in main.jac";
    user_msg += "\n2. Client-side: UI component in cl {{ }} block that calls server walkers";
    user_msg += f"\n\nData model: {data_model}";
    user_msg += f"\nOperations needed: {operations}";
    user_msg += "\n\nServer rules:";
    user_msg += "\n- Use walker:pub for public endpoints, walker:priv for per-user endpoints";
    user_msg += "\n- Walker 'has' fields = request body, 'report' = response body";
    user_msg += "\n- Use 'can ... with Root entry {{ }}' for entry abilities";
    user_msg += "\n\nClient rules:";
    user_msg += "\n- Use 'sv import from ...main {{ walker_name }}' to import server walkers";
    user_msg += "\n- Use 'root spawn walker_name(field=value)' to call endpoints";
    user_msg += "\n- Access results via 'result.reports[0]'";
    user_msg += "\n- Use 'has' for reactive state, immutable updates (items = items + [x])";
    user_msg += "\n- Event handlers need type annotations: lambda e: any -> None {{ ... }}";
    user_msg += "\nAfter generating, validate ALL code using the validate_jac tool.";

    return _make_prompt(f"Generate full-stack feature: {name}", system, user_msg);
}
