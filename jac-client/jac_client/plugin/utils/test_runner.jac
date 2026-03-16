"""Client-side test runner for .cl.test.jac files.

Compiles test files and their dependencies to JavaScript using jac-client's
compilation infrastructure, sets up test environment, and runs tests via
bun test (component tests) or playwright (E2E tests).
"""

"""Run client-side tests (.cl.test.jac files).

Args:
    cl_files: List of absolute paths to .cl.test.jac files.
    base_dir: Base directory for the project (where .jac/ output goes).
    entry_point: Entry point file for jac start (used for E2E webServer config).

Returns:
    Exit code (0 = all pass).
"""
def run_client_tests(cl_files: list[str], base_dir: str, entry_point: str = "") -> int;
