# Milestone 2 Formula Engine & Rollup Calculator Blueprint Report

## 1. Observation

Direct code observations from project inspection:
1. **Repository Layout and Milestone Scope**:
   - `c:\parsa\HamPA\PROJECT.md` (lines 29-32) defines Milestone 2 features:
     - `F08`: Rich Property Schema Engine (dynamic columns: text, number, select, multi-select, status, date, tags, relations, formulas, rollups).
     - `F09`: Two-Way Database Relations (1:1, 1:N, N:N linking between rows of different databases).
     - `F10`: Formula Expression Engine (AST evaluator for math, string, date, logic, and cycle detection `#CYCLE!`).
     - `F11`: Automatic Rollups & Aggregations (Sum, Average, Min, Max, Count, Percent checked across relations).
   - `c:\parsa\HamPA\PROJECT.md` (lines 90-102) defines interface contract `IDatabaseEngineRepository`:
     ```dart
     Future<dynamic> evaluateFormula({required String rowId, required String expression});
     Future<dynamic> computeRollup({
       required String rowId,
       required String relationPropertyId,
       required String targetPropertyId,
       required RollupFunction function,
     });
     ```
2. **Existing Database Contracts and E2E Harness**:
   - `c:\parsa\HamPA\test\e2e\contracts\database_contracts.dart` (lines 4-25) defines `PropertyType` and `RollupFunction`:
     ```dart
     enum PropertyType { title, text, number, select, multiSelect, status, date, checkbox, relation, formula, rollup }
     enum RollupFunction { sum, average, min, max, count, percentChecked }
     ```
   - `c:\parsa\HamPA\test\e2e\harness\test_database_harness.dart` (lines 254-324) implements an in-memory prototype of `evaluateFormula` with rudimentary regex matching for `prop("Name")`, basic arithmetic, division by zero detection (`#DIV/0!`), and recursion prevention with `visitedProperties`.
   - `c:\parsa\HamPA\test\e2e\harness\test_database_harness.dart` (lines 327-396) implements an in-memory prototype of `computeRollup` evaluating `sum`, `average`, `count`, `min`, `max`, and `percentChecked`.
3. **Existing E2E Test Suite Expectations**:
   - `test/e2e/tier1_feature_coverage/f08_f16_relational_database_test.dart`:
     - Lines 226-234: `F10-1: 10 + 25` evaluates to `35.0`.
     - Lines 236-247: `F10-2: prop("Hours") * 60` evaluates to `240.0`.
     - Lines 249-262: `F10-3: prop("Midterm") + prop("Final")` evaluates to `90.0`.
     - Lines 264-273: `F10-4: prop("MissingVal") + 10` returns `null` when property value is null.
     - Lines 275-284: `F10-5: ACTIVE` fallback string literal evaluates to `'ACTIVE'`.
     - Lines 295-323: `F11-1: Rollup Sum` aggregates scores to `100`.
     - Lines 325-351: `F11-2: Rollup Average` computes mean (`85.0`).
     - Lines 353-383: `F11-3: Rollup Count` returns count of linked rows (`4`).
     - Lines 385-415: `F11-4: Rollup Percent Checked` computes boolean percentage (`75.0`).
     - Lines 417-452: `F11-5: Rollup Min and Max` computes `12` and `89`.
   - `test/e2e/tier2_boundary_corner/f08_f16_relational_boundary_test.dart`:
     - Lines 167-181: `F10-B1`: Circular formula reference returns `#CYCLE!`.
     - Lines 183-195: `F10-B2`: Division by zero (`100 / 0` and `50 /0`) returns `#DIV/0!`.
     - Lines 197-204: `F10-B3`: Missing property returns `null`.
     - Lines 206-214: `F10-B4`: Negative arithmetic (`50 - 80`) returns `-30.0`.
     - Lines 216-224: `F10-B5`: Large numbers (`1000000 * 2000`) evaluate to `2000000000.0` without integer overflow.
     - Lines 236-260: `F11-B1`: Rollup targeting empty relation returns `0` for sum, `null` for average.
     - Lines 262-277: `F11-B2`: Rollup Percent Checked with 0 items returns `0.0` without divide-by-zero.
     - Lines 279-294: `F11-B3`: Rollup Min/Max on empty list returns `null`.
     - Lines 296-316: `F11-B4`: Rollup Average on single item list returns exact item value (`77.0`).
4. **Current Implementation Gap**:
   - `lib/features/workspace_database/` does not yet exist.
   - The test harness only implements an in-memory regex mock. It cannot parse nested expressions (e.g. `(2 + 3) * 4`), multiple function calls (`if(prop("A") > 10, concat("High: ", format(prop("A"))), "Low")`), date manipulation (`dateAdd`, `dateBetween`), or arbitrary directed dependency cycles.
   - A full-featured recursive descent parser, token scanner, dependency graph analyzer, and rollup calculator must be introduced in Milestone 2.

---

## 2. Logic Chain

1. **Clean Architecture Separation**:
   - Following `PROJECT.md` Clean Architecture principles, the formula and rollup engines belong in the Domain Layer as pure Dart components without Flutter UI dependencies (`lib/features/workspace_database/domain/formula/` and `lib/features/workspace_database/domain/rollup/`).
   - This ensures 100% testability via fast, headless Dart unit tests (`test/unit/formula/`) and portability across isolate boundaries.
2. **Lexing and Parsing Pipeline**:
   - Notion formula syntax combines arithmetic/comparison operators, property lookups (`prop("Name")`), literals, and nested function invocations (`if`, `dateAdd`, etc.).
   - A dedicated `FormulaLexer` converts raw formula strings into a linear stream of strongly-typed `Token` objects, preserving character positions for informative syntax error reporting.
   - A `FormulaParser` employing Recursive Descent with standard operator precedence guarantees unambiguous parsing, proper associativity (left-associative for arithmetic/logical operators; right-associative for unary operators), and parenthesized sub-expression nesting.
3. **AST Structure & Static Analysis**:
   - The AST nodes are modeled as a Dart 3 `sealed class FormulaNode` with concrete subclasses:
     - `LiteralNode`
     - `PropertyRefNode`
     - `UnaryOpNode`
     - `BinaryOpNode`
     - `FunctionCallNode`
   - Every node exposes `Set<String> extractPropertyReferences()`, allowing static extraction of all referenced property names before evaluation. This feeds directly into the directed dependency graph.
4. **Cycle Detection Strategy**:
   - To prevent infinite recursion and stack overflow, circular reference detection operates at two levels:
     - **Static Graph Analysis (`FormulaDependencyGraph`)**: Builds a directed graph of property dependencies. Uses 3-color DFS (White, Gray, Black) or Tarjan's SCC to identify cycles ahead of time and compute a `topologicalOrder()` for cascading recomputations.
     - **Runtime Active Stack (`FormulaContext`)**: Maintains a `Set<String> _activeCallStack` during evaluation. If an evaluation for a property encounters an active ancestor on the call stack, it halts recursion immediately and yields `FormulaValue.cycle()` (`#CYCLE!`).
5. **Rollup Calculation Completeness**:
   - To satisfy all 14 rollup functions specified in Milestone 2 requirements (`countAll`, `countValues`, `countUnique`, `countEmpty`, `countNotEmpty`, `percentEmpty`, `percentNotEmpty`, `sum`, `average`, `median`, `min`, `max`, `range`, `percentChecked`), the calculations are partitioned into:
     - `RollupCalculator`: Pure stateless calculation over a list of dynamic values.
     - `RollupEvaluator`: Coordinates relation traversal, row resolution, and cell value extraction.

---

## 3. Caveats

1. **Database Schema Integration**:
   - While the formula engine relies on `FormulaContext` (an interface), actual Drift SQLite property IDs and row IDs will be linked when `workspace_database` data DAOs and repositories are built. The blueprint defines clean abstractions (`IFormulaContext`) so the engine has zero coupling to database implementation specifics.
2. **DateTime Timezone Conventions**:
   - `dateAdd` and `dateBetween` operate using UTC `DateTime` values to avoid daylight saving time ambiguities. Timezone adjustments should occur at the presentation layer.
3. **Type Coercion Nuances**:
   - Notion allows strings in arithmetic `+` to trigger concatenation (e.g., `"Value: " + 10` -> `"Value: 10"`). In subtraction, multiplication, and division, string operands that cannot be parsed as numbers produce `#VALUE!` errors or `null`.
4. **Case Sensitivity**:
   - In Notion, property names inside `prop("Name")` are case-sensitive matching the exact property name, while function names (`if`, `IF`, `dateAdd`) are case-insensitive. The parser normalizes function identifiers to lowercase.

---

## 4. Conclusion: File-by-File Technical Blueprint

### Summary of New Files to Be Created

```
lib/features/workspace_database/
├── domain/
│   ├── formula/
│   │   ├── token.dart                  # Token definition & TokenType enum
│   │   ├── lexer.dart                  # Character scanner & tokenizer
│   │   ├── ast_nodes.dart              # Sealed FormulaNode AST hierarchy
│   │   ├── parser.dart                 # Recursive descent parser
│   │   ├── formula_value.dart          # Typed runtime value & error codes
│   │   ├── formula_context.dart        # Property resolution context interface
│   │   ├── formula_evaluator.dart      # AST interpreter & built-in functions
│   │   └── dependency_graph.dart       # Directed graph, cycle detector & topological sort
│   └── rollup/
│       ├── rollup_function.dart        # 14 Rollup aggregation functions enum
│       ├── rollup_calculator.dart      # Pure aggregation calculation functions
│       └── rollup_evaluator.dart       # Cross-relation data resolver
test/unit/formula/
├── formula_lexer_test.dart             # Lexer tokenization & edge case tests
├── formula_parser_test.dart            # Parser AST & precedence tests
├── formula_evaluator_test.dart         # Formula evaluation, math, string, date & errors
├── dependency_graph_test.dart          # Cycle detection (#CYCLE!) & topological order tests
└── rollup_calculator_test.dart         # All 14 rollup functions & empty/boundary tests
```

---

### Detailed File Specifications

#### File 1: `lib/features/workspace_database/domain/formula/token.dart`
- **Purpose**: Defines lexical tokens and token classification for the formula language.
- **Classes**:
  ```dart
  enum TokenType {
    // Literals
    number,
    string,
    boolean,
    nullLiteral,

    // Identifiers & Built-in Keywords
    identifier,
    prop,      // 'prop'
    fnIf,      // 'if'
    dateAdd,   // 'dateAdd'
    dateBetween,// 'dateBetween'
    format,    // 'format'
    concat,    // 'concat'
    length,    // 'length'
    round,     // 'round'
    ceil,      // 'ceil'
    floor,     // 'floor'

    // Operators
    plus,          // '+'
    minus,         // '-'
    star,          // '*'
    slash,         // '/'
    percent,       // '%'
    equalEqual,    // '=='
    bangEqual,     // '!='
    less,          // '<'
    lessEqual,     // '<='
    greater,       // '>'
    greaterEqual,  // '>='
    andAnd,        // '&&'
    orOr,          // '||'
    bang,          // '!'

    // Punctuation
    leftParen,     // '('
    rightParen,    // ')'
    comma,         // ','

    // End of File
    eof,
  }

  class Token {
    final TokenType type;
    final String lexeme;
    final dynamic literal;
    final int position;

    const Token({
      required this.type,
      required this.lexeme,
      this.literal,
      required this.position,
    });

    @override
    String toString() => 'Token($type, "$lexeme", $literal, pos: $position)';
  }
  ```

---

#### File 2: `lib/features/workspace_database/domain/formula/lexer.dart`
- **Purpose**: Converts a formula expression string into a sequence of `Token` instances.
- **Key Responsibilities**:
  - Scanning numeric literals (integers, floating-point decimals, e.g. `42`, `3.1415`).
  - Scanning string literals delimited by double quotes (`"..."`) or single quotes (`'...'`), supporting escape sequences: `\"`, `\'`, `\\`, `\n`, `\t`.
  - Scanning identifiers and mapping keywords: `prop`, `if`, `dateAdd`, `dateBetween`, `format`, `concat`, `length`, `round`, `ceil`, `floor`, `true`, `false`, `null`.
  - Scanning multi-character operators: `==`, `!=`, `<=`, `>=`, `&&`, `||`.
  - Scanning single-character operators and delimiters: `+`, `-`, `*`, `/`, `%`, `<`, `>`, `!`, `(`, `)`, `,`.
  - Skipping whitespace (spaces, tabs, newlines).
  - Throwing `FormulaLexerException` with character offset on malformed tokens (e.g. unterminated strings).
- **Class Signature**:
  ```dart
  class FormulaLexer {
    final String source;
    final List<Token> tokens = [];
    int _start = 0;
    int _current = 0;

    FormulaLexer(this.source);

    List<Token> scanTokens();
    // Helper methods: _scanToken(), _isAtEnd, _advance(), _peek(), _peekNext(),
    // _match(String expected), _string(String quoteChar), _number(), _identifier()
  }

  class FormulaLexerException implements Exception {
    final String message;
    final int position;
    FormulaLexerException(this.message, this.position);
    @override
    String toString() => 'FormulaLexerException at $position: $message';
  }
  ```

---

#### File 3: `lib/features/workspace_database/domain/formula/ast_nodes.dart`
- **Purpose**: Abstract Syntax Tree node hierarchy using Dart 3 sealed classes for compile-time exhaustive pattern matching.
- **Node Hierarchy**:
  ```dart
  enum BinaryOperator {
    add, subtract, multiply, divide, modulo,
    equal, notEqual, lessThan, lessThanOrEqual, greaterThan, greaterThanOrEqual,
    and, or,
  }

  enum UnaryOperator {
    negate, plus, not,
  }

  sealed class FormulaNode {
    const FormulaNode();
    Set<String> extractPropertyReferences();
    R accept<R, C>(FormulaVisitor<R, C> visitor, C context);
  }

  class LiteralNode extends FormulaNode {
    final dynamic value; // num, String, bool, or null
    const LiteralNode(this.value);

    @override
    Set<String> extractPropertyReferences() => const {};

    @override
    R accept<R, C>(FormulaVisitor<R, C> visitor, C context) =>
        visitor.visitLiteral(this, context);
  }

  class PropertyRefNode extends FormulaNode {
    final String propertyName;
    const PropertyRefNode(this.propertyName);

    @override
    Set<String> extractPropertyReferences() => {propertyName};

    @override
    R accept<R, C>(FormulaVisitor<R, C> visitor, C context) =>
        visitor.visitPropertyRef(this, context);
  }

  class UnaryOpNode extends FormulaNode {
    final UnaryOperator operator;
    final FormulaNode operand;
    const UnaryOpNode(this.operator, this.operand);

    @override
    Set<String> extractPropertyReferences() => operand.extractPropertyReferences();

    @override
    R accept<R, C>(FormulaVisitor<R, C> visitor, C context) =>
        visitor.visitUnaryOp(this, context);
  }

  class BinaryOpNode extends FormulaNode {
    final BinaryOperator operator;
    final FormulaNode left;
    final FormulaNode right;
    const BinaryOpNode(this.operator, this.left, this.right);

    @override
    Set<String> extractPropertyReferences() => {
      ...left.extractPropertyReferences(),
      ...right.extractPropertyReferences(),
    };

    @override
    R accept<R, C>(FormulaVisitor<R, C> visitor, C context) =>
        visitor.visitBinaryOp(this, context);
  }

  class FunctionCallNode extends FormulaNode {
    final String functionName;
    final List<FormulaNode> arguments;
    const FunctionCallNode(this.functionName, this.arguments);

    @override
    Set<String> extractPropertyReferences() =>
        arguments.expand((arg) => arg.extractPropertyReferences()).toSet();

    @override
    R accept<R, C>(FormulaVisitor<R, C> visitor, C context) =>
        visitor.visitFunctionCall(this, context);
  }

  abstract class FormulaVisitor<R, C> {
    R visitLiteral(LiteralNode node, C context);
    R visitPropertyRef(PropertyRefNode node, C context);
    R visitUnaryOp(UnaryOpNode node, C context);
    R visitBinaryOp(BinaryOpNode node, C context);
    R visitFunctionCall(FunctionCallNode node, C context);
  }
  ```

---

#### File 4: `lib/features/workspace_database/domain/formula/parser.dart`
- **Purpose**: Recursive descent parser converting token stream into AST.
- **Operator Precedence (lowest to highest)**:
  1. `expression()` -> `logicalOr()`
  2. `logicalOr()` -> `logicalAnd()` (`||`)
  3. `logicalAnd()` -> `equality()` (`&&`)
  4. `equality()` -> `comparison()` (`==`, `!=`)
  5. `comparison()` -> `term()` (`<`, `<=`, `>`, `>=`)
  6. `term()` -> `factor()` (`+`, `-`)
  7. `factor()` -> `unary()` (`*`, `/`, `%`)
  8. `unary()` -> `!`, `-`, `+`
  9. `primary()`:
     - Literals: `number`, `string`, `true`, `false`, `null`
     - Property access: `prop("Name")` -> parsed as `PropertyRefNode("Name")`
     - Function calls: `if(...)`, `dateAdd(...)`, `concat(...)`, etc. -> `FunctionCallNode(name, args)`
     - Parenthesized expressions: `( expr )`
     - Fallback bare identifiers (e.g. `'ACTIVE'`) -> `LiteralNode('ACTIVE')`
- **Class Signature**:
  ```dart
  class FormulaParser {
    final List<Token> tokens;
    int _current = 0;

    FormulaParser(this.tokens);

    FormulaNode parse();

    FormulaNode _expression();
    FormulaNode _logicalOr();
    FormulaNode _logicalAnd();
    FormulaNode _equality();
    FormulaNode _comparison();
    FormulaNode _term();
    FormulaNode _factor();
    FormulaNode _unary();
    FormulaNode _primary();
    FormulaNode _functionCall(String name);
    FormulaNode _propReference();

    // Utility methods: _match(), _check(), _advance(), _peek(), _previous(), _consume()
  }

  class FormulaParseException implements Exception {
    final String message;
    final Token? token;
    FormulaParseException(this.message, [this.token]);
    @override
    String toString() => 'FormulaParseException: $message at ${token?.lexeme}';
  }
  ```

---

#### File 5: `lib/features/workspace_database/domain/formula/formula_value.dart`
- **Purpose**: Unified runtime representation of formula evaluation results and error badges.
- **Specification**:
  ```dart
  sealed class FormulaValue {
    const FormulaValue();

    factory FormulaValue.number(num value) = NumberFormulaValue;
    factory FormulaValue.string(String value) = StringFormulaValue;
    factory FormulaValue.boolean(bool value) = BooleanFormulaValue;
    factory FormulaValue.date(DateTime value) = DateFormulaValue;
    factory FormulaValue.nullValue() = NullFormulaValue;
    factory FormulaValue.divZero() => const ErrorFormulaValue('#DIV/0!');
    factory FormulaValue.cycle() => const ErrorFormulaValue('#CYCLE!');
    factory FormulaValue.error([String code = '#ERROR!']) => ErrorFormulaValue(code);

    dynamic get rawValue;
    bool get isTruthy;
    bool get isError;
  }

  class NumberFormulaValue extends FormulaValue {
    final num value;
    const NumberFormulaValue(this.value);
    @override dynamic get rawValue => value;
    @override bool get isTruthy => value != 0;
    @override bool get isError => false;
  }

  class StringFormulaValue extends FormulaValue {
    final String value;
    const StringFormulaValue(this.value);
    @override dynamic get rawValue => value;
    @override bool get isTruthy => value.isNotEmpty;
    @override bool get isError => false;
  }

  class BooleanFormulaValue extends FormulaValue {
    final bool value;
    const BooleanFormulaValue(this.value);
    @override dynamic get rawValue => value;
    @override bool get isTruthy => value;
    @override bool get isError => false;
  }

  class DateFormulaValue extends FormulaValue {
    final DateTime value;
    const DateFormulaValue(this.value);
    @override dynamic get rawValue => value;
    @override bool get isTruthy => true;
    @override bool get isError => false;
  }

  class NullFormulaValue extends FormulaValue {
    const NullFormulaValue();
    @override dynamic get rawValue => null;
    @override bool get isTruthy => false;
    @override bool get isError => false;
  }

  class ErrorFormulaValue extends FormulaValue {
    final String errorCode; // '#DIV/0!', '#CYCLE!', '#ERROR!'
    const ErrorFormulaValue(this.errorCode);
    @override dynamic get rawValue => errorCode;
    @override bool get isTruthy => false;
    @override bool get isError => true;
  }
  ```

---

#### File 6: `lib/features/workspace_database/domain/formula/formula_context.dart`
- **Purpose**: Interface for resolving property values, relation rows, and active call stack during evaluation.
- **Specification**:
  ```dart
  abstract class IFormulaContext {
    /// Retrieve cell value for the given property name or id on the current row
    Future<dynamic> getPropertyValue(String propertyName);

    /// Set of properties currently in active evaluation stack (for dynamic cycle detection)
    Set<String> get activeCallStack;

    /// Creates a child context with an added property on the active call stack
    IFormulaContext pushCallStack(String propertyName);

    /// Checks if a property is already on the call stack
    bool isPropertyInCallStack(String propertyName);
  }

  class MapFormulaContext implements IFormulaContext {
    final Map<String, dynamic> propertyValues;
    @override
    final Set<String> activeCallStack;

    MapFormulaContext({
      required this.propertyValues,
      Set<String>? activeCallStack,
    }) : activeCallStack = activeCallStack ?? <String>{};

    @override
    Future<dynamic> getPropertyValue(String propertyName) async {
      return propertyValues[propertyName];
    }

    @override
    bool isPropertyInCallStack(String propertyName) =>
        activeCallStack.contains(propertyName);

    @override
    IFormulaContext pushCallStack(String propertyName) {
      return MapFormulaContext(
        propertyValues: propertyValues,
        activeCallStack: {...activeCallStack, propertyName},
      );
    }
  }
  ```

---

#### File 7: `lib/features/workspace_database/domain/formula/formula_evaluator.dart`
- **Purpose**: Tree-walking AST evaluator executing arithmetic, comparison, logical, date, string, and rounding operations.
- **Built-in Functions Supported**:
  - `if(condition, thenExpr, elseExpr)`: Evaluates condition; conditionally evaluates only the matching branch.
  - `dateAdd(date, amount, unit)`: Adds quantity (`days`, `weeks`, `months`, `years`, `hours`, `minutes`) to date.
  - `dateBetween(date1, date2, unit)`: Computes signed difference between two dates in given unit.
  - `format(val)`: Formats any value to string.
  - `concat(arg1, arg2, ...)`: Variadic concatenation of strings.
  - `length(str)`: Length of string.
  - `round(n)`: Rounds number to nearest integer.
  - `ceil(n)`: Ceiling of number.
  - `floor(n)`: Floor of number.
- **Division by Zero & Cycle Handling**:
  - `left / 0` or `left % 0` immediately returns `FormulaValue.divZero()`.
  - When evaluating `PropertyRefNode`:
    - Checks `context.isPropertyInCallStack(propertyName)`. If true, returns `FormulaValue.cycle()`.
    - If property value is null, returns `FormulaValue.nullValue()`.
- **Class Signature**:
  ```dart
  class FormulaEvaluator implements FormulaVisitor<Future<FormulaValue>, IFormulaContext> {
    const FormulaEvaluator();

    Future<FormulaValue> evaluate(FormulaNode node, IFormulaContext context);

    @override
    Future<FormulaValue> visitLiteral(LiteralNode node, IFormulaContext context);

    @override
    Future<FormulaValue> visitPropertyRef(PropertyRefNode node, IFormulaContext context);

    @override
    Future<FormulaValue> visitUnaryOp(UnaryOpNode node, IFormulaContext context);

    @override
    Future<FormulaValue> visitBinaryOp(BinaryOpNode node, IFormulaContext context);

    @override
    Future<FormulaValue> visitFunctionCall(FunctionCallNode node, IFormulaContext context);
  }
  ```

---

#### File 8: `lib/features/workspace_database/domain/formula/dependency_graph.dart`
- **Purpose**: Directed dependency graph tracking cross-property and cross-formula references for static cycle detection and topological sorting.
- **Data Structure**:
  - `Map<String, Set<String>> _adjacencyList`: maps property node to set of dependent properties (edges $A \to B$ where $A$ depends on $B$).
- **Key Methods**:
  - `void addDependency(String property, String dependsOn)`
  - `void setPropertyDependencies(String property, Set<String> dependencies)`
  - `bool hasCycle()`: Detects if any circular dependency exists using 3-color DFS marking (`White = 0`, `Gray = 1`, `Black = 2`).
  - `List<String>? findCyclePath()`: Returns the exact cycle trace (e.g. `['Score', 'Bonus', 'Score']`) if a cycle exists.
  - `List<String> getTopologicalOrder()`: Produces topological ordering (Kahn's algorithm) for cascade updates. Throws `CircularDependencyException` if a cycle is present.
- **Specification**:
  ```dart
  class FormulaDependencyGraph {
    final Map<String, Set<String>> _dependencies = {}; // node -> outgoing edges (dependencies)

    void addProperty(String propertyId, Set<String> dependencies) {
      _dependencies[propertyId] = Set.from(dependencies);
    }

    void removeProperty(String propertyId) {
      _dependencies.remove(propertyId);
      for (final deps in _dependencies.values) {
        deps.remove(propertyId);
      }
    }

    bool hasCycle() => findCyclePath() != null;

    List<String>? findCyclePath() {
      final visited = <String, int>{}; // 0 = unvisited, 1 = visiting, 2 = visited
      final path = <String>[];

      for (final node in _dependencies.keys) {
        if (!visited.containsKey(node)) {
          final cycle = _dfsFindCycle(node, visited, path);
          if (cycle != null) return cycle;
        }
      }
      return null;
    }

    List<String>? _dfsFindCycle(String current, Map<String, int> visited, List<String> path) {
      visited[current] = 1;
      path.add(current);

      final neighbors = _dependencies[current] ?? {};
      for (final neighbor in neighbors) {
        if (visited[neighbor] == 1) {
          // Cycle found!
          final cycleStart = path.indexOf(neighbor);
          return path.sublist(cycleStart)..add(neighbor);
        } else if (!visited.containsKey(neighbor)) {
          final res = _dfsFindCycle(neighbor, visited, path);
          if (res != null) return res;
        }
      }

      path.removeLast();
      visited[current] = 2;
      return null;
    }

    List<String> getTopologicalOrder() {
      final inDegree = <String, int>{};
      for (final node in _dependencies.keys) {
        inDegree.putIfAbsent(node, () => 0);
        for (final dep in _dependencies[node]!) {
          inDegree[dep] = (inDegree[dep] ?? 0) + 1;
        }
      }

      final queue = inDegree.keys.where((k) => inDegree[k] == 0).toList();
      final order = <String>[];

      while (queue.isNotEmpty) {
        final current = queue.removeAt(0);
        order.add(current);

        for (final dep in _dependencies[current] ?? {}) {
          inDegree[dep] = inDegree[dep]! - 1;
          if (inDegree[dep] == 0) queue.add(dep);
        }
      }

      if (order.length < _dependencies.length) {
        throw CircularDependencyException('Cycle detected in formula dependencies');
      }
      return order;
    }
  }

  class CircularDependencyException implements Exception {
    final String message;
    CircularDependencyException(this.message);
  }
  ```

---

#### File 9: `lib/features/workspace_database/domain/rollup/rollup_function.dart`
- **Purpose**: Defines all 14 rollup aggregation functions required by Notion and HamPA specifications.
- **Specification**:
  ```dart
  enum RollupAggregation {
    countAll,         // Total count of all related items
    countValues,      // Count of items where target property is not empty
    countUnique,      // Count of distinct non-empty values
    countEmpty,       // Count of items where target property is empty/null
    countNotEmpty,    // Alias of countValues
    percentEmpty,     // Percentage of items where target is empty (0.0 - 100.0)
    percentNotEmpty,  // Percentage of items where target is not empty (0.0 - 100.0)
    sum,              // Numeric sum of all values
    average,          // Arithmetic mean of numeric values
    median,           // Median of numeric values
    min,              // Minimum numeric value
    max,              // Maximum numeric value
    range,            // Difference between max and min
    percentChecked,   // Percentage of boolean values that are true (0.0 - 100.0)
  }
  ```

---

#### File 10: `lib/features/workspace_database/domain/rollup/rollup_calculator.dart`
- **Purpose**: Pure computation engine that aggregates a list of dynamic target cell values according to `RollupAggregation`.
- **Algorithm Implementations**:
  1. `countAll`: `values.length`.
  2. `countValues`: `values.where((v) => v != null && v != '').length`.
  3. `countUnique`: `values.where((v) => v != null && v != '').toSet().length`.
  4. `countEmpty`: `values.where((v) => v == null || v == '').length`.
  5. `countNotEmpty`: same as `countValues`.
  6. `percentEmpty`: `countAll == 0 ? 0.0 : (countEmpty / countAll) * 100.0`.
  7. `percentNotEmpty`: `countAll == 0 ? 0.0 : (countNotEmpty / countAll) * 100.0`.
  8. `sum`: numeric values fold: `nums.isEmpty ? 0 : nums.fold<num>(0, (a, b) => a + b)`.
  9. `average`: `nums.isEmpty ? null : sum / nums.length`.
  10. `median`:
      - Sort numbers ascending.
      - If `nums.isEmpty`, return `null`.
      - If odd: `nums[n ~/ 2]`.
      - If even: `(nums[(n ~/ 2) - 1] + nums[n ~/ 2]) / 2.0`.
  11. `min`: `nums.isEmpty ? null : nums.reduce((a, b) => a < b ? a : b)`.
  12. `max`: `nums.isEmpty ? null : nums.reduce((a, b) => a > b ? a : b)`.
  13. `range`: `nums.length < 1 ? null : max - min`.
  14. `percentChecked`:
      - Extract all booleans: `bools = values.whereType<bool>().toList()`.
      - If `bools.isEmpty`, return `0.0` (prevents divide-by-zero per test `F11-B2`).
      - Return `(bools.where((b) => b).length / bools.length) * 100.0`.
- **Class Signature**:
  ```dart
  class RollupCalculator {
    static dynamic compute({
      required List<dynamic> values,
      required RollupAggregation aggregation,
    }) {
      switch (aggregation) {
        case RollupAggregation.countAll:
          return values.length;
        case RollupAggregation.countValues:
        case RollupAggregation.countNotEmpty:
          return values.where((v) => v != null && v != '').length;
        case RollupAggregation.countUnique:
          return values.where((v) => v != null && v != '').toSet().length;
        case RollupAggregation.countEmpty:
          return values.where((v) => v == null || v == '').length;
        case RollupAggregation.percentEmpty:
          if (values.isEmpty) return 0.0;
          final emptyCount = values.where((v) => v == null || v == '').length;
          return (emptyCount / values.length) * 100.0;
        case RollupAggregation.percentNotEmpty:
          if (values.isEmpty) return 0.0;
          final notEmptyCount = values.where((v) => v != null && v != '').length;
          return (notEmptyCount / values.length) * 100.0;
        case RollupAggregation.sum:
          final nums = values.whereType<num>().toList();
          return nums.fold<num>(0, (a, b) => a + b);
        case RollupAggregation.average:
          final nums = values.whereType<num>().toList();
          if (nums.isEmpty) return null;
          return nums.fold<num>(0, (a, b) => a + b) / nums.length;
        case RollupAggregation.median:
          final nums = values.whereType<num>().toList()..sort();
          if (nums.isEmpty) return null;
          final mid = nums.length ~/ 2;
          return nums.length.isOdd ? nums[mid] : (nums[mid - 1] + nums[mid]) / 2.0;
        case RollupAggregation.min:
          final nums = values.whereType<num>().toList();
          if (nums.isEmpty) return null;
          return nums.reduce((a, b) => a < b ? a : b);
        case RollupAggregation.max:
          final nums = values.whereType<num>().toList();
          if (nums.isEmpty) return null;
          return nums.reduce((a, b) => a > b ? a : b);
        case RollupAggregation.range:
          final nums = values.whereType<num>().toList();
          if (nums.isEmpty) return null;
          final min = nums.reduce((a, b) => a < b ? a : b);
          final max = nums.reduce((a, b) => a > b ? a : b);
          return max - min;
        case RollupAggregation.percentChecked:
          final bools = values.whereType<bool>().toList();
          if (bools.isEmpty) return 0.0;
          final checked = bools.where((b) => b).length;
          return (checked / bools.length) * 100.0;
      }
    }
  }
  ```

---

#### File 11: `lib/features/workspace_database/domain/rollup/rollup_evaluator.dart`
- **Purpose**: Coordinates relationship traversal from source row to target rows, extracts target property values, and delegates to `RollupCalculator`.
- **Specification**:
  ```dart
  abstract class IRollupDataSource {
    Future<List<String>> getRelatedRowIds(String rowId, String relationPropertyId);
    Future<List<dynamic>> getPropertyValuesForRows(List<String> rowIds, String targetPropertyId);
  }

  class RollupEvaluator {
    final IRollupDataSource dataSource;
    RollupEvaluator(this.dataSource);

    Future<dynamic> evaluate({
      required String rowId,
      required String relationPropertyId,
      required String targetPropertyId,
      required RollupAggregation aggregation,
    }) async {
      final relatedRowIds = await dataSource.getRelatedRowIds(rowId, relationPropertyId);
      if (relatedRowIds.isEmpty) {
        return RollupCalculator.compute(values: [], aggregation: aggregation);
      }
      final targetValues = await dataSource.getPropertyValuesForRows(relatedRowIds, targetPropertyId);
      return RollupCalculator.compute(values: targetValues, aggregation: aggregation);
    }
  }
  ```

---

### Detailed Unit Test Suite Blueprint

#### Test File 1: `test/unit/formula/formula_lexer_test.dart`
- Tests to implement:
  1. `Tokenizes integer and decimal numbers`: `42`, `3.14159`, `0.5`, `1000`.
  2. `Tokenizes double-quoted strings with escape sequences`: `"hello \"world\""`, `"line1\nline2"`.
  3. `Tokenizes single-quoted strings`: `'simple string'`.
  4. `Tokenizes all arithmetic operators`: `+`, `-`, `*`, `/`, `%`.
  5. `Tokenizes all comparison operators`: `==`, `!=`, `<`, `<=`, `>`, `>=`.
  6. `Tokenizes all logical operators`: `&&`, `||`, `!`.
  7. `Tokenizes built-in function keywords`: `if`, `dateAdd`, `dateBetween`, `format`, `concat`, `length`, `round`, `ceil`, `floor`.
  8. `Tokenizes prop property accessor`: `prop("Price")` -> `prop`, `(`, `"Price"`, `)`.
  9. `Handles whitespace and newlines cleanly`.
  10. `Throws FormulaLexerException on unterminated strings`.

#### Test File 2: `test/unit/formula/formula_parser_test.dart`
- Tests to implement:
  1. `Parses numeric and string literals into LiteralNode`.
  2. `Parses prop("Name") into PropertyRefNode("Name")`.
  3. `Respects multiplication precedence over addition`: `2 + 3 * 4` -> `BinaryOpNode(+, 2, BinaryOpNode(*, 3, 4))`.
  4. `Respects parentheses overriding precedence`: `(2 + 3) * 4` -> `BinaryOpNode(*, BinaryOpNode(+, 2, 3), 4)`.
  5. `Parses comparison and equality chains`: `prop("Score") >= 50 && prop("Score") < 100`.
  6. `Parses unary operators`: `-10`, `!true`.
  7. `Parses function calls with multiple arguments`: `if(prop("Done"), "Finished", "Pending")`.
  8. `Parses nested function calls`: `concat("Score: ", format(round(prop("Val"))))`.
  9. `Parses bare identifier as fallback literal`: `'ACTIVE'` parses without crash.
  10. `Extracts all property references from parsed AST`: `ast.extractPropertyReferences()` returns `{"A", "B", "C"}`.
  11. `Throws FormulaParseException on missing closing parenthesis or invalid syntax`.

#### Test File 3: `test/unit/formula/formula_evaluator_test.dart`
- Tests to implement:
  1. `Evaluates constant math`: `10 + 25` = `35.0`, `100 - 45` = `55.0`, `6 * 7` = `42.0`, `20 / 4` = `5.0`, `14 % 3` = `2.0`.
  2. `Evaluates property lookup`: `prop("Hours") * 60` with `Hours = 4` = `240.0`.
  3. `Evaluates multi-property math`: `prop("Midterm") + prop("Final")` = `90.0`.
  4. `Returns null on unpopulated / null referenced property`: `prop("Missing") + 10` = `null`.
  5. `Returns division by zero error`: `100 / 0` = `'#DIV/0!'`, `50 % 0` = `'#DIV/0!'`.
  6. `Evaluates negative numbers`: `50 - 80` = `-30.0`.
  7. `Evaluates large numbers without overflow`: `1000000 * 2000` = `2000000000.0`.
  8. `Evaluates string concatenation via +`: `"Hello " + "World"` = `"Hello World"`.
  9. `Evaluates string + number concatenation`: `"Score: " + 98` = `"Score: 98"`.
  10. `Evaluates if() conditional with true branch`: `if(10 > 5, "yes", "no")` = `"yes"`.
  11. `Evaluates if() conditional with false branch`: `if(10 < 5, "yes", "no")` = `"no"`.
  12. `Lazily evaluates if() branches (short-circuiting)`: does not evaluate divide-by-zero in untaken branch: `if(true, "safe", 1 / 0)` = `"safe"`.
  13. `Evaluates round, ceil, floor`: `round(3.6)` = `4`, `floor(3.6)` = `3`, `ceil(3.2)` = `4`.
  14. `Evaluates concat and length`: `concat("A", "B", "C")` = `"ABC"`, `length("HamPA")` = `5`.
  15. `Evaluates dateAdd with days and months`: `dateAdd("2026-10-16", 5, "days")` = `2026-10-21`.
  16. `Evaluates dateBetween`: `dateBetween("2026-10-25", "2026-10-20", "days")` = `5`.
  17. `Evaluates boolean logic and short-circuiting`: `false && (1 / 0 == 0)` = `false` (no error).

#### Test File 4: `test/unit/formula/dependency_graph_test.dart`
- Tests to implement:
  1. `Detects direct self-cycle`: `A -> A` returns `true` and path `['A', 'A']`.
  2. `Detects 2-hop circular dependency`: `A -> B` and `B -> A` returns `true`.
  3. `Detects 3-hop circular dependency`: `A -> B -> C -> A` returns `true`.
  4. `Permits valid Directed Acyclic Graph (DAG) without false positives`: `A -> B`, `A -> C`, `B -> D`, `C -> D` returns `false`.
  5. `Computes correct topological sort order for DAG`: dependencies evaluated before dependents.
  6. `Evaluator returns #CYCLE! badge on active call stack re-entry`: matches Tier 2 test `F10-B1`.
  7. `Handles deep dependency chain (10 levels) cleanly`.

#### Test File 5: `test/unit/formula/rollup_calculator_test.dart`
- Tests to implement (all 14 functions + edge cases):
  1. `countAll counts all items including nulls`: `[1, null, "a"]` -> `3`.
  2. `countValues counts only non-null and non-empty items`: `[1, null, "", "b"]` -> `2`.
  3. `countUnique counts distinct non-empty values`: `[1, 2, 2, 3, null]` -> `3`.
  4. `countEmpty counts nulls and empty strings`: `[1, null, "", "b"]` -> `2`.
  5. `countNotEmpty returns same as countValues`.
  6. `percentEmpty calculates percentage of empty items`: `[null, 1, 2, null]` -> `50.0`.
  7. `percentNotEmpty calculates percentage of populated items`: `[null, 1, 2, null]` -> `50.0`.
  8. `sum sums numeric values`: `[10, 20, 30]` -> `60`.
  9. `sum ignores non-numeric values gracefully`: `[10, null, "x", 20]` -> `30`.
  10. `average computes arithmetic mean`: `[80, 90]` -> `85.0`.
  11. `average returns null on empty list`: `[]` -> `null`.
  12. `median computes odd list median`: `[10, 50, 20]` -> `20`.
  13. `median computes even list median`: `[10, 20, 30, 40]` -> `25.0`.
  14. `min and max find extreme values`: `[12, 89, 45]` -> min `12`, max `89`.
  15. `range computes difference between max and min`: `[10, 50]` -> `40`.
  16. `percentChecked calculates boolean true percentage`: `[true, true, true, false]` -> `75.0`.
  17. `percentChecked returns 0.0 on empty list without divide by zero`: `[]` -> `0.0`.
  18. `Empty list defaults match E2E contracts`: `sum` = `0`, `average` = `null`, `min` = `null`, `max` = `null`, `percentChecked` = `0.0`.

---

## 5. Verification Method

To independently verify the architecture and subsequent implementation:
1. **Source File Compilation & Linter Verification**:
   ```powershell
   flutter analyze lib/features/workspace_database/domain/formula lib/features/workspace_database/domain/rollup
   ```
   *Expected Result*: 0 errors, 0 warnings.
2. **Dedicated Unit Test Suite Execution**:
   ```powershell
   flutter test test/unit/formula/
   ```
   *Expected Result*: All 5 test suites pass with 100% green assertions across 60+ test cases.
3. **E2E Feature & Boundary Regression Verification**:
   ```powershell
   flutter test test/e2e/tier1_feature_coverage/f08_f16_relational_database_test.dart
   flutter test test/e2e/tier2_boundary_corner/f08_f16_relational_boundary_test.dart
   ```
   *Expected Result*: All Tier 1 and Tier 2 tests for F10 (Formula) and F11 (Rollup) pass cleanly, specifically verifying:
   - `F10-1` through `F10-5`: Basic arithmetic, property lookups, and missing values.
   - `F10-B1`: `#CYCLE!` circular reference error badge.
   - `F10-B2`: `#DIV/0!` divide-by-zero error badge.
   - `F11-1` through `F11-5`: Rollup sum, average, count, percent checked, min/max.
   - `F11-B1` through `F11-B5`: Boundary conditions for empty relations, zero items, and single-item lists.
4. **Invalidation Conditions**:
   - Any stack overflow or infinite recursion when circular formulas are defined (`A -> B -> A`).
   - Unhandled division by zero returning `double.infinity` or throwing unhandled exceptions instead of `#DIV/0!`.
   - Any failure to distinguish between empty collections (yielding `null` for `average`/`min`/`max` and `0` for `sum`/`percentChecked`).
