import mimetypes;
import from collections.abc { Callable }
import from datetime { UTC, datetime, timedelta }
import from pathlib { Path }
import from typing { Any }
import jwt;
import from os { getenv }
import from fastapi.middleware.cors { CORSMiddleware }
import from fastapi.responses { HTMLResponse, JSONResponse, Response, RedirectResponse }
import from jac_scale.jserver.jfast_api { JFastApiServer }
import from jac_scale.jserver.jserver {
    APIParameter,
    HTTPMethod,
    JEndPoint,
    ParameterType
}
import from jaclang.pycore.runtime { JacRuntime as Jac }
import from jaclang.runtimelib.server { JacAPIServer as JServer }
import from jaclang.runtimelib.server { JsonValue }
import from jaclang.runtimelib.server { JsonValue }
import from enum { StrEnum }
import from fastapi_sso.sso.google { GoogleSSO }
import from jac_scale.utils { generate_random_password }
import from jac_scale.config_loader { get_scale_config }

# Load configuration from jac.toml with env var overrides
glob _jwt_config = get_scale_config().get_jwt_config(),
     _sso_config = get_scale_config().get_sso_config(),
     JWT_SECRET = _jwt_config['secret'],
     JWT_ALGORITHM = _jwt_config['algorithm'],
     JWT_EXP_DELTA_DAYS = _jwt_config['exp_delta_days'],
     SSO_HOST = _sso_config['host'];

class Platforms(StrEnum) {
    has GOOGLE: str = 'google';
}

class Operations(StrEnum) {
    has LOGIN: str = 'login',
        REGISTER: str = 'register';
}

class JacAPIServer {
    static def create_jwt_token(username: str) -> str;
    static def validate_jwt_token(token: str) -> (str | None);
    static def refresh_jwt_token(token: str) -> (str | None);
    static def login(jac_server: Any, username: str, password: str) -> JSONResponse;
    static def register_login_endpoint(jac_server: Any) -> None;
    static def create_user(
        jac_server: Any, username: str, password: str
    ) -> JSONResponse;

    static def refresh_token(token: (str | None) = None) -> JSONResponse;
    static def register_create_user_endpoint(jac_server: Any) -> None;
    static def register_refresh_token_endpoint(jac_server: Any) -> None;
    static def get_sso(
        jac_server: Any, platform: str, operation: str
    ) -> (GoogleSSO | None);

    async static def sso_initiate(
        jac_server: Any, platform: str, operation: str
    ) -> Response;

    async static def sso_callback(
        jac_server: Any, request: Request, platform: str, operation: str
    ) -> JSONResponse;

    static def register_sso_endpoints(jac_server: Any) -> None;
    static def create_walker_callback(
        jac_server: Any, walker_name: str, has_node_param: bool = False
    ) -> Callable[..., dict[(str, JsonValue)]];

    static def create_walker_parameters(
        jac_server: Any, walker_name: str, invoke_on_root: bool
    ) -> list[APIParameter];

    static def register_walkers_endpoints(jac_server: Any) -> None;
    static def create_function_callback(
        jac_server: Any, func_name: str
    ) -> Callable[..., dict[(str, JsonValue)]];

    static def create_function_parameters(
        jac_server: Any, func_name: str
    ) -> list[APIParameter];

    static def register_functions_endpoints(jac_server: Any) -> None;
    static def render_page_callback(jac_server: Any) -> Callable[..., HTMLResponse];
    static def render_base_route_callback(
        jac_server: Any, app_name: str
    ) -> Callable[..., HTMLResponse];

    static def register_page_endpoint(jac_server: Any) -> None;
    static def serve_client_js_callback(jac_server: Any) -> Callable[..., Response];
    static def register_client_js_endpoint(jac_server: Any) -> None;
    static def register_static_file_endpoint(jac_server: Any) -> None;
    static def serve_static_file(file_path: str) -> Response;
    static def register_root_asset_endpoint(jac_server: Any) -> None;
    static def serve_root_asset(file_path: str) -> Response;
    static def _configure_openapi_security(jac_server: Any) -> None;
    static def start(jac_server: Any) -> None;
}
