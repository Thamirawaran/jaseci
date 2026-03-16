"""Component tests for SubmitButton."""

cl import from ."submit-button" { SubmitButton }

@ jactest.it test "renders a submit button with Sign Up text" {
    render(<SubmitButton/>);
    button = screen.getByText("Sign Up");
    expect(button).toBeInTheDocument();
    expect(button.tagName).toBe("BUTTON");
    expect(button.type).toBe("submit");
}

@ jactest.it test "button has correct styling" {
    render(<SubmitButton/>);
    button = screen.getByText("Sign Up");
    expect(button.style.backgroundColor).toBe("#1da1f2");
    expect(button.style.color).toBe("white");
    expect(button.style.borderRadius).toBe("4px");
    expect(button.style.cursor).toBe("pointer");
}

@ jactest.it test "button has full width" {
    render(<SubmitButton/>);
    button = screen.getByText("Sign Up");
    expect(button.style.width).toBe("100%");
}
