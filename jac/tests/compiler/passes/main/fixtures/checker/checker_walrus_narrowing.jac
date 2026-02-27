"""Tests for walrus operator (:=) type narrowing in conditions."""

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

def get_animal -> Dog | Cat {
    return Dog(name="Rex");
}

def get_optional -> str | None {
    return "hello";
}

# 1. isinstance with walrus — narrows walrus target
def test_walrus_isinstance(animal: Dog | Cat) -> str {
    if isinstance(x := animal, Dog) {
        d: Dog = x;  # <-- Ok after narrowing (Dog)
        return d.bark();
    }
    return "";
}

# 2. Walrus with is not None — narrows to non-None
def test_walrus_is_not_none -> str {
    if (val := get_optional()) is not None {
        result: str = val;  # <-- Ok after narrowing (str)
        return result;
    }
    return "default";
}

# E1. Wrong type in walrus isinstance
def test_error_walrus_isinstance(animal: Dog | Cat) -> str {
    if isinstance(x := animal, Dog) {
        c: Cat = x;  # <-- Error: Dog cannot assign to Cat
        return c.meow();
    }
    return "";
}
