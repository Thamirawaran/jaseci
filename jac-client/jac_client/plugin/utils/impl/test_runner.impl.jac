"""Implementation of client-side test runner."""

impl run_client_tests(cl_files: list[str], base_dir: str, entry_point: str = "") -> int {
    import subprocess;
    import json;
    import os;
    import from pathlib { Path }
    import from jaclang.jac0core.runtime { JacRuntime as Jac }
    import from jaclang.compiler.passes.ecmascript { EsastGenPass }
    import from jaclang.cli.console { console }
    import from jac_client.plugin.utils.bun_installer { ensure_bun_available }

    if not ensure_bun_available() {
        console.error('Bun is required for client tests. Install: https://bun.sh');
        return 1;
    }

    # ── Setup directories ──────────────────────────────────────────────
    test_output_dir = Path(base_dir) / '.jac' / 'test-output';
    runners_dir = test_output_dir / 'runners';
    test_output_dir.mkdir(parents=True, exist_ok=True);
    runners_dir.mkdir(parents=True, exist_ok=True);

    # ── Locate plugin resources ────────────────────────────────────────
    import jac_client.plugin as _cl_plugin;
    plugin_dir = Path(list(_cl_plugin.__path__)[0]);
    test_runtime_dir = plugin_dir / 'test_runtime';

    # ── Helper: compile a .cl.jac file to JS ───────────────────────────
    # Uses the same pattern as ClientBundleBuilder._compile_to_js()
    def _compile_to_js(source_path: Path) -> tuple[str, any] {
        source_key = str(source_path);
        Jac.program.errors_had.clear();
        if source_key in Jac.program.mod.hub {
            del Jac.program.mod.hub[source_key];
        }
        mod = Jac.program.compile(source_key);
        if Jac.program.errors_had {
            errors = '\n'.join(str(e) for e in Jac.program.errors_had);
            console.error(f'Compile error: {source_path.name}\n{errors}');
            Jac.program.errors_had.clear();
            return ('', None);
        }
        js_code = (mod.gen.js or '') if mod else '';
        Jac.program.errors_had.clear();
        return (js_code, mod);
    }

    # ── Helper: compile dep without test annexes ───────────────────────
    # Uses no_cgen=True + manual EsastGenPass, same pattern as
    # ViteCompiler.compile_dependencies_recursively() but strips test_mod
    def _compile_dep(source_path: Path) -> tuple[str, any] {
        source_key = str(source_path);
        Jac.program.errors_had.clear();
        if source_key in Jac.program.mod.hub {
            del Jac.program.mod.hub[source_key];
        }
        dep_mod = Jac.program.compile(source_key, no_cgen=True);
        if dep_mod {
            dep_mod.test_mod = [];
            EsastGenPass(ir_in=dep_mod, prog=Jac.program);
        }
        js_code = (dep_mod.gen.js or '') if dep_mod else '';
        Jac.program.errors_had.clear();
        return (js_code, dep_mod);
    }

    # ── Helper: recursively compile dependencies from manifest ─────────
    # Follows the pattern of ViteCompiler.compile_dependencies_recursively()
    def _compile_deps_recursive(
        mod: any, source_path: Path, compiled_deps: set[str], jac_runtime_import: str
    ) -> None {
        manifest = mod.gen.client_manifest if mod else None;
        if not manifest or not manifest.imports {
            return;
        }
        for (import_key, import_resolved) in manifest.imports.items() {
            if import_key.startswith('@jac/') {
                continue;
            }
            # Strip leading dots from import key for filename
            dep_name = import_key.lstrip('.');
            # Resolve dependency path — manifest provides resolved paths
            dep_path: Path | None = None;
            candidates = [
                Path(import_resolved + '.jac'),
                Path(import_resolved),
                source_path.parent / (dep_name + '.cl.jac'),
                source_path.parent / (dep_name + '.jac'),

            ];
            for candidate in candidates {
                if candidate.exists() and str(candidate).endswith('.jac') {
                    dep_path = candidate.resolve();
                    break;
                }
            }
            if dep_path is None or str(dep_path) in compiled_deps {
                continue;
            }
            compiled_deps.add(str(dep_path));
            (dep_js, dep_mod) = _compile_dep(dep_path);
            if dep_js {
                # Add runtime import if needed
                if '__jacJsx' in dep_js and jac_runtime_import not in dep_js {
                    dep_js = jac_runtime_import + '\n' + dep_js;
                }
                dep_js = dep_js.replace(
                    'from "@jac/runtime"', 'from "./client_runtime.js"'
                );
                dep_output = test_output_dir / f'{dep_name}.js';
                dep_output.write_text(dep_js, encoding='utf-8');
                console.success(f'  Compiled dep: {dep_path.name} -> {dep_name}.js');
                # Recurse into transitive dependencies
                _compile_deps_recursive(
                    dep_mod, dep_path, compiled_deps, jac_runtime_import
                );
            }
        }
    }

    # ── Step 1: Compile test runners ───────────────────────────────────
    for (runner_jac, runner_dest) in [
        ('it_runner.cl.jac', 'it.js'),
        ('e2e_runner.cl.jac', 'e2e.js')
    ] {
        runner_src = test_runtime_dir / runner_jac;
        runner_out = runners_dir / runner_dest;
        if runner_src.exists() {
            (runner_js, _) = _compile_to_js(runner_src);
            if runner_js {
                # Playwright requires destructured params in test callbacks.
                # Jac can't express JS destructuring, so post-process.
                if runner_dest == 'e2e.js' {
                    runner_js = runner_js.replace(
                        'function callback(args)',
                        'function callback({ page, browser, context })'
                    );
                    runner_js = runner_js.replace('args.page', 'page');
                    runner_js = runner_js.replace('args.browser', 'browser');
                    runner_js = runner_js.replace('args.context', 'context');
                }
                runner_out.write_text(runner_js, encoding='utf-8');
            } else {
                console.warning(f'Failed to compile runner: {runner_jac}');
            }
        }
    }

    # ── Step 2: Compile real client runtime ────────────────────────────
    # Uses the actual client_runtime.cl.jac from jac-client plugin,
    # same as ViteCompiler.compile_runtime_utils()
    client_runtime_path = plugin_dir / 'client_runtime.cl.jac';
    if client_runtime_path.exists() {
        (runtime_js, _) = _compile_to_js(client_runtime_path);
        if runtime_js {
            (test_output_dir / 'client_runtime.js').write_text(
                runtime_js, encoding='utf-8'
            );
            console.success('Compiled client runtime from client_runtime.cl.jac');
        } else {
            console.warning(
                'Failed to compile client_runtime.cl.jac, using minimal stub'
            );
            _write_runtime_stub(test_output_dir);
        }
    } else {
        console.warning('client_runtime.cl.jac not found, using minimal stub');
        _write_runtime_stub(test_output_dir);
    }

    # ── Step 3: Compile test files + dependencies ──────────────────────
    jac_runtime_import = 'import {__jacJsx, __jacSpawn} from "@jac/runtime";';
    compiled_files: list[str] = [];
    compiled_deps: set[str] = set();

    for test_file in cl_files {
        source_path = Path(test_file).resolve();
        console.info(f'\n\t\t* Compiling {source_path.name} *');

        (js_code, mod) = _compile_to_js(source_path);
        if not js_code {
            console.warning(f'No JS generated for {source_path.name}');
            continue;
        }

        # Add runtime import if needed
        if '__jacJsx' in js_code and jac_runtime_import not in js_code {
            js_code = jac_runtime_import + '\n' + js_code;
        }

        # Determine output filename from runner type
        test_name = source_path.stem;
        if test_name.endswith('.cl.test') {
            test_name = test_name[:-8];
        } elif test_name.endswith('.cl') {
            test_name = test_name[:-3];
        }

        has_e2e = 'E2eRunner' in js_code;
        output_filename = (
            f'{test_name}.e2e.test.js' if has_e2e else f'{test_name}.it.test.jsx'
        );

        # Rewrite @jac/ imports to relative paths
        js_code = js_code.replace(
            'from "@jac/test-runtime/it"', 'from "./runners/it.js"'
        );
        js_code = js_code.replace(
            'from "@jac/test-runtime/e2e"', 'from "./runners/e2e.js"'
        );
        js_code = js_code.replace('from "@jac/runtime"', 'from "./client_runtime.js"');

        # Rewrite local dep imports: "./.foo-bar.js" -> "./foo-bar.js"
        manifest = mod.gen.client_manifest if mod else None;
        if manifest and manifest.imports {
            for ik in manifest.imports.keys() {
                if ik.startswith('@jac/') {
                    continue;
                }
                dn = ik.lstrip('.');
                if dn != ik {
                    js_code = js_code.replace(f'from "./{ik}.js"', f'from "./{dn}.js"');
                }
            }
        }

        output_path = test_output_dir / output_filename;
        output_path.write_text(js_code, encoding='utf-8');
        compiled_files.append(str(output_path));
        console.success(f'  Compiled: {source_path.name} -> {output_filename}');

        # Recursively compile all dependencies
        _compile_deps_recursive(mod, source_path, compiled_deps, jac_runtime_import);
    }

    if not compiled_files {
        console.warning('No client test files compiled successfully.');
        return 0;
    }

    # ── Step 4: Detect test types ──────────────────────────────────────
    it_files = [
        f
        for f in compiled_files
        if '.it.test.' in f
    ];
    e2e_files = [
        f
        for f in compiled_files
        if '.e2e.test.' in f
    ];

    # ── Step 5: Generate configs & install deps ────────────────────────
    # TypeScript config
    tsconfig = json.dumps(
        {
            "compilerOptions": {
                "jsx": "react-jsx",
                "module": "esnext",
                "moduleResolution": "bundler",
                "paths": {
                    "@jac/runtime": ["./client_runtime.js"],
                    "@jac/test-runtime/*": ["./runners/*"]
                }
            }
        },
        indent=2
    );
    (test_output_dir / 'tsconfig.json').write_text(tsconfig, encoding='utf-8');

    # Package dependencies — includes full runtime deps
    deps: dict = {};
    if it_files {
        # React + Testing Library
        deps["react"] = "^19.0.0";
        deps["react-dom"] = "^19.0.0";
        deps["@testing-library/react"] = ">=14.0.0";
        deps["@testing-library/jest-dom"] = ">=6.0.0";
        deps["@testing-library/user-event"] = ">=14.0.0";
        deps["@happy-dom/global-registrator"] = ">=15.0.0";
        deps["happy-dom"] = ">=15.0.0";
        # Client runtime deps (needed by compiled client_runtime.js)
        deps["react-router-dom"] = ">=6.0.0";
        deps["react-error-boundary"] = ">=4.0.0";
        deps["react-hook-form"] = ">=7.0.0";
        deps["@hookform/resolvers"] = ">=3.0.0";
        deps["zod"] = ">=3.0.0";
    }
    if e2e_files {
        deps["@playwright/test"] = ">=1.40.0";
    }

    package_json = json.dumps(
        {
            "name": "jac-test-output",
            "type": "module",
            "private": True,
            "dependencies": deps
        },
        indent=2
    );
    pkg_path = test_output_dir / 'package.json';
    old_pkg = pkg_path.read_text(encoding='utf-8') if pkg_path.exists() else '';
    pkg_path.write_text(package_json, encoding='utf-8');

    # Bun test config (component tests)
    if it_files {
        (test_output_dir / 'bunfig.toml').write_text(
            '[test]\npreload = ["./setup.ts"]', encoding='utf-8'
        );
        (test_output_dir / 'setup.ts').write_text(
            'import { GlobalRegistrator } from "@happy-dom/global-registrator";\n'
            'GlobalRegistrator.register();\n'
            'import "@testing-library/jest-dom";',
            encoding='utf-8'
        );
    }

    # Playwright config (E2E tests)
    if e2e_files {
        # Resolve the entry point for jac start from project config
        start_entry = '';
        try {
            import from jaclang.project.config { get_config }
            config = get_config(start_path=Path(base_dir));
            if config {
                start_entry = config.project.entry_point;
            }
        } except Exception { }
        if not start_entry {
            start_entry = 'main.jac';
        }
        # Store for use during test execution
        _e2e_project_dir = str(Path(base_dir).resolve());
        _e2e_start_entry = start_entry;
        pw_config = (
            'import { defineConfig } from "@playwright/test";\n'
            'export default defineConfig({\n'
            '  use: { baseURL: "http://localhost:8000" },\n'
            '  testDir: ".",\n'
            '  testMatch: "*.e2e.test.js",\n'
            '});\n'
        );
        (test_output_dir / 'playwright.config.js').write_text(
            pw_config, encoding='utf-8'
        );
    }

    # Install dependencies
    needs_install = (
        not (test_output_dir / 'node_modules').exists() or package_json != old_pkg
    );
    if needs_install {
        console.info('Installing test dependencies...');
        subprocess.run(
            ['bun', 'install'], cwd=str(test_output_dir), capture_output=True
        );
    }

    # ── Step 6: Run tests ──────────────────────────────────────────────
    ret = 0;

    if it_files {
        console.info('\n\t\t* Running component tests (bun test) *');
        result = subprocess.run(['bun', 'test'] + it_files, cwd=str(test_output_dir));
        ret += result.returncode;
    }

    if e2e_files {
        console.info('\n\t\t* Running E2E tests (playwright) *');
        import time;
        import tomllib;
        # Ensure playwright browsers are installed
        subprocess.run(
            ['npx', 'playwright', 'install', '--with-deps', 'chromium'],
            cwd=str(test_output_dir),
            capture_output=True
        );
        # Auto-detect base_route_app if not configured in jac.toml
        # The server needs this to serve the SPA for client-side routing
        project_dir = Path(_e2e_project_dir);
        jac_toml_path = project_dir / 'jac.toml';
        toml_backup: str | None = None;
        if jac_toml_path.exists() {
            toml_content = jac_toml_path.read_text(encoding='utf-8');
            toml_data = tomllib.loads(toml_content);
            has_base_route = bool(toml_data.get('serve', {}).get('base_route_app', ''));
            if not has_base_route {
                # Auto-detect from the entry module's client exports
                app_func = '';
                entry_path = project_dir / _e2e_start_entry;
                # Try the .cl variant (client module) which has client exports
                cl_variant = entry_path.with_suffix('')
                    if str(entry_path).endswith('.jac')
                    else entry_path;
                cl_path = Path(str(cl_variant) + '.cl.jac')
                    if not str(cl_variant).endswith('.cl')
                    else Path(str(cl_variant) + '.jac');
                # Check both the entry module and its .cl variant
                for check_path in [cl_path, entry_path] {
                    if check_path.exists() {
                        check_key = str(check_path.resolve());
                        check_mod = Jac.program.mod.hub.get(check_key);
                        if not check_mod {
                            # Compile it to populate the hub
                            (_, check_mod) = _compile_to_js(check_path);
                        }
                        if check_mod and check_mod.gen.client_manifest {
                            exports = check_mod.gen.client_manifest.exports;
                            if exports {
                                # Prefer function ending with _app or named 'app'
                                for exp in exports {
                                    if exp == 'app' or exp.endswith('_app') {
                                        app_func = exp;
                                        break;
                                    }
                                }
                                if not app_func {
                                    app_func = exports[0];
                                }
                                break;
                            }
                        }
                    }
                }
                if not app_func {
                    app_func = 'app';
                }
                console.info(
                    f'  Auto-detected base_route_app = "{app_func}" for SPA serving'
                );
                # Temporarily add [serve] config for the server
                toml_backup = toml_content;
                if '[serve]' in toml_content {
                    toml_content = toml_content.replace(
                        '[serve]', f'[serve]\nbase_route_app = "{app_func}"'
                    );
                } else {
                    toml_content += f'\n[serve]\nbase_route_app = "{app_func}"\n';
                }
                jac_toml_path.write_text(toml_content, encoding='utf-8');
            }
        }
        # Start jac server for E2E tests
        start_file = project_dir / _e2e_start_entry;
        console.info(f'  Starting server: jac start {start_file}');
        server_proc = subprocess.Popen(
            ['jac', 'start', str(start_file)],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True
        );
        # Wait for server to be ready (look for "Server ready" in output)
        server_ready = False;
        try {
            import selectors;
            sel = selectors.DefaultSelector();
            sel.register(server_proc.stdout, selectors.EVENT_READ);
            deadline = time.time() + 60;
            while time.time() < deadline {
                events = sel.select(timeout=1);
                for (key, _) in events {
                    line = key.fileobj.readline();
                    if line {
                        if 'Server ready' in line or 'ready' in line.lower() {
                            server_ready = True;
                        }
                    }
                }
                if server_ready {
                    break;
                }
                if server_proc.poll() is not None {
                    console.error('  Server process exited unexpectedly');
                    break;
                }
            }
            sel.close();
        } except Exception as e {
            console.warning(f'  Server readiness check error: {e}');
            # Fallback: just wait a bit
            time.sleep(5);
            server_ready = server_proc.poll() is None;
        }
        if not server_ready {
            console.error('  Server failed to start within timeout');
            if server_proc.poll() is None {
                server_proc.terminate();
            }
            ret += 1;
        } else {
            console.success('  Server started');
            try {
                result = subprocess.run(
                    [
                        'npx',
                        'playwright',
                        'test',
                        '--config',
                        'playwright.config.js'
                    ] + e2e_files,
                    cwd=str(test_output_dir)
                );
                ret += result.returncode;
            } finally {
                # Stop the server
                console.info('  Stopping server...');
                server_proc.terminate();
                try {
                    server_proc.wait(timeout=10);
                } except subprocess.TimeoutExpired {
                    server_proc.kill();
                }
            }
        }
        # Restore original jac.toml if we modified it
        if toml_backup is not None {
            jac_toml_path.write_text(toml_backup, encoding='utf-8');
        }
    }

    return ret;
}

# Fallback stub for when client_runtime.cl.jac compilation fails
def _write_runtime_stub(test_output_dir: any) -> None {
    import from pathlib { Path }
    stub = (
        'import React from "react";\n'
        'export function __jacJsx(tag, props, children) {\n'
        '  props = props || {};\n'
        '  return React.createElement(tag, props, ...(children || []));\n'
        '}\n'
        'export async function __jacSpawn() { return null; }\n'
        'export async function __jacCallFunction() { return null; }\n'
    );
    Path(test_output_dir / 'client_runtime.js').write_text(stub, encoding='utf-8');
}
