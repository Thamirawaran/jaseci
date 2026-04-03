# jac-mcp Release Notes

## jac-mcp 0.1.9 (Unreleased)

### Profile-aware model support

The server now adapts its behavior based on a `profile` setting in `jac.toml`, making it effective across model sizes:

- **`minimal` profile (~11 tools, 5 prompts)**: Designed for small models (Haiku, etc.). Collapses overlapping tools into composites (e.g., `fix_error` replaces 5 separate validation tools), uses a condensed top-15 pitfalls guide, and sends a simplified 3-step workflow in server instructions.
- **`standard` profile (~20 tools, 12 prompts)**: Balanced set for mid-range models (Sonnet, GPT-4o). Full pitfalls guide, capped resource loading (max 2 per prompt), 5-step workflow.
- **`full` profile (32 tools, 13 prompts)**: All tools and prompts for large models (Opus). Unchanged from previous behavior. Remains the default.

Configure with a single line:

```toml
[plugins.mcp]
profile = "minimal"    # or "standard" or "full"
```

Individual tool flags (`enable_transpile`, `enable_cli_tools`, `enable_project`) can override profile defaults.

### New tools (v2)

- **Targeted retrieval**: `get_doc_section` (section by heading match), `get_example_file` (single file), `list_example_files` (file listing with sizes) - lighter alternatives to full-document fetching
- **Workflow guidance**: `recommend_workflow` (task-aware steps/resources), `recommend_docs` (doc recommendations), `find_example` (example matching)
- **Composite validation**: `fix_error` (validate + explain in one call), `inspect_validation` (errors grouped by root cause)
- **Project tools**: `create_project` (scaffold from template), `list_templates`, `preview_endpoints` (analyze HTTP endpoints without starting server), `inspect_project` (file inventory, walkers, endpoints)
- **Knowledge map**: `understand_jac_and_jaseci` - orientation guide with resource URIs

### New prompts (v2)

- `write_client_component`: Generate `cl {}` components with reactive state and JSX
- `write_walker_endpoint`: Generate `walker:pub` or `walker:priv` HTTP endpoints
- `write_auth_flow`: Generate login/signup pages with built-in auth functions
- `write_fullstack_feature`: Generate coordinated server walkers + client UI

### Session caching

- Resource content (`read_resource`) is now cached per session - repeated reads of pitfalls, docs, or examples skip disk/network I/O
- GitHub API responses are cached per session - browsing examples no longer makes redundant API calls

### Expanded pitfalls guide

- Added 10 new battle-tested pitfalls (sections 44-53) from real-world devkit applications: `root` vs `root()` in client code, `sv import` same-file walkers, `getattr` for `.reports`, `dict()`/`list()` casting in client code, `sv import` for types, null API response guards, Python string methods in JS, JSX component hooks, Router `basename`, computed dict keys
- New `pitfalls_essential.md` - condensed top-15 guide used by minimal profile

### Config schema

- Added missing `enable_transpile`, `enable_cli_tools`, `enable_project` options to `[plugins.mcp]` config schema
- All config options are now discoverable and documented

### Documentation

- Updated MCP docs with all 32 tools (organized by category with profile availability)
- Updated prompts documentation (13 prompts, grouped by profile tier)
- Added profiles section with comparison table
- Added new guide resources (`pitfalls_essential`, `understand`)

## jac-mcp 0.1.8 (Latest Release)

- **Full CLI access over MCP**: AI models can now discover and run any `jac` CLI command (including plugin-provided ones) directly from the MCP session. `list_commands` returns a lightweight summary; `get_command(name)` returns full argument details; `execute_command` runs them. Replaces the narrower `start_server`, `create_project`, and `list_templates` tools.

## jac-mcp 0.1.7

- 2 small changes.
- **8 new tools**: AI models can now run Jac code, lint files, convert Jac to Python or JavaScript, visualize graphs, list project templates, scaffold new projects, and start a local server - all from within the MCP session.
- **`jac_to_js` fix**: Client-side transpilation now correctly targets `.cl.jac` files; previously produced no output.
- **`start_server` fix**: Server startup now runs from the project's directory so `jac.toml` is discovered correctly.
- **Expanded test coverage**: 35 new tests covering all new tools at both the `CompilerBridge` and `ToolProvider` levels.
- **Richer example descriptions**: `list_examples` now returns a meaningful one-line description per example (fullstack, OSP, native/lib mode, etc.) so AI models can pick the right one without fetching its contents first.

## jac-mcp 0.1.6

- **Fix SSE transport method issue**
- **Fix `prompts/get` failing with Pydantic validation error**: System instructions now correctly use `role: "assistant"`
- **Fix CompilerBridge tools returning incorrect results**: `check_syntax`, `validate_jac`, and `get_ast` now use the compiler's structured diagnostics and parse API to correctly detect errors and return real AST output
- **Fix error reporting and example loading**: Syntax errors now report accurate line/column numbers. `list_examples` now correctly falls back to GitHub API when installed from PyPI, instead of returning an empty list
- **Fix jac-mcp configuration issue in `jac.toml`***: Respect [plugins.mcp] config from jac.toml in jac mcp, using it as fallback when CLI args are not explicitly provided.
- **Lazy GitHub-based example fetching**: Examples are now fetched on-demand from GitHub instead of being bundled in the PyPI package, reducing package size and ensuring examples are always up-to-date. Local repo examples are used when available, with GitHub as a fallback

## jac-mcp 0.1.5

## jac-mcp 0.1.4

- **Fix streamable HTTP transport method issue**: Refactors the server initialization logic for the `streamable-http` transport method.
- 1 small change/refactor.

## jac-mcp 0.1.3

- **Updated token definitions path**: Grammar resource now references `tokens.na.jac` (renamed from `tokens.jac`)
- **Added backtick escaping pitfall**: New section documenting when keywords need backtick escaping and clarifying that special variable references (`self`, `super`, `root`, `here`, `visitor`, `init`, `postinit`) are used directly without backticks

## jac-mcp 0.1.2

- **Compiler-validated MCP content**: Cross-validated all code snippets in pitfalls.md and patterns.md against the Jac compiler, fixing critical issues where the server was teaching syntax the compiler rejects
- **Fixed `can` vs `def` guidance**: `can` is only for event-driven abilities (`can X with Y entry`); `def` is correct for regular methods. Updated pitfalls, patterns, and SERVER_INSTRUCTIONS accordingly
- **Fixed `enumerate()` pitfall**: Corrected documentation that wrongly said `enumerate()` is unsupported in Jac
- **Removed invalid `<>` ByRef pitfall**: This syntax does not exist in current Jac
- **Fixed `class` vs `obj` pitfall**: `class` is valid Jac syntax alongside `obj`
- **Fixed match/case syntax in patterns**: Uses colon syntax, not braces
- **Enhanced SERVER_INSTRUCTIONS**: Corrected `can`/`def` guidance sent to AI clients during MCP initialization
- **Enhanced tool descriptions**: Added workflow guidance (MUST validate, use before writing, etc.)
- **System/user role separation**: All 9 prompt templates now use proper role separation
- **QA test suite**: Added 149-test `qa_server.jac` covering resources, tools, prompts, server instructions, and compiler validation

## jac-mcp 0.1.1

- **Expanded documentation resources**: DOC_MAPPINGS now covers all 42 mkdocs pages (up from 12), including tutorials, developer workflow, and quick-start guides
- **Auto-generated doc bundling**: New `scripts/bundle_docs.jac` script replaces hardcoded CI copy commands, using DOC_MAPPINGS as the single source of truth for PyPI release bundling

## jac-mcp 0.1.0

Initial release of jac-mcp, the MCP (Model Context Protocol) server plugin for Jac.

### Features

- **MCP Server**: Full MCP server with stdio, SSE, and streamable-http transport support
- **Resources (24+)**: Grammar spec, token definitions, 11 documentation sections, example index, bundled pitfalls/patterns guides
- **Tools (9)**: validate_jac, check_syntax, format_jac, py_to_jac, explain_error, list_examples, get_example, search_docs, get_ast
- **Prompts (9)**: write_module, write_impl, write_walker, write_node, write_test, write_ability, debug_error, fix_type_error, migrate_python
- **Compiler Bridge**: Parse, typecheck, format, and py2jac operations with timeout protection and input size limits
- **CLI Integration**: `jac mcp` command with --transport, --port, --host, --inspect flags
- **Plugin System**: Full Jac plugin with JacCmd and JacPluginConfig hooks
