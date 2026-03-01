"""Tests for WhileStmt condition-based type narrowing."""

obj Dog {
    has name: str;

    def bark -> str {
        return "woof";
    }
}

obj Cat {
    has name: str;

    def meow -> str {
        return "meow";
    }
}

# 1. while isinstance narrowing — body sees narrowed type
def test_while_isinstance(animal: Dog | Cat) -> str {
    while isinstance(animal, Dog) {
        d: Dog = animal;  # <-- Ok after narrowing (Dog)
        return d.bark();
    }
    return "";
}

# 2. while is not None narrowing — body sees non-None type
def test_while_not_none(val: str | None) -> str {
    while val is not None {
        result: str = val;  # <-- Ok after narrowing (str)
        return result;
    }
    return "default";
}

# 3. while truthiness narrowing — body excludes None
def test_while_truthiness(val: int | None) -> int {
    while val {
        result: int = val;  # <-- Ok after narrowing (int)
        return result;
    }
    return 0;
}

# E1. Wrong type assignment inside while narrowed body
def test_error_while_wrong_type(animal: Dog | Cat) -> str {
    while isinstance(animal, Dog) {
        c: Cat = animal;  # <-- Error: Dog cannot assign to Cat
        return c.meow();
    }
    return "";
}
