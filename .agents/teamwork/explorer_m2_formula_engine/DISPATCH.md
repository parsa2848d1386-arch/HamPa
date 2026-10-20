## 2026-10-16T21:43:50Z
Sender: 22d8faaf-eb90-463c-99a6-32a4eb94320e (parent)
Content:
You are explorer_m2_formula_engine.
Your working directory is c:\parsa\HamPA\.agents\teamwork\explorer_m2_formula_engine.
You MUST read:
1. c:\parsa\HamPA\.agents\teamwork\ORIGINAL_REQUEST.md
2. c:\parsa\HamPA\PROJECT.md (Milestone 2, F10, F11)

Your task is to design the file-by-file blueprint for Milestone 2 Formula Engine & Rollup Calculator:
- Tokenizer / Lexer for Notion-like formulas (identifiers `prop("Price")`, literals, operators `+`, `-`, `*`, `/`, `%`, `==`, `!=`, `<`, `>`, `<=`, `>=`, `&&`, `||`, functions `if`, `dateAdd`, `dateBetween`, `format`, `concat`, `length`, `round`, `ceil`, `floor`).
- Recursive Descent Parser generating an Abstract Syntax Tree (AST: `BinaryOpNode`, `UnaryOpNode`, `PropertyRefNode`, `FunctionCallNode`, `LiteralNode`).
- Cycle Detection: Directed dependency graph tracking cross-property and cross-formula references; detect circular dependencies and return `#CYCLE!` instead of stack overflow or infinite loops.
- Rollup Engine: Evaluates rollups across relations (target relation property + target property + aggregation function: `countAll`, `countValues`, `countUnique`, `countEmpty`, `countNotEmpty`, `percentEmpty`, `percentNotEmpty`, `sum`, `average`, `median`, `min`, `max`, `range`, `percentChecked`).
- Unit test suite blueprint with comprehensive formula test cases and circular reference edge cases.

Write your complete blueprint in c:\parsa\HamPA\.agents\teamwork\explorer_m2_formula_engine\handoff.md.
Do NOT write or edit source code directly.
When done, use send_message to report back to parent orchestrator (Conversation ID: 22d8faaf-eb90-463c-99a6-32a4eb94320e).
