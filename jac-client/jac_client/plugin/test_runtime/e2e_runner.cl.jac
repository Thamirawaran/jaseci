"""E2E test runner utility wrapping @playwright/test."""

import from "@playwright/test" { test, expect }

def:pub e2e_runner_run(name: str, fn: any) -> None {
    async def callback(args: any) -> None {
        await fn(
            {
                "page": args.page,
                "expect": expect,
                "browser": args.browser,
                "context": args.context
            }
        );
    }
    test(name, callback);
}

def:pub e2e_runner_skip(name: str, fn: any) -> None {
    async def callback(args: any) -> None {
        await fn(
            {
                "page": args.page,
                "expect": expect,
                "browser": args.browser,
                "context": args.context
            }
        );
    }
    test.skip(name, callback);
}

def:pub e2e_runner_todo(name: str) -> None {
    async def noop -> None {
        0;
    }
    test.fixme(name, noop);
}

def:pub e2e_runner_only(name: str, fn: any) -> None {
    async def callback(args: any) -> None {
        await fn(
            {
                "page": args.page,
                "expect": expect,
                "browser": args.browser,
                "context": args.context
            }
        );
    }
    test.only(name, callback);
}

glob:pub E2eRunner = {
         "run": e2e_runner_run,
         "skip": e2e_runner_skip,
         "todo": e2e_runner_todo,
         "only": e2e_runner_only
     };
