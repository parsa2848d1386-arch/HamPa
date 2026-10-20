enum BinaryOperator {
  add,
  subtract,
  multiply,
  divide,
  modulo,
  equal,
  notEqual,
  lessThan,
  lessThanOrEqual,
  greaterThan,
  greaterThanOrEqual,
  and,
  or,
}

enum UnaryOperator {
  negate,
  plus,
  not,
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

  @override
  String toString() => 'LiteralNode($value)';
}

class PropertyRefNode extends FormulaNode {
  final String propertyName;
  const PropertyRefNode(this.propertyName);

  @override
  Set<String> extractPropertyReferences() => {propertyName};

  @override
  R accept<R, C>(FormulaVisitor<R, C> visitor, C context) =>
      visitor.visitPropertyRef(this, context);

  @override
  String toString() => 'PropertyRefNode("$propertyName")';
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

  @override
  String toString() => 'UnaryOpNode($operator, $operand)';
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

  @override
  String toString() => 'BinaryOpNode($operator, $left, $right)';
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

  @override
  String toString() => 'FunctionCallNode($functionName, $arguments)';
}

abstract class FormulaVisitor<R, C> {
  R visitLiteral(LiteralNode node, C context);
  R visitPropertyRef(PropertyRefNode node, C context);
  R visitUnaryOp(UnaryOpNode node, C context);
  R visitBinaryOp(BinaryOpNode node, C context);
  R visitFunctionCall(FunctionCallNode node, C context);
}
