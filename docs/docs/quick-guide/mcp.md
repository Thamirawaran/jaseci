# MCP Server (jac-mcp)

The `jac-mcp` plugin provides a [Model Context Protocol](https://modelcontextprotocol.io/) server that gives AI assistants deep knowledge of the Jac language. It exposes grammar specifications, documentation, code examples, compiler tools, and prompt templates through a standardized protocol --so any MCP-compatible AI client can write, validate, format, and debug Jac code.

## Installation

If you installed Jaseci via PyPI or the install script, `jac-mcp` is likely already included. Run `jac --version` to check -- it prints all installed plugins. If `jac-mcp` appears in the list, you're good to go.

Otherwise, install it separately:

```bash
pip install jac-mcp
```

## Quick Start

### 1. Start the MCP server

```bash
jac mcp
```

This starts the server with the default **stdio** transport, ready for IDE integration.

### 2. Inspect what's available

```bash
jac mcp --inspect
```

This prints all available resources, tools, and prompts, then exits.

### 3. Connect your AI client

Add the server to your AI client's MCP configuration (see [IDE Integration](#ide-integration) below), then start using Jac tools directly from your AI assistant.

## IDE Integration

### Claude Desktop

Add to `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS) or `%APPDATA%\Claude\claude_desktop_config.json` (Windows):

```json
{
  "mcpServers": {
    "jac": {
      "command": "jac",
      "args": ["mcp"]
    }
  }
}
```

Restart Claude Desktop after saving. The Jac tools will appear in the tool picker (hammer icon).

### Claude Code (CLI)

Add to your project's `.mcp.json`:

```json
{
  "mcpServers": {
    "jac": {
      "command": "jac",
      "args": ["mcp"],
      "type": "stdio"
    }
  }
}
```

Or add it interactively:

```bash
claude mcp add jac -- jac mcp
```

### Cursor

Add to `.cursor/mcp.json` in your project root:

```json
{
  "mcpServers": {
    "jac": {
      "command": "jac",
      "args": ["mcp"]
    }
  }
}
```

After saving, open Cursor Settings > MCP and verify the server shows a green status indicator.

### VS Code with Continue

Add to your Continue config (`.continue/config.json`):

```json
{
  "mcpServers": [
    {
      "name": "jac",
      "command": "jac",
      "args": ["mcp"]
    }
  ]
}
```

### VS Code with Copilot Chat

Add to your VS Code `settings.json`:

```json
{
  "mcp": {
    "servers": {
      "jac": {
        "command": "jac",
        "args": ["mcp"]
      }
    }
  }
}
```

### Windsurf

Add to `~/.windsurf/mcp_config.json`:

```json
{
  "mcpServers": {
    "jac": {
      "command": "jac",
      "args": ["mcp"]
    }
  }
}
```

### Remote / SSE Clients

For clients that connect over HTTP rather than stdio:

```bash
jac mcp --transport sse --port 3001
```

Then configure your client to connect to:

- **SSE endpoint:** `http://127.0.0.1:3001/sse`
- **Message endpoint:** `http://127.0.0.1:3001/messages/` (POST)

!!! tip
    If your `jac` binary is installed in a virtualenv, use the full path in the `command` field (e.g., `/path/to/venv/bin/jac`). You can find it with `which jac`.

## CLI Reference

```
jac mcp [OPTIONS]
```

| Option | Default | Description |
|---|---|---|
| `--transport` | `stdio` | Transport protocol: `stdio`, `sse`, or `streamable-http` |
| `--port` | `3001` | Port for SSE/HTTP transports |
| `--host` | `127.0.0.1` | Bind address for SSE/HTTP transports |
| `--inspect` | `false` | Print inventory of resources, tools, and prompts then exit |

**Examples:**

```bash
# Default stdio (for IDE integration)
jac mcp

# SSE on custom port
jac mcp --transport sse --port 8080

# Streamable HTTP
jac mcp --transport streamable-http --port 3001

# See everything the server exposes
jac mcp --inspect
```

## Configuration

Add to your project's `jac.toml` to customize the server:

```toml
[plugins.mcp]
# Profile: controls how many tools, prompts, and context the server exposes
# "minimal"  - ~11 tools, 5 prompts, condensed pitfalls (for small models like Haiku)
# "standard" - ~20 tools, 12 prompts, full pitfalls (for mid-range models like Sonnet)
# "full"     - 32 tools, 13 prompts, full pitfalls + all resources (for large models like Opus)
profile = "full"

# Transport settings
transport = "stdio"          # "stdio", "sse", or "streamable-http"
port = 3001                  # Port for SSE/HTTP transports
host = "127.0.0.1"          # Bind address for SSE/HTTP transports

# Resource exposure
expose_grammar = true        # Expose jac.spec and token definitions
expose_docs = true           # Expose language documentation
expose_examples = true       # Expose example Jac projects
expose_pitfalls = true       # Expose common AI mistakes guide

# Tool enable/disable (override profile defaults)
enable_validate = true       # validate_jac and check_syntax tools
enable_format = true         # format_jac and lint_jac tools
enable_py2jac = true         # py_to_jac conversion tool
enable_ast = false           # get_ast tool (verbose, off by default)
enable_transpile = false     # jac_to_py and jac_to_js tools (full profile default)
enable_cli_tools = false     # list_commands, get_command, execute_command (full profile default)
enable_project = true        # list_templates, create_project, preview_endpoints

# Project context
project_root = "."           # Root directory for project-aware tools
```

### Profiles

Profiles adapt the server's behavior for different model capabilities. The key differences:

| Dimension | `minimal` | `standard` | `full` |
|---|---|---|---|
| **Tools** | ~11 (composites) | ~20 | 32 |
| **Prompts** | 5 | 12 | 13 |
| **Server instructions** | 3-step workflow | 5-step workflow | 8-step workflow |
| **Pitfalls in prompts** | Essential top 15 | Full (53 sections) | Full (53 sections) |
| **Extra resources per prompt** | 0 (inline rules only) | Up to 2 | Unlimited |

**Minimal** collapses overlapping tools into composites (e.g., `fix_error` replaces `validate_jac` + `check_syntax` + `explain_error` + `inspect_validation` in a single call), reducing tool selection confusion for smaller models.

**Standard** provides a balanced set with most v2 tools, suited for models that handle 15-20 tools well.

**Full** exposes everything including CLI tools, transpilation, AST introspection, and the most complex prompt templates.

You can override individual tool flags on any profile:

```toml
[plugins.mcp]
profile = "minimal"
enable_transpile = true   # Re-enable transpile even on minimal
```

## Transport Options

| Transport | Flag | Use Case | Requirements |
|---|---|---|---|
| **stdio** | `--transport stdio` | IDE integration (Claude Desktop, Cursor, Claude Code). Default. | None |
| **SSE** | `--transport sse` | Browser-based clients, remote access | None |
| **Streamable HTTP** | `--transport streamable-http` | Advanced HTTP clients, load-balanced deployments | None |

**Endpoint details for HTTP transports:**

| Transport | Endpoints |
|---|---|
| SSE | `GET /sse` (event stream), `POST /messages/` (client messages) |
| Streamable HTTP | `POST /mcp` (bidirectional streaming) |

## Resources (45+)

Resources are read-only reference materials that AI models can load for context. They are served through the `jac://` URI scheme.

### Grammar

| URI | Description |
|---|---|
| `jac://grammar/spec` | Full EBNF grammar specification |
| `jac://grammar/tokens` | Token and keyword definitions |

### Getting Started

| URI | Description |
|---|---|
| `jac://docs/welcome` | Getting started with Jac |
| `jac://docs/install` | Installation guide |
| `jac://docs/core-concepts` | What makes Jac different |
| `jac://docs/first-app` | Build an AI Day Planner tutorial |
| `jac://docs/cheatsheet` | Quick syntax reference |
| `jac://docs/jac-vs-traditional` | Architecture comparison with traditional stacks |
| `jac://docs/faq` | Frequently asked questions |

### Language Specification

| URI | Description |
|---|---|
| `jac://docs/reference-overview` | Full reference index |
| `jac://docs/foundation` | Core language concepts |
| `jac://docs/primitives` | Primitives and codespace semantics |
| `jac://docs/functions-objects` | Archetypes, abilities, has declarations |
| `jac://docs/osp` | Object-Spatial Programming (nodes, edges, walkers) |
| `jac://docs/concurrency` | Concurrency (flow, wait, async) |
| `jac://docs/advanced` | Comprehensions and filters |

### Language Tutorials

| URI | Description |
|---|---|
| `jac://docs/tutorial-coding-primer` | Coding primer for beginners |
| `jac://docs/tutorial-basics` | Jac language fundamentals |
| `jac://docs/tutorial-osp` | Graphs and walkers tutorial |

### AI Integration

| URI | Description |
|---|---|
| `jac://docs/byllm` | byLLM plugin reference |
| `jac://docs/tutorial-ai-quickstart` | Your first AI function |
| `jac://docs/tutorial-ai-structured` | Structured outputs tutorial |
| `jac://docs/tutorial-ai-agentic` | Building AI agents tutorial |
| `jac://docs/tutorial-ai-multimodal` | Multimodal AI tutorial |

### Full-Stack Development

| URI | Description |
|---|---|
| `jac://docs/jac-client` | jac-client plugin reference |
| `jac://docs/tutorial-fullstack-setup` | Project setup |
| `jac://docs/tutorial-fullstack-components` | Components tutorial |
| `jac://docs/tutorial-fullstack-state` | State management |
| `jac://docs/tutorial-fullstack-backend` | Backend integration |
| `jac://docs/tutorial-fullstack-auth` | Authentication |
| `jac://docs/tutorial-fullstack-routing` | Routing |

### Deployment & Scaling

| URI | Description |
|---|---|
| `jac://docs/jac-scale` | jac-scale plugin reference |
| `jac://docs/tutorial-production-local` | Local API server deployment |
| `jac://docs/tutorial-production-k8s` | Kubernetes deployment |

### Developer Workflow

| URI | Description |
|---|---|
| `jac://docs/cli` | CLI command reference |
| `jac://docs/config` | Project configuration |
| `jac://docs/code-organization` | Project structure guide |
| `jac://docs/mcp` | MCP server reference (this page) |
| `jac://docs/testing` | Test framework reference |
| `jac://docs/debugging` | Debugging techniques |

### Python Integration

| URI | Description |
|---|---|
| `jac://docs/python-integration` | Python interoperability |
| `jac://docs/library-mode` | Using Jac as a Python library |

### Quick Reference

| URI | Description |
|---|---|
| `jac://docs/walker-responses` | Walker response patterns |
| `jac://docs/appendices` | Additional language reference |

### Guides & Examples

| URI | Description |
|---|---|
| `jac://guide/pitfalls` | Full common AI mistakes guide (53 sections) |
| `jac://guide/pitfalls_essential` | Condensed top-15 pitfalls (used by minimal profile) |
| `jac://guide/patterns` | Idiomatic Jac code patterns |
| `jac://guide/understand` | Jac & Jaseci knowledge map with resource URIs |
| `jac://examples/*` | Example Jac projects (auto-discovered) |

## Tools (32)

Tools are executable operations that AI models can invoke. They are organized by category. Availability depends on the active [profile](#profiles).

!!! note "Safety limits"
    All compiler tools enforce a **100 KB** maximum input size and a **10-second** timeout per operation.

### Compilation & Validation

| Tool | Description | Profile |
|---|---|---|
| `validate_jac` | Full type-check validation. Returns structured errors and warnings | standard, full |
| `check_syntax` | Parse-only syntax check (faster, no type checking) | full |
| `format_jac` | Format Jac code to standard style | all |
| `lint_jac` | Lint for style violations and unused symbols. Supports `auto_fix` | standard, full |
| `explain_error` | Explain a compiler error with category, root cause, and fix example | full |
| `fix_error` | Validate + explain all errors in one call. Recommended for smaller models | all |
| `inspect_validation` | Group errors by category with root-cause analysis | full |

### Code Transformation

| Tool | Description | Profile |
|---|---|---|
| `py_to_jac` | Transpile Python code to Jac | standard, full |
| `jac_to_py` | Transpile Jac code to Python | full |
| `jac_to_js` | Transpile Jac code to JavaScript (for `.cl.jac` files) | full |
| `get_ast` | Parse Jac code and return AST as tree or JSON | full |

### Execution & Visualization

| Tool | Description | Profile |
|---|---|---|
| `run_jac` | Execute Jac code and return stdout/stderr | all |
| `graph_visualize` | Run Jac code and visualize the graph as DOT or JSON | standard, full |

### Documentation & Examples

| Tool | Description | Profile |
|---|---|---|
| `get_doc_section` | Get a specific section from a doc by heading match (lightweight) | all |
| `get_resource` | Fetch a full doc resource by URI | standard, full |
| `search_docs` | Keyword search across docs, returns ranked snippets | standard, full |
| `get_example_file` | Get a single `.jac` file from an example category (lightweight) | all |
| `list_example_files` | List `.jac` files in an example category with sizes | standard, full |
| `list_examples` | List all example categories with descriptions | full |
| `get_example` | Get all `.jac` files from an example category | full |

### Workflow & Guidance

| Tool | Description | Profile |
|---|---|---|
| `recommend_workflow` | Given a task, recommend resources, tools, and steps | all |
| `recommend_docs` | Given a task, recommend 2-5 most relevant doc resources | standard, full |
| `find_example` | Given a task, find the most relevant examples | all |
| `understand_jac_and_jaseci` | Get the Jac & Jaseci knowledge map with resource URIs | full |

### Project & Testing

| Tool | Description | Profile |
|---|---|---|
| `inspect_project` | Analyze project directory: files, entry points, walkers, endpoints | all |
| `run_tests` | Run Jac tests and return pass/fail results | all |
| `create_project` | Create a new Jac project from a template | all |
| `list_templates` | List available project templates | standard, full |
| `preview_endpoints` | Preview HTTP endpoints a `.jac` file would expose | all |

### CLI Tools

| Tool | Description | Profile |
|---|---|---|
| `list_commands` | List all `jac` CLI commands including plugin-provided ones | full |
| `get_command` | Get full argument details for a specific CLI command | full |
| `execute_command` | Execute a `jac` CLI command with arguments | full |

## Prompts (13)

Prompt templates provide structured system prompts for common Jac development tasks. Each prompt automatically loads the pitfalls guide and relevant reference material as context. The amount of context loaded adapts to the active [profile](#profiles).

### Core Prompts (all profiles)

| Prompt | Description | Key Arguments |
|---|---|---|
| `write_module` | Generate a Jac module with optional `.impl.jac` | `name`, `purpose`, `has_impl` |
| `write_walker` | Generate a walker with visit logic | `name`, `purpose`, `node_types` |
| `debug_error` | Debug a Jac compilation error | `error_output`, `code` |
| `write_client_component` | Generate a `cl {}` component with reactive state and JSX | `name`, `purpose`, `props` |
| `write_walker_endpoint` | Generate a `walker:pub` or `walker:priv` HTTP endpoint | `name`, `purpose`, `visibility`, `fields` |

### Standard & Full Prompts

| Prompt | Description | Key Arguments |
|---|---|---|
| `write_impl` | Generate `.impl.jac` for existing declarations | `declarations` |
| `write_node` | Generate a node archetype with `has` declarations | `name`, `fields` |
| `write_test` | Generate test blocks for a module | `module_name`, `functions_to_test` |
| `write_ability` | Generate an ability (method) implementation | `name`, `signature`, `purpose` |
| `fix_type_error` | Fix a type checking error | `error_output`, `code` |
| `migrate_python` | Convert Python code to idiomatic Jac | `python_code` |
| `write_auth_flow` | Generate login/signup/logout pages with built-in auth | `pages`, `redirect_to` |

### Full Profile Only

| Prompt | Description | Key Arguments |
|---|---|---|
| `write_fullstack_feature` | Generate coordinated server walkers + client UI | `name`, `purpose`, `data_model`, `operations` |

## Troubleshooting

### "command not found: jac"

The `jac` binary is not on your PATH. If installed in a virtualenv, use the full path:

```json
{
  "command": "/path/to/venv/bin/jac",
  "args": ["mcp"]
}
```

Find the path with `which jac` or `python -m site --user-base`.

### Server connects but shows no tools

Run `jac mcp --inspect` to verify the server is working. If it shows tools but your AI client doesn't, restart the AI client --most clients only load MCP servers at startup.

### Tools return timeout errors

The compiler bridge enforces a 10-second timeout per operation. If your code is very large, split it into smaller files. The maximum input size is 100 KB.

### Resources show "Error: File not found"

Resource paths are resolved relative to the jaclang package installation. In a **development install** (`pip install -e`), resources are read directly from the repository's `docs/` directory. In a **PyPI install**, bundled copies are used. If you see missing resources after a PyPI install, update to the latest version:

```bash
pip install --upgrade jac-mcp
```
