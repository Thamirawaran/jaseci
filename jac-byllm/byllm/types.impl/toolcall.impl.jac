#-------------------------------------------------------------------------------
# ToolCall Implementations
#-------------------------------------------------------------------------------
"""Execute the tool call and return a result message."""
impl ToolCall.__call__ -> ToolCallResultMsg {
    if self.args is not None {
        result = self.tool(**self.args);
    } else {
        raise ByLLMError("ToolCall.args is None, expected a dictionary");
    }
    return ToolCallResultMsg(
        content=str(result), tool_call_id=self.call_id, name=self.tool.get_name(),
    );
}

"""Execute the tool call asynchronously and return a result message.

Async tools are awaited directly. Sync tools are offloaded to a thread
via asyncio.to_thread() so they never block the event loop.
"""
impl ToolCall.acall -> ToolCallResultMsg {
    import asyncio;
    import inspect;
    if self.args is not None {
        if inspect.iscoroutinefunction(self.tool.func) {
            result = await self.tool(**self.args);
        } else {
            result = await asyncio.to_thread(self.tool.__call__, **self.args);
        }
    } else {
        raise ByLLMError("ToolCall.args is None, expected a dictionary");
    }
    return ToolCallResultMsg(
        content=str(result), tool_call_id=self.call_id, name=self.tool.get_name(),
    );
}

"""Return the string representation of the tool call."""
impl ToolCall.__str__ -> str {
    params = ", ".join(f"{k}={v}" for (k, v) in self.args.items());
    return f"{self.tool.get_name()}({params})";
}

"""Check if this is a call to the finish tool."""
impl ToolCall.is_finish_call -> bool {
    return self.tool.is_finish_tool();
}

"""Get the output from the finish tool call."""
impl ToolCall.get_output -> object {
    assert (self.is_finish_call()) , "This method should only be called for finish tools.";
    return self.tool(**self.args);
}

#-------------------------------------------------------------------------------
# MockToolCall Implementations
#-------------------------------------------------------------------------------
"""Convert the mock tool call to a real ToolCall for testing."""
impl MockToolCall.to_tool_call -> ToolCall {
    args_parsed = Tool(self.tool).parse_arguments(self.args);
    return ToolCall(
        call_id="",  # Call ID is not used in mock calls.
        tool=Tool(self.tool),
        args=args_parsed,
    );
}
