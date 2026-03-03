"""CFG build pass tests – migrated from test_cfg_build_pass.py."""

import os;
import from pathlib { Path }
import jaclang;
import from jaclang.compiler.passes.main.cfg_build_pass { cfg_dot_from_file }

glob FIXTURES = os.path.join(
         str(Path(jaclang.__file__).parent.parent),
         "tests",
         "compiler",
         "passes",
         "main",
         "fixtures"
     );

test "cfg branches and loops" {
    dot = cfg_dot_from_file(file_name=os.path.join(FIXTURES, "cfg_gen.jac"));
    expected_dot = (
        "digraph G {\n" + '  0 [label="BB0\\nx = 5 ;\\ny = 3 ;\\nif x > 3", shape=box];\n' + '  1 [label="BB1\\nz = x + y ;", shape=box];\n' + '  2 [label="BB2\\nelif x == 0", shape=box];\n' + '  3 [label="BB3\\nz = y ;", shape=box];\n' + '  4 [label="BB4\\nz = x - y ;", shape=box];\n' + '  5 [label="BB5\\nfor i in range ( 0 , 10 )", shape=box];\n' + '  6 [label="BB6\\nz = z + 1 ;", shape=box];\n' + '  7 [label="BB7\\nwhile z < 10", shape=box];\n' + '  8 [label="BB8\\nz = z + 2 ;", shape=box];\n' + "  0 -> 1;\n" + "  0 -> 2;\n" + "  1 -> 5;\n" + "  2 -> 3;\n" + "  2 -> 4;\n" + "  3 -> 5;\n" + "  4 -> 5;\n" + "  5 -> 6;\n" + "  5 -> 7;\n" + "  6 -> 5;\n" + "  7 -> 8;\n" + "  8 -> 7;\n" + "}\n"
    );
    assert dot == expected_dot;
}

test "cfg abilities and objects" {
    dot = cfg_dot_from_file(file_name=os.path.join(FIXTURES, "cfg_ability_test.jac"));
    expected_dot = (
        "digraph G {\n" + '  0 [label="BB0\\nobj math_mod", shape=box];\n' + '  1 [label="BB1\\ncan divide( x : int , y : int ) -> int\\nif y == 0", shape=box];\n' + '  2 [label="BB2\\nreturn 0 ;", shape=box];\n' + '  3 [label="BB3\\nreturn x // y ;", shape=box];\n' + '  4 [label="BB4\\ncan multiply( x : int , y : int ) -> int\\nreturn x * y ;", shape=box];\n' + '  5 [label="BB5\\nx = 5 ;\\ny = 0 ;\\nmath = math_mod ( ) ;\\nz = math . divide ( x , y ) ;\\nprint ( z ) ;", shape=box];\n' + "  0 -> 1;\n" + "  0 -> 4;\n" + "  1 -> 2;\n" + "  1 -> 3;\n" + "}\n"
    );
    assert dot == expected_dot;
}

test "cfg ability with has" {
    dot = cfg_dot_from_file(file_name=os.path.join(FIXTURES, "cfg_has_var.jac"));
    expected_dot = (
        "digraph G {\n" + '  0 [label="BB0\\nobj Rock", shape=box];\n' + '  1 [label="BB1\\nhas pellets : list ;", shape=box];\n' + '  2 [label="BB2\\ncan count_pellets( ) -> int\\nreturn self . pellets . length ( ) ;", shape=box];\n' + '  3 [label="BB3\\nrock = Rock ( pellets = [ 1 , 2 , 3 ] ) ;\\nprint ( \\"Number of pellets: \\" + rock . count_pellets ( ) . to_string ( ) ) ;", shape=box];\n' + "  0 -> 1;\n" + "  0 -> 2;\n" + "}\n"
    );
    assert dot == expected_dot;
}

test "cfg if no else" {
    dot = cfg_dot_from_file(file_name=os.path.join(FIXTURES, "cfg_if_no_else.jac"));
    expected_dot = (
        "digraph G {\n" + '  0 [label="BB0\\ncan test_if_without_else( x : int )\\nif ( x > 0 )", shape=box];\n' + '  1 [label="BB1\\nprint ( \\"Positive\\" ) ;", shape=box];\n' + '  2 [label="BB2\\nprint ( \\"Done\\" ) ;", shape=box];\n' + '  3 [label="BB3\\ntest_if_without_else ( 5 ) ;\\ntest_if_without_else ( - 3 ) ;", shape=box];\n' + "  0 -> 1;\n" + "  0 -> 2;\n" + "  1 -> 2;\n" + "}\n"
    );
    assert dot == expected_dot;
}

test "cfg return stmt" {
    dot = cfg_dot_from_file(file_name=os.path.join(FIXTURES, "cfg_return.jac"));
    expected_dot = (
        "digraph G {\n" + '  0 [label="BB0\\ncan test_return_direct( )\\nprint ( \\"Before return\\" ) ;\\nreturn ;\\nprint ( \\"After return\\" ) ;", shape=box];\n' + '  1 [label="BB1\\ntest_return_direct ( ) ;", shape=box];\n' + "}\n"
    );
    assert dot == expected_dot;
}

test "cfg while loop with break continue and else" {
    dot = cfg_dot_from_file(file_name=os.path.join(FIXTURES, "cfg_while_stmt.jac"));
    expected_dot = (
        "digraph G {\n" + '  0 [label="BB0\\nx = 0 ;", shape=box];\n' + '  1 [label="BB1\\nwhile x < 5", shape=box];\n' + '  2 [label="BB2\\nx = x + 1 ;\\nif x == 2", shape=box];\n' + '  3 [label="BB3\\ncontinue ;", shape=box];\n' + '  4 [label="BB4\\nprint ( x ) ;\\nif x == 4", shape=box];\n' + '  5 [label="BB5\\nbreak ;", shape=box];\n' + '  6 [label="BB6\\nprint ( \\"done\\" ) ;", shape=box];\n' + "  0 -> 1;\n" + "  1 -> 2;\n" + "  1 -> 6;\n" + "  2 -> 3;\n" + "  2 -> 4;\n" + "  3 -> 1;\n" + "  4 -> 5;\n" + "  4 -> 1;\n" + "}\n"
    );
    assert dot == expected_dot;
}

test "cfg for loop with break continue and else" {
    dot = cfg_dot_from_file(file_name=os.path.join(FIXTURES, "cfg_for_stmt.jac"));
    expected_dot = (
        "digraph G {\n" + '  0 [label="BB0\\nfor i in range ( 0 , 5 )", shape=box];\n' + '  1 [label="BB1\\nif i == 1", shape=box];\n' + '  2 [label="BB2\\ncontinue ;", shape=box];\n' + '  3 [label="BB3\\nprint ( i ) ;\\nif i == 3", shape=box];\n' + '  4 [label="BB4\\nbreak ;", shape=box];\n' + '  5 [label="BB5\\nprint ( \\"done\\" ) ;", shape=box];\n' + "  0 -> 1;\n" + "  0 -> 5;\n" + "  1 -> 2;\n" + "  1 -> 3;\n" + "  2 -> 0;\n" + "  3 -> 4;\n" + "  3 -> 0;\n" + "}\n"
    );
    assert dot == expected_dot;
}

test "cfg short circuit boolean evaluation" {
    dot = cfg_dot_from_file(file_name=os.path.join(FIXTURES, "cfg_short_circuit.jac"));
    expected_dot = (
        "digraph G {\n" + '  0 [label="BB0\\ncan test_short_circuit( x : int )\\nif x > 0", shape=box];\n' + '  1 [label="BB1\\nand x < 10", shape=box];\n' + '  2 [label="BB2\\nprint ( \\"case1\\" ) ;", shape=box];\n' + '  3 [label="BB3\\nif x > 0", shape=box];\n' + '  4 [label="BB4\\nor x < - 5", shape=box];\n' + '  5 [label="BB5\\nprint ( \\"case2\\" ) ;", shape=box];\n' + '  6 [label="BB6\\nif x > 0", shape=box];\n' + '  7 [label="BB7\\nand x < 10", shape=box];\n' + '  8 [label="BB8\\nprint ( \\"case3a\\" ) ;", shape=box];\n' + '  9 [label="BB9\\nprint ( \\"case3b\\" ) ;", shape=box];\n' + '  10 [label="BB10\\nif x > 0", shape=box];\n' + '  11 [label="BB11\\nor x < - 5", shape=box];\n' + '  12 [label="BB12\\nprint ( \\"case4a\\" ) ;", shape=box];\n' + '  13 [label="BB13\\nprint ( \\"case4b\\" ) ;", shape=box];\n' + '  14 [label="BB14\\nif x > 0", shape=box];\n' + '  15 [label="BB15\\nor x == - 1", shape=box];\n' + '  16 [label="BB16\\nand x < 10", shape=box];\n' + '  17 [label="BB17\\nprint ( \\"case5\\" ) ;", shape=box];\n' + '  18 [label="BB18\\nprint ( \\"case5b\\" ) ;", shape=box];\n' + '  19 [label="BB19\\nif x > 0", shape=box];\n' + '  20 [label="BB20\\nand x < 5", shape=box];\n' + '  21 [label="BB21\\nor x > 8", shape=box];\n' + '  22 [label="BB22\\nprint ( \\"case6\\" ) ;", shape=box];\n' + '  23 [label="BB23\\nprint ( \\"case6b\\" ) ;", shape=box];\n' + '  24 [label="BB24\\nif x > 0", shape=box];\n' + '  25 [label="BB25\\nor x > 20", shape=box];\n' + '  26 [label="BB26\\nand x < 10", shape=box];\n' + '  27 [label="BB27\\nand x < 30", shape=box];\n' + '  28 [label="BB28\\nprint ( \\"case7\\" ) ;", shape=box];\n' + '  29 [label="BB29\\nprint ( \\"case7b\\" ) ;", shape=box];\n' + '  30 [label="BB30\\nif x > 0", shape=box];\n' + '  31 [label="BB31\\nand x < 100", shape=box];\n' + '  32 [label="BB32\\nor x > 90", shape=box];\n' + '  33 [label="BB33\\nprint ( \\"case8\\" ) ;", shape=box];\n' + '  34 [label="BB34\\nprint ( \\"case8b\\" ) ;", shape=box];\n' + '  35 [label="BB35\\nif x > 0", shape=box];\n' + '  36 [label="BB36\\nand x < 10", shape=box];\n' + '  37 [label="BB37\\nprint ( \\"case9a\\" ) ;", shape=box];\n' + '  38 [label="BB38\\nelif x > 20", shape=box];\n' + '  39 [label="BB39\\nor x < - 5", shape=box];\n' + '  40 [label="BB40\\nprint ( \\"case9b\\" ) ;", shape=box];\n' + '  41 [label="BB41\\nelif x > 50", shape=box];\n' + '  42 [label="BB42\\nor x == 100", shape=box];\n' + '  43 [label="BB43\\nand x < 60", shape=box];\n' + '  44 [label="BB44\\nprint ( \\"case9c\\" ) ;", shape=box];\n' + '  45 [label="BB45\\nprint ( \\"case9d\\" ) ;", shape=box];\n' + '  46 [label="BB46\\nwhile x > 0", shape=box];\n' + '  47 [label="BB47\\nand x < 10", shape=box];\n' + '  48 [label="BB48\\nprint ( x ) ;\\nx = x + 1 ;", shape=box];\n' + '  49 [label="BB49\\nwhile x > 100", shape=box];\n' + '  50 [label="BB50\\nor x < - 50", shape=box];\n' + '  51 [label="BB51\\nprint ( x ) ;\\nx = x - 1 ;", shape=box];\n' + '  52 [label="BB52\\ntest_short_circuit ( 5 ) ;", shape=box];\n' + "  0 -> 1;\n" + "  0 -> 3;\n"  # case1: AND split
         + "  1 -> 2;\n" + "  1 -> 3;\n" + "  2 -> 3;\n" + "  3 -> 5;\n" + "  3 -> 4;\n"  # case2: OR split
         + "  4 -> 5;\n" + "  4 -> 6;\n" + "  5 -> 6;\n" + "  6 -> 7;\n" + "  6 -> 9;\n"  # case3: AND + else
         + "  7 -> 8;\n" + "  7 -> 9;\n" + "  8 -> 10;\n" + "  9 -> 10;\n" + "  10 -> 12;\n" + "  10 -> 11;\n"  # case4: OR + else
         + "  11 -> 12;\n" + "  11 -> 13;\n" + "  12 -> 14;\n" + "  13 -> 14;\n" + "  14 -> 16;\n" + "  14 -> 15;\n"  # case5: (A and B) or C
         + "  15 -> 17;\n" + "  15 -> 18;\n" + "  16 -> 17;\n" + "  16 -> 15;\n" + "  17 -> 19;\n" + "  18 -> 19;\n" + "  19 -> 20;\n" + "  19 -> 23;\n"  # case6: A and (B or C)
         + "  20 -> 22;\n" + "  20 -> 21;\n" + "  21 -> 22;\n" + "  21 -> 23;\n" + "  22 -> 24;\n" + "  23 -> 24;\n" + "  24 -> 26;\n" + "  24 -> 25;\n"  # case7: (A and B) or (C and D)
         + "  25 -> 27;\n" + "  25 -> 29;\n" + "  26 -> 28;\n" + "  26 -> 25;\n" + "  27 -> 28;\n" + "  27 -> 29;\n" + "  28 -> 30;\n" + "  29 -> 30;\n" + "  30 -> 31;\n" + "  30 -> 34;\n"  # case8: A and B and (C or D)
         + "  31 -> 32;\n" + "  31 -> 34;\n" + "  32 -> 33;\n" + "  32 -> 34;\n" + "  33 -> 35;\n" + "  34 -> 35;\n" + "  35 -> 36;\n" + "  35 -> 38;\n"  # case9: elif chain
         + "  36 -> 37;\n" + "  36 -> 38;\n" + "  37 -> 46;\n" + "  38 -> 40;\n" + "  38 -> 39;\n"  # elif OR
         + "  39 -> 40;\n" + "  39 -> 41;\n" + "  40 -> 46;\n" + "  41 -> 43;\n" + "  41 -> 42;\n"  # elif (A and B) or C
         + "  42 -> 44;\n" + "  42 -> 45;\n" + "  43 -> 44;\n" + "  43 -> 42;\n" + "  44 -> 46;\n" + "  45 -> 46;\n" + "  46 -> 47;\n" + "  46 -> 49;\n"  # case10: while AND
         + "  47 -> 48;\n" + "  47 -> 49;\n" + "  48 -> 46;\n"  # loop back
         + "  49 -> 51;\n" + "  49 -> 50;\n"  # case11: while OR
         + "  50 -> 51;\n" + "  50 -> 52;\n" + "  51 -> 49;\n"  # loop back
         + "}\n"
    );
    assert dot == expected_dot;
}
