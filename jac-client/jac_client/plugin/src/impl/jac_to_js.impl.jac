"""Add runtime imports to compiled JS code."""

impl JacToJSCompiler.add_runtime_imports(js_code: str) -> str {
    # Skip adding import if this file IS the runtime (defines __jacJsx itself)
    if "function __jacJsx(" in js_code {
        return js_code;
    }
    # All known runtime exports that user code may reference
    all_runtime_symbols: list[str] = [
        '__jacJsx', '__jacSpawn', '__jacCallFunction', '__jacReportError',
        '__jacInstallErrorHandlers', '__createJacSchema',
        '__doWalkerFetch', '__doFuncFetch', '__cachedEndpointCall',
        '__cacheGet', '__cacheSet', '__evictOldest', '__isFresh',
        '__getCacheState', '__getEndpointEffects',
        '__getApiBaseUrl', '__getLocalStorage', '__setLocalStorage',
        '__removeLocalStorage', '__invalidateEndpoint', '__overlaps',
        'jacSpawn', 'jacSignup', 'jacLogin', 'jacLogout', 'jacIsLoggedIn',
        'navigate', 'useRouter', 'useNavigate', 'useLocation', 'useParams',
        'useState', 'useEffect', 'useJacForm',
        'AuthGuard', 'ErrorFallback', 'errorOverlay',
        'JacForm', 'JacSchema', 'JacClientErrorBoundary',
        'Router', 'Routes', 'Route', 'Link', 'Navigate', 'Outlet'
    ];
    # Find which runtime symbols are actually used in this code
    needed: list[str] = [];
    for sym in all_runtime_symbols {
        if sym in js_code {
            needed.append(sym);
        }
    }
    if not needed {
        needed = ['__jacJsx', '__jacSpawn'];
    }
    import_line = 'import {' + ', '.join(sorted(needed)) + '} from "@jac/runtime";';
    return f"{import_line}\n{js_code}";
}

"""Extract client globals from manifest and module."""
impl JacToJSCompiler.extract_globals(
    manifest: (ClientManifest | None), module: ModuleType
) -> dict[str, Any] {
    return self._extract_client_globals(manifest, module);
}

"""Extract client exports from manifest."""
impl JacToJSCompiler.extract_exports(manifest: (ClientManifest | None)) -> list[str] {
    return self._extract_client_exports(manifest);
}

"""Compile a Jac module to JavaScript."""
impl JacToJSCompiler.compile_module(
    module_path: Path
) -> tuple[str, (ModuleType | None), (ClientManifest | None)] {
    (module_js, mod) = self._compile_to_js(module_path);
    manifest = mod.gen.client_manifest if mod else None;
    return (module_js, mod, manifest);
}
