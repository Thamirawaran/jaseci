"""File covering plugin implementation."""
import os;
import pathlib;
import pickle;
import sys;
import from dotenv { load_dotenv }
import from jaclang.cli.cmdreg { CommandPriority, cmd_registry }
import from jaclang.pycore.runtime { hookimpl, plugin_manager }
import from jaclang.runtimelib.context { ExecutionContext }
import from jaclang.pycore.runtime { JacRuntime as Jac }
import from .context { JScaleExecutionContext }
import from .kubernetes.docker_impl { build_and_push_docker }
import from .kubernetes.K8s { deploy_K8s }
import from .kubernetes.utils { cleanup_K8s_resources }
import from .serve { JacAPIServer, Platforms }
import from jac_scale.config_loader { get_scale_config }
import from fastapi.middleware.cors { CORSMiddleware }
"""Jac CLI."""
class JacCmd {
    """Create Jac CLI cmds."""
    @hookimpl
    static def create_cmd -> None {
        """Jac Scale functionality.""";
        @cmd_registry.register(priority=CommandPriority.PLUGIN, source='jac-scale')
        def scale(file_path: str, build: bool = False) -> None {
            if not os.path.exists(file_path) {
                raise FileNotFoundError(f"File not found: '{file_path}'") ;
            }
            code_folder = os.path.dirname(file_path) or '.';
            dotenv_path = os.path.join(code_folder, '.env');
            load_dotenv(dotenv_path);
            code_folder = os.path.relpath(code_folder);
            code_folder = pathlib.Path(code_folder).as_posix();
            base_file_path = os.path.basename(file_path);
            if build {
                build_and_push_docker(code_folder);
            }
            deploy_K8s(code_folder, base_file_path, build);
        }
        """Jac Destroys functionality.""";
        @cmd_registry.register(priority=CommandPriority.PLUGIN, source='jac-scale')
        def destroy(file_path: str) -> None {
            if not os.path.exists(file_path) {
                raise FileNotFoundError(f"File not found: '{file_path}'") ;
            }
            code_folder = os.path.dirname(file_path) or '.';
            dotenv_path = os.path.join(code_folder, '.env');
            load_dotenv(dotenv_path);
            cleanup_K8s_resources();
        }
    }
}

"""Jac Scale Plugin Implementation."""
class JacScalePlugin {
    @hookimpl
    static def create_j_context(
        session: (str | None) = None, <>root: (str | None) = None
    ) -> ExecutionContext {
        return JScaleExecutionContext(session=session, <>root=<>root);
    }

    @hookimpl
    static def create_server(apiserver: JacAPIServer, host: str,) -> Any {
        import from jac_scale.jserver.jfast_api { JFastApiServer }
        scale_server = JFastApiServer([]);
        scale_server.app.add_middleware(
            CORSMiddleware,
            allow_origins=['*'],
            allow_credentials=True,
            allow_methods=['*'],
            allow_headers=['*']
        );
        return scale_server;
    }

    @hookimpl
    static def add_platform -> dict {
        supported_platforms: dict = {};
        # Load SSO config fresh (not from cached global) to support env var overrides at runtime
        sso_config = get_scale_config().get_sso_config();
        for platform in Platforms {
            key = platform.lower();
            platform_config = sso_config.get(key, {});

            client_id = platform_config.get('client_id', '');
            client_secret = platform_config.get('client_secret', '');

            if not client_id or not client_secret {
                continue;
            }

            supported_platforms[platform.value] = {
                "client_id": client_id,
                "client_secret": client_secret
            };
        }
        return supported_platforms;
    }

    @hookimpl
    static def start_server(
        server: JacAPIServer
    ) -> None {
        JacAPIServer.start(server);
    }

    @hookimpl
    static def render_page_callback(
        jac_server: JacAPIServer
    ) -> Callable[..., HTMLResponse] {
        return JacAPIServer.render_page_callback(jac_server);
    }

    @hookimpl
    static def create_user(
        jac_server: JacAPIServer, username: str, password: str
    ) -> JSONResponse {
        return JacAPIServer.create_user(jac_server, username, password);
    }

    @hookimpl
    static def login(jac_server: JacAPIServer, username: str, password: str) -> JSONResponse {
        return JacAPIServer.login(jac_server, username, password);
    }
}

# Pluggy's varnames() puts parameters with defaults into kwargnames, not argnames.
# But _multicall only passes argnames to hook implementations.
# JacRuntimeInterfaceImpl strips defaults via generate_plugin_helpers, so we must too.
import inspect;
glob func = JacScalePlugin.create_j_context,
     sig = inspect.signature(func),
     sig_nodef = sig.replace(
         parameters=[
             p.replace(default=inspect.Parameter.empty)
             for p in sig.parameters.values()
         ]
     );

with entry {
    func.__signature__ = sig_nodef;
    plugin_manager.register(JacScalePlugin());
}
