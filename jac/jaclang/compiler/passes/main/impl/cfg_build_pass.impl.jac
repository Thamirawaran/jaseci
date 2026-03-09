"""Control flow graph build pass implementation."""

# ============================================================================
# cfg_dot_from_file + CoalesceBBPass (unchanged)
# ============================================================================

"""Print the control flow graph."""
impl cfg_dot_from_file(file_name: str) -> str {
    import from jaclang.jac0core.program { JacProgram }
    with open(file_name) as f {
        file_source = f.read();
    }
    ir = (prog := JacProgram()).compile(use_str=file_source, file_path=file_name);
    cfg_pass = CoalesceBBPass(ir_in=ir, prog=prog);
    dot = cfg_pass.printgraph_cfg();
    return dot;
}

"""Initialize CoalesceBBPass."""
impl CoalesceBBPass.init(
    ir_in: uni.Module, prog: Any, cancel_token: Any = None
) -> None {
    super.init(ir_in, prog, cancel_token);
}

"""Generate dot graph for CFG."""
impl CoalesceBBPass.printgraph_cfg -> str {
    cfg: dict = {};
    dot = 'digraph G {\n';
    for (key, bb) in self.basic_blocks.items() {
        cfg[key] = {
            'bb_stmts': bb['bb_stmts'],
            'bb_out': [0 for _ in range(len(bb['bb_out']))] if bb['bb_out'] else None
        };

        if bb['bb_out'] {
            for out_obj in bb['bb_out'] {
                for (k, v) in self.basic_blocks.items() {
                    if (out_obj == v['bb_stmts'][0]) {
                        cfg[key]['bb_out'][bb['bb_out'].index(out_obj)] = k;
                        break;
                    }
                }
            }
        }
    }
    for (key, bb) in cfg.items() {
        for (i, bbs) in enumerate(bb['bb_stmts']) {
            if isinstance(bbs, uni.ElseIf) {
                cfg[key]['bb_stmts'][i] = 'elif ' + bbs.condition.unparse();
            } elif isinstance(bbs, uni.IfStmt) {
                cfg[key]['bb_stmts'][i] = 'if ' + bbs.condition.unparse();
            } elif isinstance(bbs, uni.ElseStmt) {
                cfg[key]['bb_stmts'][i] = 'else';
            } elif isinstance(bbs, uni.Archetype) {
                cfg[key]['bb_stmts'][i] = 'obj ' + bbs.name.unparse();
            } elif isinstance(bbs, uni.Ability) {
                cfg[key]['bb_stmts'][i] = 'can ' + bbs.name_ref.unparse() + bbs.signature.unparse()
                    if bbs.signature
                    else '';
            } elif isinstance(bbs, (uni.InForStmt, uni.IterForStmt)) {
                cfg[key]['bb_stmts'][i] = (
                    'for ' + bbs.target.unparse() + ' in ' + bbs.collection.unparse()
                )
                    if isinstance(bbs, uni.InForStmt)
                    else (
                        'for ' + bbs.iter.unparse() + bbs.condition.unparse() + bbs.count_by.unparse()
                    );
            } elif isinstance(bbs, uni.WhileStmt) {
                cfg[key]['bb_stmts'][i] = 'while ' + bbs.condition.unparse();
            } else {
                cfg[key]['bb_stmts'][i] = bbs.unparse();
            }
        }
    }
    for (key, value) in cfg.items() {
        if value.get('bb_stmts') {
            stmts = '\\n'.join([stmt.replace('"', '\\"') for stmt in value['bb_stmts']]);
            dot += f'  {key} [label="BB{key}\\n{stmts}", shape=box];' + "\n";
        } else {
            dot += f'  {key} [label="BB{key}"];' + "\n";
        }
    }
    for (key, value) in cfg.items() {
        if value.get('bb_out') {
            for out_id in value['bb_out'] {
                dot += f"  {key} -> {out_id};\n";
            }
        }
    }
    dot += '}\n';
    return dot;
}

"""Enter BasicBlockStmt nodes."""
impl CoalesceBBPass.enter_node(nd: uni.UniNode) -> None {
    if (isinstance(nd, uni.UniCFGNode) and not isinstance(nd, uni.Semi)) {
        for bbs in self.basic_blocks.values() {
            if (nd in bbs['bb_stmts']) {
                return;
            }
        }
        tail = nd.get_tail();
        bb = self.get_bb(nd);
        self.basic_blocks[self.bb_counter] = {'bb_stmts': bb, 'bb_out': tail.bb_out};
        self.bb_counter += 1;
    }
}

"""Get basic block."""
impl CoalesceBBPass.get_bb(nd: uni.UniCFGNode) -> list[uni.UniCFGNode] {
    head = nd.get_head();
    tail = nd.get_tail();
    bb_list: list[uni.UniCFGNode] = [];
    if (head and tail) {
        cur_node = head;
        while (cur_node != tail) {
            if (cur_node not in bb_list) {
                bb_list.append(cur_node);
            }

            if cur_node.bb_out {
                cur_node = cur_node.bb_out[0];
            }
        }
        bb_list.append(tail) if (tail not in bb_list) else None;
    }
    return bb_list;
}

"""Before pass."""
impl CoalesceBBPass.before_pass -> None {
    self.basic_blocks: dict = {};
    self.bb_counter: int = 0;
}

# ============================================================================
# CFGBuildPass
# ============================================================================

impl CFGBuildPass.init(ir_in: uni.Module, prog: Any, cancel_token: Any = None) -> None {
    super.init(ir_in, prog, cancel_token);
}

"""Before pass -- no state needed."""
impl CFGBuildPass.before_pass -> None {}

# ============================================================================
# Utilities
# ============================================================================

"""Link two CFG nodes: source.bb_out -> target, target.bb_in -> source.
Also propagates affected_symbols for the Pyright-style branch-skipping optimization."""
impl CFGBuildPass.link_bbs(source: uni.UniCFGNode, target: uni.UniCFGNode) -> None {
    if source and target {
        if target not in source.bb_out {
            source.bb_out.append(target);
        }
        if source not in target.bb_in {
            target.bb_in.append(source);
        }
        target.affected_symbols.update(source.affected_symbols);
    }
}

"""Link sequential statements in a body, skipping after terminals.
For compound statements (if/while/for/try/match/etc.), also connects
their internal unconnected tails to the next sibling."""
impl CFGBuildPass._link_sequential(body: Sequence[uni.CodeBlockStmt]) -> None {
    for i in range(1, len(body)) {
        prev = body[i - 1];
        next = body[i];
        if self._is_terminal(prev) {
            continue;
        }
        if isinstance(prev, uni.IfStmt) and prev.else_body is not None {
            # All branches covered by if/elif/else -- no direct prev→next edge.
            # Only connect internal tails (body ends) to next.
            self._connect_tails(prev, next);
        } else {
            # Direct prev→next edge (includes false-branch fallthrough for if-without-else).
            self.link_bbs(prev, next);
            # Also connect internal tails for compound stmts.
            self._connect_tails(prev, next);
        }
    }
}

"""Find non-terminal CFG nodes with empty bb_out in parent's subtree and link to target.
Skips expression subtrees and scope boundaries (Ability, Archetype, ImplDef).
Recurses into compound stmts and non-CFG containers (ElseStmt, MatchCase, etc.)."""
impl CFGBuildPass._connect_tails(parent: uni.UniNode, target: uni.UniCFGNode) -> None {
    for k in parent.kid {
        if not k or isinstance(k, uni.Expr) or isinstance(k, uni.Semi) {
            continue;
        }
        if isinstance(k, (uni.Ability, uni.Archetype, uni.ImplDef)) {
            # Scope boundary -- don't recurse into nested scopes
            continue;
        }
        if isinstance(k, uni.UniCFGNode) {
            if not k.bb_out and not self._is_terminal(k) {
                # Unconnected tail -- link to target
                self.link_bbs(k, target);
            } elif isinstance(k, uni.IfStmt) and not k.else_body {
                # If/elif without else: false branch falls through to target
                self.link_bbs(k, target);
                self._connect_tails(k, target);
            } else {
                # Has outgoing edges or is terminal -- check children
                self._connect_tails(k, target);
            }
        } else {
            # Non-CFG container (ElseStmt, MatchCase, etc.) -- check children
            self._connect_tails(k, target);
        }
    }
}

"""Check if a node is a terminal (no control flow continues past it)."""
impl CFGBuildPass._is_terminal(nd: uni.UniNode) -> bool {
    return isinstance(nd, (uni.ReturnStmt, uni.RaiseStmt, uni.CtrlStmt, uni.DisengageStmt));
}

"""Find the nearest ancestor matching one of the given types."""
impl CFGBuildPass._find_parent_of_types(
    nd: uni.UniNode, types: tuple
) -> (uni.UniNode | None) {
    cur = nd.parent;
    while cur {
        if isinstance(cur, types) {
            return cur;
        }
        cur = cur.parent;
    }
    return None;
}

"""Find the next CodeBlockStmt sibling after child in parent.body."""
impl CFGBuildPass._find_next_cfg_stmt_after(
    parent: uni.UniNode, child: uni.UniNode
) -> (uni.UniCFGNode | None) {
    if hasattr(parent, 'body') and isinstance(parent.body, Sequence) {
        found = False;
        for stmt in parent.body {
            if found and isinstance(stmt, uni.CodeBlockStmt) {
                return stmt;
            }
            if stmt is child {
                found = True;
            }
        }
    }
    return None;
}

# ============================================================================
# Symbol collection (enter handlers)
# ============================================================================

"""Collect affected_symbols for all CFG nodes, then dispatch to type-specific enter."""
impl CFGBuildPass.enter_node(nd: uni.UniNode) -> None {
    import from jaclang.compiler.symbol_utils { collect_assigned_symbols }
    if isinstance(nd, uni.UniCFGNode) and not isinstance(nd, uni.Semi) {
        nd.affected_symbols.update(collect_assigned_symbols(nd));
    }
    # Dispatch to enter_if_stmt, enter_assert_stmt, etc.
    super.enter_node(nd);
}

"""Collect narrowing symbols from if condition."""
impl CFGBuildPass.enter_if_stmt(nd: uni.IfStmt) -> None {
    import from jaclang.compiler.symbol_utils { collect_narrowing_symbols }
    nd.affected_symbols.update(collect_narrowing_symbols(nd.condition));
}

"""Collect narrowing symbols from elif condition."""
impl CFGBuildPass.enter_else_if(nd: uni.ElseIf) -> None {
    import from jaclang.compiler.symbol_utils { collect_narrowing_symbols }
    nd.affected_symbols.update(collect_narrowing_symbols(nd.condition));
}

"""Collect narrowing symbols from assert condition."""
impl CFGBuildPass.enter_assert_stmt(nd: uni.AssertStmt) -> None {
    import from jaclang.compiler.symbol_utils { collect_narrowing_symbols }
    nd.affected_symbols.update(collect_narrowing_symbols(nd.condition));
}

"""Collect affected symbols from match target."""
impl CFGBuildPass.enter_match_stmt(nd: uni.MatchStmt) -> None {
    if isinstance(nd.target, uni.Name) {
        nd.affected_symbols.add(nd.target.value);
    }
}

# ============================================================================
# Edge building (exit handlers) -- Branch
# ============================================================================

"""IfStmt: link to body + else_body."""
impl CFGBuildPass.exit_if_stmt(nd: uni.IfStmt) -> None {
    # Sequential link within body (first stmt gets if as predecessor)
    if nd.body {
        self.link_bbs(nd, nd.body[0]);
        self._link_sequential(nd.body);
    }
    # Else branch
    if nd.else_body {
        if isinstance(nd.else_body, uni.ElseIf) {
            self.link_bbs(nd, nd.else_body);
        } elif isinstance(nd.else_body, uni.ElseStmt) and nd.else_body.body {
            self.link_bbs(nd, nd.else_body.body[0]);
        }
    }
}

"""ElseIf: same structure as IfStmt (ElseIf extends IfStmt)."""
impl CFGBuildPass.exit_else_if(nd: uni.ElseIf) -> None {
    self.exit_if_stmt(nd);
}

"""ElseStmt: sequential link within body (incoming edge set by parent IfStmt/ElseIf)."""
impl CFGBuildPass.exit_else_stmt(nd: uni.ElseStmt) -> None {
    if nd.body {
        self._link_sequential(nd.body);
    }
}

# ============================================================================
# Edge building (exit handlers) -- Loop
# ============================================================================

"""WhileStmt: body + back-edge + else_body."""
impl CFGBuildPass.exit_while_stmt(nd: uni.WhileStmt) -> None {
    if nd.body {
        self.link_bbs(nd, nd.body[0]);
        self._link_sequential(nd.body);
        # Back-edge: last body stmt -> loop header
        if not self._is_terminal(nd.body[-1]) {
            self.link_bbs(nd.body[-1], nd);
        }
    }
    # Loop-else: runs on normal exit (condition false), not on break
    if nd.else_body and isinstance(nd.else_body, uni.ElseStmt) and nd.else_body.body {
        self.link_bbs(nd, nd.else_body.body[0]);
    }
}

"""InForStmt: body + back-edge + else_body."""
impl CFGBuildPass.exit_in_for_stmt(nd: uni.InForStmt) -> None {
    if nd.body {
        self.link_bbs(nd, nd.body[0]);
        self._link_sequential(nd.body);
        if not self._is_terminal(nd.body[-1]) {
            self.link_bbs(nd.body[-1], nd);
        }
    }
    if nd.else_body and isinstance(nd.else_body, uni.ElseStmt) and nd.else_body.body {
        self.link_bbs(nd, nd.else_body.body[0]);
    }
}

"""IterForStmt: body + back-edge + else_body."""
impl CFGBuildPass.exit_iter_for_stmt(nd: uni.IterForStmt) -> None {
    if nd.body {
        self.link_bbs(nd, nd.body[0]);
        self._link_sequential(nd.body);
        if not self._is_terminal(nd.body[-1]) {
            self.link_bbs(nd.body[-1], nd);
        }
    }
    if nd.else_body and isinstance(nd.else_body, uni.ElseStmt) and nd.else_body.body {
        self.link_bbs(nd, nd.else_body.body[0]);
    }
}

# ============================================================================
# Edge building (exit handlers) -- Control flow
# ============================================================================

"""CtrlStmt: break -> next after loop, continue -> loop header."""
impl CFGBuildPass.exit_ctrl_stmt(nd: uni.CtrlStmt) -> None {
    loop = self._find_parent_of_types(
        nd, (uni.WhileStmt, uni.InForStmt, uni.IterForStmt)
    );
    if not loop {
        return;
    }
    if nd.ctrl.value == "continue" {
        self.link_bbs(nd, loop);
    } elif nd.ctrl.value == "break" {
        if loop.parent {
            next_node = self._find_next_cfg_stmt_after(loop.parent, loop);
            if next_node {
                self.link_bbs(nd, next_node);
            }
        }
    }
}

# ============================================================================
# Edge building (exit handlers) -- Exception
# ============================================================================

"""TryStmt: body + except handlers + finally."""
impl CFGBuildPass.exit_try_stmt(nd: uni.TryStmt) -> None {
    # Try body
    if nd.body {
        self.link_bbs(nd, nd.body[0]);
        self._link_sequential(nd.body);
    }
    # Conservative: any stmt in try could throw -> link to each except handler
    for exc in nd.excepts {
        self.link_bbs(nd, exc);
    }
    # Try-else: runs on normal completion (no exception)
    if nd.else_body and isinstance(nd.else_body, uni.ElseStmt) and nd.else_body.body {
        if nd.body and not self._is_terminal(nd.body[-1]) {
            self.link_bbs(nd.body[-1], nd.else_body.body[0]);
        }
    }
    # Finally: all paths flow through it
    if nd.finally_body {
        if nd.body and not self._is_terminal(nd.body[-1]) {
            self.link_bbs(nd.body[-1], nd.finally_body);
        }
        for exc in nd.excepts {
            if exc.body and not self._is_terminal(exc.body[-1]) {
                self.link_bbs(exc.body[-1], nd.finally_body);
            }
        }
    }
}

"""Except: link to body."""
impl CFGBuildPass.exit_except(nd: uni.Except) -> None {
    if nd.body {
        self.link_bbs(nd, nd.body[0]);
        self._link_sequential(nd.body);
    }
}

"""FinallyStmt: link to body."""
impl CFGBuildPass.exit_finally_stmt(nd: uni.FinallyStmt) -> None {
    if nd.body {
        self.link_bbs(nd, nd.body[0]);
        self._link_sequential(nd.body);
    }
}

# ============================================================================
# Edge building (exit handlers) -- Multi-branch
# ============================================================================

"""MatchStmt: link to each MatchCase node."""
impl CFGBuildPass.exit_match_stmt(nd: uni.MatchStmt) -> None {
    for case in nd.cases {
        self.link_bbs(nd, case);
    }
}

"""MatchCase: link to body (incoming set by MatchStmt)."""
impl CFGBuildPass.exit_match_case(nd: uni.MatchCase) -> None {
    if nd.body {
        self.link_bbs(nd, nd.body[0]);
        self._link_sequential(nd.body);
    }
}

"""SwitchStmt: link to each SwitchCase node."""
impl CFGBuildPass.exit_switch_stmt(nd: uni.SwitchStmt) -> None {
    for case in nd.cases {
        self.link_bbs(nd, case);
    }
}

"""SwitchCase: link to body (incoming set by SwitchStmt)."""
impl CFGBuildPass.exit_switch_case(nd: uni.SwitchCase) -> None {
    if nd.body {
        self.link_bbs(nd, nd.body[0]);
        self._link_sequential(nd.body);
    }
}

# ============================================================================
# Edge building (exit handlers) -- Other
# ============================================================================

"""WithStmt: link to body."""
impl CFGBuildPass.exit_with_stmt(nd: uni.WithStmt) -> None {
    if nd.body {
        self.link_bbs(nd, nd.body[0]);
        self._link_sequential(nd.body);
    }
}

"""TypedCtxBlock: link to body."""
impl CFGBuildPass.exit_typed_ctx_block(nd: uni.TypedCtxBlock) -> None {
    if nd.body {
        self.link_bbs(nd, nd.body[0]);
        self._link_sequential(nd.body);
    }
}

# ============================================================================
# Edge building (exit handlers) -- Scope boundaries
# ============================================================================

"""Ability: scope boundary, link to body."""
impl CFGBuildPass.exit_ability(nd: uni.Ability) -> None {
    if nd.body and isinstance(nd.body, Sequence) {
        body = [s for s in nd.body if isinstance(s, uni.CodeBlockStmt)];
        if body {
            self.link_bbs(nd, body[0]);
            self._link_sequential(body);
        }
    }
}

"""Archetype: scope boundary, link to each child (declarations are independent)."""
impl CFGBuildPass.exit_archetype(nd: uni.Archetype) -> None {
    if nd.body and isinstance(nd.body, Sequence) {
        for s in nd.body {
            if isinstance(s, uni.CodeBlockStmt) {
                self.link_bbs(nd, s);
            }
        }
    }
}

"""ImplDef: scope boundary, link to body."""
impl CFGBuildPass.exit_impl_def(nd: uni.ImplDef) -> None {
    if nd.body and isinstance(nd.body, Sequence) {
        body = [s for s in nd.body if isinstance(s, uni.CodeBlockStmt)];
        if body {
            self.link_bbs(nd, body[0]);
            self._link_sequential(body);
        }
    }
}

"""ModuleCode: sequential link body (not a CFG node, no parent edge)."""
impl CFGBuildPass.exit_module_code(nd: uni.ModuleCode) -> None {
    if nd.body {
        self._link_sequential(nd.body);
    }
}
