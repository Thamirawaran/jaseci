"""Tests for ElseIf chain type narrowing."""

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

obj Fish {
    has name: str;

    def swim -> str {
        return "splash";
    }
}

obj Bird {
    has name: str;

    def fly -> str {
        return "flap";
    }
}

# 1. Elif with early return — negative narrowing accumulates through chain
def test_elif_early_return(animal: Dog | Cat | Fish) -> str {
    if isinstance(animal, Dog) {
        return animal.bark();
    } elif isinstance(animal, Cat) {
        return animal.meow();
    }
    # After both early returns: animal is Fish
    f: Fish = animal;  # <-- Ok after narrowing (Fish)
    return f.swim();
}

# 2. Deep elif chain — 4-way branch with early returns
def test_deep_elif_chain(animal: Dog | Cat | Fish | Bird) -> str {
    if isinstance(animal, Dog) {
        return animal.bark();
    } elif isinstance(animal, Cat) {
        return animal.meow();
    } elif isinstance(animal, Fish) {
        return animal.swim();
    }
    # Only Bird remains
    b: Bird = animal;  # <-- Ok after narrowing (Bird)
    return b.fly();
}

# 3. Elif with else — negative narrowing in else block
def test_elif_else(animal: Dog | Cat | Fish) -> str {
    if isinstance(animal, Dog) {
        d: Dog = animal;  # <-- Ok after narrowing (Dog)
        return d.bark();
    } elif isinstance(animal, Cat) {
        c: Cat = animal;  # <-- Ok after narrowing (Cat)
        return c.meow();
    } else {
        f: Fish = animal;  # <-- Ok after narrowing (Fish)
        return f.swim();
    }
}

# 4. Elif with None narrowing
def test_elif_none(val: str | int | None) -> str {
    if val is None {
        return "none";
    } elif isinstance(val, str) {
        s: str = val;  # <-- Ok after narrowing (str)
        return s;
    }
    # val is int here
    result: int = val;  # <-- Ok after narrowing (int)
    return str(result);
}

# E1. Wrong type in elif negative narrowing
def test_error_elif_wrong_type(animal: Dog | Cat | Fish) -> str {
    if isinstance(animal, Dog) {
        return animal.bark();
    } elif isinstance(animal, Cat) {
        return animal.meow();
    }
    # animal is Fish here, NOT Dog
    d: Dog = animal;  # <-- Error: Fish cannot assign to Dog
    return d.bark();
}
