"""Plugin configuration hooks for jac-mcp.

This module implements JacPluginConfig hooks to integrate with core's
configuration system, registering:
- Plugin metadata (name, version)
- Config schema for [plugins.mcp] section
"""

import from typing { Any }
import from jaclang.jac0core.runtime { hookimpl }

"""Plugin configuration hooks for jac-mcp."""
class JacMcpPluginConfig {
    """Return plugin metadata."""
    @hookimpl
    static def get_plugin_metadata -> dict[str, Any] {
        return {
            "name": "mcp",
            "version": "0.1.0",
            "description": "MCP server for AI-assisted Jac development"
        };
    }

    """Return the plugin's configuration schema for [plugins.mcp]."""
    @hookimpl
    static def get_config_schema -> dict[str, Any] {
        return {
            "section": "mcp",
            "options": {
                "transport": {
                    "type": "string",
                    "default": "stdio",
                    "description": "Transport protocol: stdio, sse, or streamable-http"
                },
                "port": {
                    "type": "int",
                    "default": 3001,
                    "description": "Port for SSE/HTTP transports (1-65535)"
                },
                "host": {
                    "type": "string",
                    "default": "127.0.0.1",
                    "description": "Bind address for SSE/HTTP transports"
                },
                "expose_grammar": {
                    "type": "bool",
                    "default": True,
                    "description": "Expose jac.spec language grammar as resource"
                },
                "expose_docs": {
                    "type": "bool",
                    "default": True,
                    "description": "Expose reference documentation as resources"
                },
                "expose_examples": {
                    "type": "bool",
                    "default": True,
                    "description": "Expose example code from jaclang/examples"
                },
                "expose_pitfalls": {
                    "type": "bool",
                    "default": True,
                    "description": "Expose curated pitfalls/gotchas guide"
                },
                "enable_validate": {
                    "type": "bool",
                    "default": True,
                    "description": "Enable parse + type-check tools"
                },
                "enable_format": {
                    "type": "bool",
                    "default": True,
                    "description": "Enable Jac code formatting tool"
                },
                "enable_py2jac": {
                    "type": "bool",
                    "default": True,
                    "description": "Enable Python to Jac conversion tool"
                },
                "enable_ast": {
                    "type": "bool",
                    "default": False,
                    "description": "Enable AST introspection tool (verbose)"
                },
                "enable_transpile": {
                    "type": "bool",
                    "default": False,
                    "description": "Enable jac_to_py, jac_to_js transpilation tools (full profile default)"
                },
                "enable_cli_tools": {
                    "type": "bool",
                    "default": False,
                    "description": "Enable list_commands, get_command, execute_command CLI tools (full profile default)"
                },
                "enable_project": {
                    "type": "bool",
                    "default": True,
                    "description": "Enable project tools (list_templates, create_project, preview_endpoints)"
                },
                "project_root": {
                    "type": "string",
                    "default": ".",
                    "description": "Root directory for project-aware tools"
                },
                "profile": {
                    "type": "string",
                    "default": "full",
                    "description": "Tool profile: minimal (fewer tools for small models), standard, or full (all tools)"
                }
            }
        };
    }
}
