"""Tests for attribute assignment-based type narrowing.

Validates that after assigning to an object attribute (o.field = value),
the type checker narrows the attribute type via CFG backward walk.
"""

obj Container {
    has value: int | None = None;
}

def accept_int(x: int) -> int {
    return x;
}

# 1. Simple attribute assignment narrows union type.
#    c.value: int | None, after c.value = 42 → narrowed to int.
def test_attr_assignment_narrows(c: Container) -> int {
    c.value = 42;
    return accept_int(c.value);  # Ok
}

# 2. Attribute assignment inside a method via self.
obj MyObj {
    has data: str | None = None;

    def set_and_use -> str {
        self.data = "hello";
        result: str = self.data;  # Ok
        return result;
    }
}

# 3. Multiple sequential attribute assignments - last one wins.
def test_attr_reassignment(c: Container) -> int {
    c.value = None;
    c.value = 10;
    return accept_int(c.value);  # Ok - last assignment is int
}
