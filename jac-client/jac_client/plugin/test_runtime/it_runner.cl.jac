"""Test runner utility wrapping bun:test and @testing-library/react."""

import from "bun:test" { describe, it, expect, beforeEach, afterEach }
import from "@testing-library/react" {
    render,
    screen,
    fireEvent,
    waitFor,
    within,
    act,
    cleanup
}
import from "@testing-library/react" { renderHook }
import from "@testing-library/user-event" { default as userEvent }
import '@testing-library/jest-dom';

glob test_utils = {
         "render": render,
         "screen": screen,
         "expect": expect,
         "fireEvent": fireEvent,
         "waitFor": waitFor,
         "within": within,
         "act": act,
         "renderHook": renderHook,
         "userEvent": userEvent
     };

def call_cleanup -> None {
    cleanup();
}

with entry {
    afterEach(call_cleanup);
}

def:pub it_runner_run(name: str, fn: any) -> None {
    it(name, lambda -> None { fn(test_utils);});
}

def:pub it_runner_skip(name: str, fn: any) -> None {
    it.skip(name, lambda -> None { fn(test_utils);});
}

def:pub it_runner_todo(name: str) -> None {
    it.todo(name);
}

def:pub it_runner_only(name: str, fn: any) -> None {
    it.only(name, lambda -> None { fn(test_utils);});
}

glob:pub ItRunner = {
         "run": it_runner_run,
         "skip": it_runner_skip,
         "todo": it_runner_todo,
         "only": it_runner_only
     };
