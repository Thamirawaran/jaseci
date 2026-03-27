# Jac & Jaseci - Knowledge Map

## What is Jac?

Jac is a full-stack language that compiles to Python bytecode (server), JavaScript (client), and native
binaries - from a single file. It extends Python with 3 paradigms beyond traditional languages:

  1. Codespaces (sv/cl/na)  - target where code runs: server, browser, or native binary
  2. Object-Spatial Programming (OSP) - graph-native data model with built-in multi-user persistence
  3. Meaning-Typed Programming (MTP) - AI functions via `by llm` with compiler-extracted semantics

## What is Jaseci?

The runtime stack for Jac: jaclang (compiler + runtime + basic client + basic http server), jac-client (React frontend),
jac-scale (deployment + scaling). They handle DB schema, API routing, HTTP, auth, and frontend
generation automatically - you write Jac, Jaseci handles the infrastructure.

---

## MANDATORY - Before Writing Any Jac Code

You MUST call the get_resource tool for BOTH of these URIs before writing any Jac code.
Do not skip this. Do not rely on training knowledge. Jac syntax differs from Python and
your training data is likely outdated.

  CALL: get_resource(uri="jac://guide/pitfalls")  - AI specific mistakes: WRONG vs RIGHT pairs
  CALL: get_resource(uri="jac://guide/patterns")  - complete working idiomatic examples

---

## Knowledge Index

Each section below describes a topic and lists the URIs you MUST call get_resource with
when that topic is relevant to your task. Only fetch what you need - do not fetch all at once.

### [A] Language Syntax - Jac is NOT Python

Semicolons on ALL statements. Braces {} for blocks, not indentation. `has` for instance fields
(not self.x). `obj` preferred over `class`. `def` for regular methods, `can` ONLY for
event-driven abilities. `import from X { Y }` syntax (no import:py prefix) and `import X;` is module level import. `with entry {}`
as main block. `glob` for module-level variables. `self` is implicit in method signatures.

  CALL get_resource when: writing any code, debugging a syntax/type error, unsure about syntax
  CALL: get_resource(uri="jac://guide/pitfalls")       - WRONG vs RIGHT for every AI mistake
  CALL: get_resource(uri="jac://docs/cheatsheet")      - complete syntax lookup while coding
  CALL: get_resource(uri="jac://docs/foundation")      - full language specification

### [B] Object-Spatial Programming (OSP) - Core Paradigm

Data lives in a graph anchored to `root`. Walkers traverse nodes as mobile agents. Replaces
ORM + database + API boilerplate entirely. Per-user data isolation built-in via `root`.
Keywords: node, edge, walker, visit, report, here, visitor, disengage, root, spawn, ++>, [-->], [?:Type]

  CALL get_resource when: storing/querying data, building endpoints, graph traversal, AI agents
  CALL: get_resource(uri="jac://docs/osp")              - nodes, edges, walkers, CRUD patterns
  CALL: get_resource(uri="jac://docs/walker-responses") - walker response and reporting patterns
  CALL: get_resource(uri="jac://examples/data_spatial") - canonical working OSP example

### [C] Data Persistence & Multi-User Auth

Nodes connected to `root` auto-persist (no DB, no SQL, no ORM). Each user gets their own
isolated root automatically. `walker:priv` enforces auth on the caller's root.
`walker:pub` = public/shared. `def:pub` = simple public function endpoint.

  CALL get_resource when: building user-specific data, adding auth, designing persistence
  CALL: get_resource(uri="jac://docs/osp")              - persistence under graph construction section

### [D] AI Integration (byLLM / MTP)

`def fn(x: T) -> R by llm;` - delegates function body to LLM using name/types as the prompt.
`sem fn = "..."` adds explicit semantic hints. Supports: structured output (obj/enum enforced),
tool calling (ReAct loop), streaming, multimodal.

  CALL get_resource when: using `by llm`, building AI functions, agentic patterns
  CALL: get_resource(uri="jac://docs/byllm")                - full byLLM + MTP reference
  CALL: get_resource(uri="jac://docs/tutorial-ai-agentic")  - agentic AI with tool calling

### [E] Full-Stack Development (Codespaces)

Single .jac file = complete full-stack app. `sv {}` = server code. `cl {}` = client code
(React/JSX). `.cl.jac` files default to client mode (no `cl {}` wrapper needed).

**Client components**: `cl def:pub Name(prop: str) -> JsxElement { ... }`
**Reactive state**: `has count: int = 0;` = React useState. Assignment `count = count + 1;`
triggers re-render. NEVER mutate directly (`items.append(x)` won't re-render - use
`items = items + [x];`).
**Effects**: `async can with entry { ... }` = useEffect on mount. `can with exit { ... }` = cleanup.
**Events**: `onClick={lambda e: Any -> None { name = e.target.value; }}` - type annotation required.
**Lists**: `{[<Item key={item._jac_id} item={item}/> for item in items]}` - use `_jac_id` for keys.

**Calling server from client** (critical pattern):
  `sv import from ..main { my_walker }` - import server walker into client code
  `response = root spawn my_walker(field=value);` - spawns walker via HTTP automatically
  `data = response.reports[0][0];` - access walker report results

**Client imports**: `cl import from react { useState }`,
  `cl import from "@jac/runtime" { Link, useNavigate, JacForm, JacSchema }`
**Auth built-ins**: `jacLogin(user, pass)`, `jacSignup(user, pass)`, `jacLogout()`, `jacIsLoggedIn()`
**Context**: `glob:pub MyCtx = createContext(None);` - module-level context
**Dict spread**: `{** dict1, ** dict2}` (NOT `{...dict1}`)
**Routing**: file-based via `pages/` directory, or manual `<Router><Routes><Route path="/" .../>`.

  CALL get_resource when: building UI, client components, full-stack features
  CALL: get_resource(uri="jac://docs/jac-client")                      - full client reference
  CALL: get_resource(uri="jac://docs/tutorial-fullstack-setup")        - project scaffolding
  CALL: get_resource(uri="jac://docs/tutorial-fullstack-components")   - components, props, JSX
  CALL: get_resource(uri="jac://docs/tutorial-fullstack-state")        - state, effects, context
  CALL: get_resource(uri="jac://docs/tutorial-fullstack-backend")      - walker calls from client
  CALL: get_resource(uri="jac://docs/tutorial-fullstack-auth")         - login, signup, protected routes
  CALL: get_resource(uri="jac://docs/tutorial-fullstack-routing")      - file-based & manual routing
  CALL: get_resource(uri="jac://docs/jac-vs-traditional")              - side-by-side vs Python+React

### [F] Design Patterns

CRUD walkers, search walkers, aggregation, hierarchical traversal, walker vs def:pub decision,
declaration/implementation separation (.jac + .impl.jac split).

  CALL get_resource when: designing app structure, choosing patterns, studying examples
  CALL: get_resource(uri="jac://guide/patterns")         - idiomatic patterns with working code
  CALL: get_resource(uri="jac://examples/littleX")       - full-stack social app (real-world OSP)
  CALL: get_resource(uri="jac://examples/guess_game")    - progressive: plain obj -> walker -> LLM

### [G] Code Organization & Project Structure

.jac (server default), .impl.jac (implementations), .cl.jac (client), .sv.jac (server-explicit),
.test.jac (tests). impl/ subdirectory for method bodies. Declaration/impl separation pattern.

  CALL get_resource when: setting up a project, organising files, splitting declaration from impl
  CALL: get_resource(uri="jac://docs/code-organization") - project structure and file conventions

### [H] API Server & Deployment

`jac start app.jac` auto-exposes `walker:pub` and `def:pub` as HTTP endpoints. Walker `has`
fields = request body. `report` values = response body. `@restspec` customises method/path.

  CALL get_resource when: exposing endpoints, deploying, configuring production
  CALL: get_resource(uri="jac://docs/jac-scale")                  - deployment and scaling
  CALL: get_resource(uri="jac://docs/tutorial-production-local")  - local API server setup

### [I] Testing

`test "name" { ... }` blocks inline or in .test.jac files. Spawn walkers and assert on `.reports`.
Run with `jac test`.

  CALL get_resource when: writing or debugging tests
  CALL: get_resource(uri="jac://docs/testing")           - test framework reference

### [J] Python Integration

Import Python packages with `import from os { path }` (same syntax, no import:py prefix).
Inline Python: `::py:: ... ::py::`. Use `class` only for Python-specific features (metaclasses,
decorators, @property). Prefer `obj` for everything else.

  CALL get_resource when: using Python libraries, mixing Python and Jac, library mode
  CALL: get_resource(uri="jac://docs/python-integration") - Python interop reference

### [K] Official Plugins - Check Before Building

Jac has 4 official plugins. Before building any feature from scratch, check if a plugin already
covers it. Plugins live in the main Jaseci repo (jac/ folder and jac-plugins/ folder).

  jac-byllm   - AI integration: `by llm`, `sem`, structured output, tool calling, streaming.
                Already used whenever you write `def fn() -> T by llm;`
                CALL: get_resource(uri="jac://docs/byllm")

  jac-client  - Full-stack frontend: React/JSX client components, routing, auth, state.
                Already used whenever you write `cl { }` blocks.
                CALL: get_resource(uri="jac://docs/jac-client")

  jac-scale   - Production deployment: REST API server, scaling, Kubernetes.
                Already used when you run `jac start`.
                CALL: get_resource(uri="jac://docs/jac-scale")

  jac-shadcn  - UI component library for Jac (shadcn/ui components, ready to use in cl blocks).
                Use this before building any UI from scratch - components already exist.
                CALL: get_resource(uri="jac://examples/plugins") - see plugin usage patterns

  CALL get_resource when: building UI, adding AI, deploying, or before implementing any feature
  that sounds like it could already be a plugin.

---

## Quick Task -> Resource Lookup

  Task                                    | You MUST call get_resource with
  ----------------------------------------|-------------------------------------------
  Write ANY Jac code                      | jac://guide/pitfalls  +  jac://guide/patterns
  Store / retrieve user data              | jac://docs/osp
  Build a REST endpoint                   | jac://docs/osp
  Call an LLM / AI function               | jac://docs/byllm
  Build UI components                     | jac://docs/tutorial-fullstack-components
  Build a full-stack app                  | jac://docs/jac-client  +  jac://docs/tutorial-fullstack-setup
  Call walkers from client UI             | jac://docs/tutorial-fullstack-backend
  Add login / signup / auth               | jac://docs/tutorial-fullstack-auth
  Manage client state / effects           | jac://docs/tutorial-fullstack-state
  Add routing / pages                     | jac://docs/tutorial-fullstack-routing
  Look up syntax while coding             | jac://docs/cheatsheet
  Debug a parse or type error             | jac://guide/pitfalls  +  jac://docs/cheatsheet
  Compare Jac to Python/React             | jac://docs/jac-vs-traditional
  Deploy to production                    | jac://docs/jac-scale
  Write tests                             | jac://docs/testing
  See a working example                   | jac://examples/data_spatial  or  jac://examples/littleX
  Understand project file layout          | jac://docs/code-organization
  Discover available plugins              | jac://examples/plugins  +  list_templates tool
