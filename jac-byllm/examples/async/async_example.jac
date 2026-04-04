"""Async byllm example — demonstrates ainvoke, async streaming, and concurrent LLM calls."""
import asyncio;
import from byllm.lib { Model, MockToolCall }
import from byllm.types { Message, MessageRole }
import from byllm.mtir { MTRuntime }

def get_weather(city: str) -> str {
    return f"22C, sunny in {city}";
}

def make_mt(
    prompt: str,
    tools: list = [],
    stream: bool = False,
    call_params: dict = {}
) -> MTRuntime {
    return MTRuntime(
        messages=[
            Message(role=MessageRole.SYSTEM, content="You are helpful."),
            Message(role=MessageRole.USER, content=prompt),
        ],
        resp_type=str,
        stream=stream,
        tools=tools,
        call_params=call_params,
        mtir=None  # type: ignore[arg-type]
    );
}

# --- 1. Basic ainvoke ---

async def demo_basic() {
    model = Model(model_name="mockllm", config={"outputs": ["Hello from async!"]});
    result = await model.ainvoke(mt_run=make_mt("Say hello."));
    print(f"[basic] {result}");
}

# --- 2. Async tool calling ---

async def demo_tools() {
    import from byllm.types { Tool }
    model = Model(
        model_name="mockllm",
        config={
            "outputs": [
                MockToolCall(tool=get_weather, args={"city": "Tokyo"}),
                "The weather in Tokyo is 22C and sunny.",
            ]
        }
    );
    tools = [Tool(get_weather)];
    tools.append(Tool.make_finish_tool(str));
    result = await model.ainvoke(mt_run=make_mt("Weather in Tokyo?", tools=tools));
    print(f"[tools] {result}");
}

# --- 3. Concurrent calls with asyncio.gather ---

async def ask(model: Model, prompt: str) -> object {
    return await model.ainvoke(mt_run=make_mt(prompt));
}

async def demo_concurrent() {
    m1 = Model(model_name="mockllm", config={"outputs": ["Answer 1"]});
    m2 = Model(model_name="mockllm", config={"outputs": ["Answer 2"]});
    m3 = Model(model_name="mockllm", config={"outputs": ["Answer 3"]});
    results = await asyncio.gather(
        ask(m1, "What is 2+2?"),
        ask(m2, "Capital of France?"),
        ask(m3, "Meaning of life?")
    );
    print(f"[concurrent 1] {results[0]}");
    print(f"[concurrent 2] {results[1]}");
    print(f"[concurrent 3] {results[2]}");
}

# --- 4. Async streaming ---

async def demo_streaming() {
    model = Model(model_name="mockllm", config={"outputs": ["Streamed token by token!"]});
    gen = await model.ainvoke(mt_run=make_mt("Tell me a story.", stream=True));
    print("[stream] ", end="");
    async for chunk in gen {  # type: ignore[union-attr]
        print(chunk, end="", flush=True);
    }
    print();
}

async def main() {
    print("=== byllm async examples ===\n");
    await demo_basic();
    await demo_tools();
    await demo_concurrent();
    await demo_streaming();
    print("\nAll done — no threads blocked!");
}

with entry {
    asyncio.run(main());
}
