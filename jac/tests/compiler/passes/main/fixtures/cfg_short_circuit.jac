can test_short_circuit(x: int) {
    # 1. Simple AND
    if x > 0 and x < 10 {
        print("case1");
    }
    # 2. Simple OR
    if x > 0 or x < -5 {
        print("case2");
    }
    # 3. AND with else
    if x > 0 and x < 10 {
        print("case3a");
    } else {
        print("case3b");
    }
    # 4. OR with else
    if x > 0 or x < -5 {
        print("case4a");
    } else {
        print("case4b");
    }
    # 5. Nested: (A and B) or C
    if (x > 0 and x < 10) or x == -1 {
        print("case5");
    } else {
        print("case5b");
    }
    # 6. A and (B or C)
    if x > 0 and (x < 5 or x > 8) {
        print("case6");
    } else {
        print("case6b");
    }
    # 7. (A and B) or (C and D)
    if (x > 0 and x < 10) or (x > 20 and x < 30) {
        print("case7");
    } else {
        print("case7b");
    }
    # 8. Three-way AND chain with nested OR at end
    if x > 0 and x < 100 and (x < 10 or x > 90) {
        print("case8");
    } else {
        print("case8b");
    }
    # 9. elif with AND
    if x > 0 and x < 10 {
        print("case9a");
    } elif x > 20 or x < -5 {
        print("case9b");
    } elif (x > 50 and x < 60) or x == 100 {
        print("case9c");
    } else {
        print("case9d");
    }
    # 10. while with AND
    while x > 0 and x < 10 {
        print(x);
        x = x + 1;
    }
    # 11. while with OR
    while x > 100 or x < -50 {
        print(x);
        x = x - 1;
    }
}

with entry {
    test_short_circuit(5);
}
