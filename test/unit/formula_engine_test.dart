import 'package:flutter_test/flutter_test.dart';
import 'package:hampa/features/workspace_database/domain/formula/token.dart';
import 'package:hampa/features/workspace_database/domain/formula/lexer.dart';
import 'package:hampa/features/workspace_database/domain/formula/parser.dart';
import 'package:hampa/features/workspace_database/domain/formula/formula_evaluator.dart';
import 'package:hampa/features/workspace_database/domain/formula/formula_context.dart';
import 'package:hampa/features/workspace_database/domain/formula/dependency_graph.dart';
import 'package:hampa/features/workspace_database/domain/formula/ast_nodes.dart';

void main() {
  group('Formula Engine Unit Tests', () {
    const evaluator = FormulaEvaluator();

    group('Lexer', () {
      test('Tokenizes numbers, strings, and operators', () {
        final lexer = FormulaLexer('prop("Hours") * 60 + 15.5');
        final tokens = lexer.scanTokens();

        expect(tokens.any((t) => t.type == TokenType.prop), isTrue);
        expect(tokens.any((t) => t.type == TokenType.string && t.literal == 'Hours'), isTrue);
        expect(tokens.any((t) => t.type == TokenType.star), isTrue);
        expect(tokens.any((t) => t.type == TokenType.number && t.literal == 60), isTrue);
        expect(tokens.any((t) => t.type == TokenType.plus), isTrue);
        expect(tokens.any((t) => t.type == TokenType.number && t.literal == 15.5), isTrue);
      });

      test('Tokenizes comparison and logical operators', () {
        final lexer = FormulaLexer('a == b && c != d || e <= f');
        final tokens = lexer.scanTokens();

        expect(tokens.map((t) => t.type), containsAll([
          TokenType.equalEqual,
          TokenType.andAnd,
          TokenType.bangEqual,
          TokenType.orOr,
          TokenType.lessEqual,
        ]));
      });
    });

    group('Parser', () {
      test('Respects operator precedence: multiplication before addition', () {
        final lexer = FormulaLexer('2 + 3 * 4');
        final tokens = lexer.scanTokens();
        final parser = FormulaParser(tokens);
        final ast = parser.parse();

        expect(ast, isA<BinaryOpNode>());
        final bin = ast as BinaryOpNode;
        expect(bin.operator, equals(BinaryOperator.add));
        expect(bin.left, isA<LiteralNode>());
        expect(bin.right, isA<BinaryOpNode>());
        expect((bin.right as BinaryOpNode).operator, equals(BinaryOperator.multiply));
      });

      test('Respects parentheses overriding precedence', () {
        final lexer = FormulaLexer('(2 + 3) * 4');
        final tokens = lexer.scanTokens();
        final parser = FormulaParser(tokens);
        final ast = parser.parse();

        expect(ast, isA<BinaryOpNode>());
        final bin = ast as BinaryOpNode;
        expect(bin.operator, equals(BinaryOperator.multiply));
        expect(bin.left, isA<BinaryOpNode>());
        expect((bin.left as BinaryOpNode).operator, equals(BinaryOperator.add));
      });
    });

    group('Evaluator Arithmetic & Edge Cases', () {
      test('F10-1: Simple addition 10 + 25 evaluates to 35.0', () async {
        final context = MapFormulaContext(propertyValues: {});
        final res = await evaluator.evaluateExpression('10 + 25', context);
        expect(res, equals(35.0));
      });

      test('F10-2: prop("Hours") * 60 evaluates to 240.0', () async {
        final context = MapFormulaContext(propertyValues: {'Hours': 4});
        final res = await evaluator.evaluateExpression('prop("Hours") * 60', context);
        expect(res, equals(240.0));
      });

      test('F10-3: prop("Midterm") + prop("Final") evaluates to 90.0', () async {
        final context = MapFormulaContext(propertyValues: {'Midterm': 40, 'Final': 50});
        final res = await evaluator.evaluateExpression('prop("Midterm") + prop("Final")', context);
        expect(res, equals(90.0));
      });

      test('F10-4 & F10-B3: Missing property returns null', () async {
        final context = MapFormulaContext(propertyValues: {});
        final res = await evaluator.evaluateExpression('prop("MissingVal") + 10', context);
        expect(res, isNull);
      });

      test('F10-5: Bare identifier returns string literal', () async {
        final context = MapFormulaContext(propertyValues: {});
        final res = await evaluator.evaluateExpression('ACTIVE', context);
        expect(res, equals('ACTIVE'));
      });

      test('F10-B1: Circular dependency returns #CYCLE!', () async {
        final context = MapFormulaContext(
          propertyValues: {'Score': 'prop("Bonus")', 'Bonus': 'prop("Score")'},
          activeCallStack: {'Score'},
        );
        final res = await evaluator.evaluateExpression('prop("Score") + 10', context);
        expect(res, equals('#CYCLE!'));
      });

      test('F10-B2: Division by zero returns #DIV/0!', () async {
        final context = MapFormulaContext(propertyValues: {});
        final res1 = await evaluator.evaluateExpression('100 / 0', context);
        expect(res1, equals('#DIV/0!'));

        final res2 = await evaluator.evaluateExpression('50 /0', context);
        expect(res2, equals('#DIV/0!'));
      });

      test('F10-B4: Negative numbers: 50 - 80 evaluates to -30.0', () async {
        final context = MapFormulaContext(propertyValues: {});
        final res = await evaluator.evaluateExpression('50 - 80', context);
        expect(res, equals(-30.0));
      });

      test('F10-B5: Large numbers: 1000000 * 2000 evaluates to 2000000000.0 without overflow', () async {
        final context = MapFormulaContext(propertyValues: {});
        final res = await evaluator.evaluateExpression('1000000 * 2000', context);
        expect(res, equals(2000000000.0));
      });

      test('Built-in function if, concat, length, round', () async {
        final context = MapFormulaContext(propertyValues: {'Score': 85});

        final resIf = await evaluator.evaluateExpression('if(prop("Score") >= 50, "Pass", "Fail")', context);
        expect(resIf, equals('Pass'));

        final resConcat = await evaluator.evaluateExpression('concat("Grade: ", "A")', context);
        expect(resConcat, equals('Grade: A'));

        final resLen = await evaluator.evaluateExpression('length("HamPA")', context);
        expect(resLen, equals(5));

        final resRound = await evaluator.evaluateExpression('round(4.6)', context);
        expect(resRound, equals(5));
      });
    });

    group('DependencyGraph', () {
      test('Detects direct cycle A -> B -> A', () {
        final graph = FormulaDependencyGraph();
        graph.addProperty('A', {'B'});
        graph.addProperty('B', {'A'});

        expect(graph.hasCycle(), isTrue);
        expect(graph.findCyclePath(), isNotNull);
        expect(() => graph.getTopologicalOrder(), throwsA(isA<CircularDependencyException>()));
      });

      test('Produces valid topological order on acyclic graph', () {
        final graph = FormulaDependencyGraph();
        graph.addProperty('Hours', {});
        graph.addProperty('Rate', {});
        graph.addProperty('Pay', {'Hours', 'Rate'});

        expect(graph.hasCycle(), isFalse);
        final order = graph.getTopologicalOrder();
        expect(order.indexOf('Pay'), greaterThan(order.indexOf('Hours')));
        expect(order.indexOf('Pay'), greaterThan(order.indexOf('Rate')));
      });
    });
  });
}
