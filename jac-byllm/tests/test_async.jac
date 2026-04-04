"""Async support tests for byllm."""
import asyncio;
import types;

import from byllm.lib { Model, MockToolCall, StreamEvent }
import from byllm.mtir { MTRuntime }
import from byllm.types { Tool, ToolCall, Message, MessageRole, CompletionResult }

"""Build a minimal MTRuntime for testing (no tools)."""
def make_mt(stream: bool = False, call_params: dict = {}) -> MTRuntime {
    return MTRuntime(
        messages=[
            Message(role=MessageRole.SYSTEM, content="Test."),
            Message(role=MessageRole.USER, content="Input."),
        ],
        resp_type=str,
        stream=stream,
        tools=[],
        call_params=call_params,
        mtir=None  # type: ignore[arg-type]
    );
}

"""Build MTRuntime with tools (includes finish_tool as required by schema)."""
def make_mt_with_tools(
    tool_fns: list,
    stream: bool = False,
    call_params: dict = {}
) -> MTRuntime {
    tools = [Tool(fn) for fn in tool_fns];
    tools.append(Tool.make_finish_tool(str));
    return MTRuntime(
        messages=[
            Message(role=MessageRole.SYSTEM, content="Test."),
            Message(role=MessageRole.USER, content="Input."),
        ],
        resp_type=str,
        stream=stream,
        tools=tools,
        call_params=call_params,
        mtir=None  # type: ignore[arg-type]
    );
}

# --- ToolCall.acall ---

test "acall offloads sync tool to thread" {
    def add(a: int, b: int) -> int {
        return a + b;
    }
    tc = ToolCall(call_id="c1", tool=Tool(add), args={"a": 3, "b": 4});
    async def run() {
        return await tc.acall();
    }
    result = asyncio.run(run());
    assert result.content == "7";
}

test "acall awaits async tool directly" {
    async def multiply(x: int, y: int) -> int {
        await asyncio.sleep(0);
        return x * y;
    }
    tc = ToolCall(call_id="c2", tool=Tool(multiply), args={"x": 5, "y": 6});
    async def run() {
        return await tc.acall();
    }
    result = asyncio.run(run());
    assert result.content == "30";
}

# --- ainvoke plain string (no tools) ---

test "ainvoke returns string without tools" {
    model = Model(model_name="mockllm", config={"outputs": ["async answer"]});
    async def run() {
        return await model.ainvoke(make_mt());
    }
    assert asyncio.run(run()) == "async answer";
}

# --- ainvoke with tools ---

def get_weather(city: str) -> str {
    return f"Sunny in {city}";
}

test "ainvoke executes tool calls" {
    model = Model(
        model_name="mockllm",
        config={
            "outputs": [
                MockToolCall(tool=get_weather, args={"city": "Tokyo"}),
                "Sunny in Tokyo.",
            ]
        }
    );
    mt = make_mt_with_tools([get_weather]);
    async def run() {
        return await model.ainvoke(mt);
    }
    result = asyncio.run(run());
    assert "Sunny" in str(result) or "Tokyo" in str(result);
}

# --- ainvoke max_react_iterations ---

def noop_tool() -> str {
    return "noop";
}

test "ainvoke respects max_react_iterations" {
    model = Model(
        model_name="mockllm",
        config={
            "outputs": [
                MockToolCall(tool=noop_tool, args={}),
                MockToolCall(tool=noop_tool, args={}),
                MockToolCall(tool=noop_tool, args={}),
                "forced answer",
            ]
        }
    );
    mt = make_mt_with_tools(
        [noop_tool],
        call_params={"max_react_iterations": 2}
    );
    async def run() {
        return await model.ainvoke(mt);
    }
    result = asyncio.run(run());
    assert result is not None;
}

# --- ainvoke streaming (no tools) ---

test "ainvoke streaming returns async generator" {
    model = Model(model_name="mockllm", config={"outputs": ["streamed"]});
    mt = make_mt(stream=True);
    async def run() {
        gen = await model.ainvoke(mt);
        chunks = [];
        async for chunk in gen {
            chunks.append(chunk);
        }
        return "".join(chunks);
    }
    assert asyncio.run(run()) == "streamed";
}

# --- _ainvoke_streaming with logging + tools ---

def search_tool(query: str) -> str {
    return f"Found: {query}";
}

test "ainvoke streaming with logging yields events" {
    model = Model(
        model_name="mockllm",
        config={
            "outputs": [
                MockToolCall(tool=search_tool, args={"query": "jac"}),
                "Answer about jac.",
            ]
        }
    );
    mt = make_mt_with_tools(
        [search_tool],
        stream=True,
        call_params={"logging": True}
    );
    async def run() {
        gen = await model.ainvoke(mt);
        events = [];
        async for event in gen {
            events.append(event);
        }
        return events;
    }
    events = asyncio.run(run());
    etypes = [e.event_type for e in events];
    assert "tool_call" in etypes;
    assert "tool_result" in etypes;
    assert "chunk" in etypes;
}

# --- Shared helpers ---

test "prepare_call_params returns model params" {
    model = Model(model_name="mockllm", config={"outputs": []});
    params = model._prepare_call_params(make_mt());
    assert params["model"] == "mockllm";
}

test "parse_response extracts tool calls" {
    def dummy() -> str {
        return "x";
    }
    model = Model(model_name="mockllm", config={"outputs": []});
    mt = make_mt_with_tools([dummy]);
    fake_fn = types.SimpleNamespace(name="dummy", arguments="{}");
    fake_tc = types.SimpleNamespace(id="call_1", function=fake_fn);
    response = {
        "choices": [{"message": {"content": "thinking", "tool_calls": [fake_tc]}}],
        "usage": {"total_tokens": 42}
    };
    result = model._parse_response(response, mt);
    assert len(result.tool_calls) == 1;
    assert result.tool_calls[0].tool.get_name() == "dummy";
    assert result.usage["total_tokens"] == 42;
}

test "aggregate_usage sums and resets" {
    model = Model(model_name="mockllm", config={"outputs": []});
    model._usage_history = [
        {"prompt_tokens": 10, "total_tokens": 30},
        {"prompt_tokens": 5, "total_tokens": 20},
    ];
    event = model._aggregate_usage();
    assert event is not None;
    assert event.data["total"]["total_tokens"] == 50;
    assert model._usage_history == [];
}

test "aggregate_usage returns None when empty" {
    model = Model(model_name="mockllm", config={"outputs": []});
    model._usage_history = [];
    assert model._aggregate_usage() is None;
}

# --- Telemetry ---

test "ainvoke streaming result is async generator" {
    import from typing { AsyncGenerator }
    model = Model(model_name="mockllm", config={"outputs": ["s"]});
    mt = make_mt(stream=True);
    async def run() {
        return await model.ainvoke(mt);
    }
    result = asyncio.run(run());
    assert isinstance(result, AsyncGenerator);
}
