# Essential Jac Pitfalls (Top 15)

Condensed reference for AI models. Each shows WRONG vs RIGHT. For full guide, use `get_resource("jac://guide/pitfalls")`.

## 1. Semicolons required on ALL statements

```
WRONG: x = 5
RIGHT: x = 5;
```

## 2. Braces for blocks, not indentation

```
WRONG: if x > 5:
           print(x)
RIGHT: if x > 5 { print(x); }
```

## 3. Import syntax

```
WRONG: from os import path
RIGHT: import from os { path }
```

## 4. `obj` not `class`, `has` not `self.x`

```jac
obj Foo {
    has x: int = 5;
    has name: str = "";
}
```

## 5. `def` for methods, `can` ONLY with `with` clause for walker entry/exit

```jac
obj Foo {
    has x: int = 0;
    def my_method(val: int) -> int { return val + 1; }
}
walker MyWalker {
    can process with MyNode entry { visit [-->]; }
}
```

`self` is implicit - do NOT put it in parameter list, but use it in the body.

## 6. Event handler lambdas REQUIRE type annotations

```
WRONG: <input onChange={lambda e { name = e.target.value; }} />
RIGHT: <input onChange={lambda e: any -> None { name = e.target.value; }} />
```

No-arg: `lambda -> None { handle_click(); }`

## 7. Client components go in `cl {}` blocks, use `has` for state (NOT useState)

```jac
cl {
    def:pub Counter() -> JsxElement {
        has count: int = 0;
        return <button onClick={lambda -> None { count = count + 1; }}>{count}</button>;
    }
}
```

## 8. Immutable updates for lists/dicts (mutation won't re-render)

```
WRONG: items.append(x);           # no re-render
RIGHT: items = items + [x];       # new reference triggers re-render
WRONG: items.pop(0);
RIGHT: items = items[1:];
```

## 9. `className` not `class` in JSX

```
WRONG: <div class="box">
RIGHT: <div className="box">
```

## 10. List rendering uses comprehensions, not .map()

```
WRONG: {items.map(i => <Item key={i.id} />)}
RIGHT: {[<Item key={item.id} /> for item in items]}
```

## 11. `sv import` for server code in client, `root spawn` to call walkers

```jac
sv import from ...main { get_tasks }

cl {
    def:pub TaskList() -> JsxElement {
        has tasks: list = [];
        async can with entry {
            result = root spawn get_tasks();
            if result.reports and result.reports.length > 0 {
                tasks = result.reports[0];
            }
        }
        return <ul>{[<li key={t.id}>{t.title}</li> for t in tasks]}</ul>;
    }
}
```

## 12. Walker results are in `result.reports[0]`, NOT `result.data`

```
WRONG: tasks = result.data;
WRONG: tasks = result;
RIGHT: tasks = result.reports[0];
```

## 13. `walker:pub` / `walker:priv` for HTTP endpoints

```jac
walker:pub get_tasks {
    can fetch with Root entry { report [-->][?:Task]; }
}
walker:priv create_task {
    has title: str;    # = request body
    can create with Root entry {
        new_task = here ++> Task(title=self.title);
        report new_task; # = response body
    }
}
```

`:priv` gives automatic per-user data isolation. No user ID filtering needed.

## 14. Auth from `@jac/runtime`, not manual fetch

```jac
cl import from "@jac/runtime" { jacLogin, jacSignup, jacLogout, jacIsLoggedIn, useNavigate }
# jacLogin(user, pass) -> bool
# jacSignup(user, pass) -> dict with "success" key
```

## 15. Use `root` (bare) in client code, NOT `root()`

```
WRONG: root() spawn my_walker();   # runtime error in client
RIGHT: root spawn my_walker();
```
