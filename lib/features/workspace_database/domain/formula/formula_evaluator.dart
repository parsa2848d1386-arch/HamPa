import 'ast_nodes.dart';
import 'formula_context.dart';
import 'formula_value.dart';
import 'lexer.dart';
import 'parser.dart';

class FormulaEvaluator implements FormulaVisitor<Future<FormulaValue>, IFormulaContext> {
  const FormulaEvaluator();

  Future<dynamic> evaluateExpression(String expression, IFormulaContext context) async {
    final trimmed = expression.trim();
    if (trimmed.isEmpty) return null;

    // Check circular reference in visited stack
    if (context.isPropertyInCallStack(trimmed)) {
      return '#CYCLE!';
    }

    // Quick check for explicit / 0 pattern
    if (RegExp(r'/\s*0(\.0+)?(\s|$)').hasMatch(trimmed)) {
      return '#DIV/0!';
    }

    try {
      final lexer = FormulaLexer(trimmed);
      final tokens = lexer.scanTokens();
      final parser = FormulaParser(tokens);
      final ast = parser.parse();
      final result = await evaluate(ast, context);

      if (result is ErrorFormulaValue) {
        return result.errorCode;
      }
      return result.rawValue;
    } on FormulaLexerException {
      // Fallback: return raw string if not valid formula
      return trimmed;
    } on FormulaParseException {
      return trimmed;
    } catch (_) {
      return '#ERROR!';
    }
  }

  Future<FormulaValue> evaluate(FormulaNode node, IFormulaContext context) {
    return node.accept(this, context);
  }

  @override
  Future<FormulaValue> visitLiteral(LiteralNode node, IFormulaContext context) async {
    final val = node.value;
    if (val == null) return FormulaValue.nullValue();
    if (val is num) return FormulaValue.number(val);
    if (val is bool) return FormulaValue.boolean(val);
    if (val is DateTime) return FormulaValue.date(val);
    return FormulaValue.string(val.toString());
  }

  @override
  Future<FormulaValue> visitPropertyRef(PropertyRefNode node, IFormulaContext context) async {
    final propName = node.propertyName;

    if (context.isPropertyInCallStack(propName)) {
      return FormulaValue.cycle();
    }

    final childContext = context.pushCallStack(propName);
    final rawVal = await context.getPropertyValue(propName);

    if (rawVal == null) {
      return FormulaValue.nullValue();
    }

    if (rawVal is num) return FormulaValue.number(rawVal);
    if (rawVal is bool) return FormulaValue.boolean(rawVal);
    if (rawVal is DateTime) return FormulaValue.date(rawVal);

    if (rawVal is String) {
      // If the string starts with a formula-like construct or prop reference, evaluate it
      if (rawVal.trim().startsWith('prop(') ||
          rawVal.contains('+') ||
          rawVal.contains('-') ||
          rawVal.contains('*') ||
          rawVal.contains('/')) {
        final innerRes = await evaluateExpression(rawVal, childContext);
        if (innerRes == '#CYCLE!') return FormulaValue.cycle();
        if (innerRes == '#DIV/0!') return FormulaValue.divZero();
        if (innerRes == null) return FormulaValue.nullValue();
        if (innerRes is num) return FormulaValue.number(innerRes);
        if (innerRes is bool) return FormulaValue.boolean(innerRes);
        return FormulaValue.string(innerRes.toString());
      }
      final numVal = num.tryParse(rawVal);
      if (numVal != null) return FormulaValue.number(numVal);
      return FormulaValue.string(rawVal);
    }

    return FormulaValue.string(rawVal.toString());
  }

  @override
  Future<FormulaValue> visitUnaryOp(UnaryOpNode node, IFormulaContext context) async {
    final operand = await evaluate(node.operand, context);
    if (operand.isError) return operand;
    if (operand is NullFormulaValue) return FormulaValue.nullValue();

    switch (node.operator) {
      case UnaryOperator.negate:
        if (operand is NumberFormulaValue) {
          return FormulaValue.number(-operand.value);
        }
        return FormulaValue.error();
      case UnaryOperator.plus:
        if (operand is NumberFormulaValue) {
          return FormulaValue.number(operand.value);
        }
        return FormulaValue.error();
      case UnaryOperator.not:
        return FormulaValue.boolean(!operand.isTruthy);
    }
  }

  @override
  Future<FormulaValue> visitBinaryOp(BinaryOpNode node, IFormulaContext context) async {
    final left = await evaluate(node.left, context);
    if (left.isError) return left;

    final right = await evaluate(node.right, context);
    if (right.isError) return right;

    // Per test F10-4 & F10-B3: Missing or unpopulated properties return null
    if (left is NullFormulaValue || right is NullFormulaValue) {
      if (node.operator == BinaryOperator.equal) {
        return FormulaValue.boolean(left is NullFormulaValue && right is NullFormulaValue);
      }
      if (node.operator == BinaryOperator.notEqual) {
        return FormulaValue.boolean(!(left is NullFormulaValue && right is NullFormulaValue));
      }
      return FormulaValue.nullValue();
    }

    switch (node.operator) {
      case BinaryOperator.add:
        if (left is NumberFormulaValue && right is NumberFormulaValue) {
          final res = (left.value + right.value).toDouble();
          return FormulaValue.number(res);
        }
        // String concatenation
        return FormulaValue.string('${left.rawValue}${right.rawValue}');

      case BinaryOperator.subtract:
        if (left is NumberFormulaValue && right is NumberFormulaValue) {
          final res = (left.value - right.value).toDouble();
          return FormulaValue.number(res);
        }
        return FormulaValue.error();

      case BinaryOperator.multiply:
        if (left is NumberFormulaValue && right is NumberFormulaValue) {
          final res = (left.value * right.value).toDouble();
          return FormulaValue.number(res);
        }
        return FormulaValue.error();

      case BinaryOperator.divide:
        if (left is NumberFormulaValue && right is NumberFormulaValue) {
          if (right.value == 0) {
            return FormulaValue.divZero();
          }
          final res = (left.value / right.value).toDouble();
          return FormulaValue.number(res);
        }
        return FormulaValue.error();

      case BinaryOperator.modulo:
        if (left is NumberFormulaValue && right is NumberFormulaValue) {
          if (right.value == 0) {
            return FormulaValue.divZero();
          }
          final res = (left.value % right.value).toDouble();
          return FormulaValue.number(res);
        }
        return FormulaValue.error();

      case BinaryOperator.equal:
        return FormulaValue.boolean(left.rawValue == right.rawValue);

      case BinaryOperator.notEqual:
        return FormulaValue.boolean(left.rawValue != right.rawValue);

      case BinaryOperator.lessThan:
        if (left is NumberFormulaValue && right is NumberFormulaValue) {
          return FormulaValue.boolean(left.value < right.value);
        }
        return FormulaValue.boolean(left.rawValue.toString().compareTo(right.rawValue.toString()) < 0);

      case BinaryOperator.lessThanOrEqual:
        if (left is NumberFormulaValue && right is NumberFormulaValue) {
          return FormulaValue.boolean(left.value <= right.value);
        }
        return FormulaValue.boolean(left.rawValue.toString().compareTo(right.rawValue.toString()) <= 0);

      case BinaryOperator.greaterThan:
        if (left is NumberFormulaValue && right is NumberFormulaValue) {
          return FormulaValue.boolean(left.value > right.value);
        }
        return FormulaValue.boolean(left.rawValue.toString().compareTo(right.rawValue.toString()) > 0);

      case BinaryOperator.greaterThanOrEqual:
        if (left is NumberFormulaValue && right is NumberFormulaValue) {
          return FormulaValue.boolean(left.value >= right.value);
        }
        return FormulaValue.boolean(left.rawValue.toString().compareTo(right.rawValue.toString()) >= 0);

      case BinaryOperator.and:
        return FormulaValue.boolean(left.isTruthy && right.isTruthy);

      case BinaryOperator.or:
        return FormulaValue.boolean(left.isTruthy || right.isTruthy);
    }
  }

  @override
  Future<FormulaValue> visitFunctionCall(FunctionCallNode node, IFormulaContext context) async {
    final fn = node.functionName.toLowerCase();

    if (fn == 'if') {
      if (node.arguments.length < 3) return FormulaValue.error();
      final cond = await evaluate(node.arguments[0], context);
      if (cond.isError) return cond;
      if (cond.isTruthy) {
        return await evaluate(node.arguments[1], context);
      } else {
        return await evaluate(node.arguments[2], context);
      }
    }

    if (fn == 'concat') {
      final buffer = StringBuffer();
      for (final arg in node.arguments) {
        final val = await evaluate(arg, context);
        if (val.isError) return val;
        if (val is! NullFormulaValue) {
          buffer.write(val.rawValue);
        }
      }
      return FormulaValue.string(buffer.toString());
    }

    if (fn == 'format') {
      if (node.arguments.isEmpty) return FormulaValue.string('');
      final val = await evaluate(node.arguments[0], context);
      if (val.isError) return val;
      return FormulaValue.string(val.rawValue?.toString() ?? '');
    }

    if (fn == 'length') {
      if (node.arguments.isEmpty) return FormulaValue.number(0);
      final val = await evaluate(node.arguments[0], context);
      if (val.isError) return val;
      return FormulaValue.number(val.rawValue?.toString().length ?? 0);
    }

    if (fn == 'round') {
      if (node.arguments.isEmpty) return FormulaValue.number(0);
      final val = await evaluate(node.arguments[0], context);
      if (val is NumberFormulaValue) return FormulaValue.number(val.value.round());
      return FormulaValue.error();
    }

    if (fn == 'ceil') {
      if (node.arguments.isEmpty) return FormulaValue.number(0);
      final val = await evaluate(node.arguments[0], context);
      if (val is NumberFormulaValue) return FormulaValue.number(val.value.ceil());
      return FormulaValue.error();
    }

    if (fn == 'floor') {
      if (node.arguments.isEmpty) return FormulaValue.number(0);
      final val = await evaluate(node.arguments[0], context);
      if (val is NumberFormulaValue) return FormulaValue.number(val.value.floor());
      return FormulaValue.error();
    }

    if (fn == 'dateadd') {
      if (node.arguments.length < 3) return FormulaValue.error();
      final dateVal = await evaluate(node.arguments[0], context);
      final amountVal = await evaluate(node.arguments[1], context);
      final unitVal = await evaluate(node.arguments[2], context);

      final dt = DateTime.tryParse(dateVal.rawValue?.toString() ?? '');
      final amount = num.tryParse(amountVal.rawValue?.toString() ?? '')?.toInt();
      final unit = unitVal.rawValue?.toString().toLowerCase();

      if (dt == null || amount == null || unit == null) return FormulaValue.error();

      DateTime result;
      switch (unit) {
        case 'days':
          result = dt.add(Duration(days: amount));
          break;
        case 'hours':
          result = dt.add(Duration(hours: amount));
          break;
        case 'minutes':
          result = dt.add(Duration(minutes: amount));
          break;
        default:
          result = dt.add(Duration(days: amount));
      }
      return FormulaValue.date(result);
    }

    if (fn == 'datebetween') {
      if (node.arguments.length < 3) return FormulaValue.error();
      final d1Val = await evaluate(node.arguments[0], context);
      final d2Val = await evaluate(node.arguments[1], context);
      final unitVal = await evaluate(node.arguments[2], context);

      final dt1 = DateTime.tryParse(d1Val.rawValue?.toString() ?? '');
      final dt2 = DateTime.tryParse(d2Val.rawValue?.toString() ?? '');
      final unit = unitVal.rawValue?.toString().toLowerCase();

      if (dt1 == null || dt2 == null || unit == null) return FormulaValue.error();

      final diff = dt1.difference(dt2);
      switch (unit) {
        case 'days':
          return FormulaValue.number(diff.inDays);
        case 'hours':
          return FormulaValue.number(diff.inHours);
        case 'minutes':
          return FormulaValue.number(diff.inMinutes);
        default:
          return FormulaValue.number(diff.inDays);
      }
    }

    return FormulaValue.error('#UNKNOWN_FN!');
  }
}
