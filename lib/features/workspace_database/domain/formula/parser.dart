import 'token.dart';
import 'ast_nodes.dart';

class FormulaParseException implements Exception {
  final String message;
  final Token? token;
  FormulaParseException(this.message, [this.token]);
  @override
  String toString() => 'FormulaParseException: $message at ${token?.lexeme}';
}

class FormulaParser {
  final List<Token> tokens;
  int _current = 0;

  FormulaParser(this.tokens);

  FormulaNode parse() {
    if (tokens.isEmpty || _peek().type == TokenType.eof) {
      return const LiteralNode(null);
    }
    return _expression();
  }

  FormulaNode _expression() {
    return _logicalOr();
  }

  FormulaNode _logicalOr() {
    var expr = _logicalAnd();

    while (_match([TokenType.orOr])) {
      final right = _logicalAnd();
      expr = BinaryOpNode(BinaryOperator.or, expr, right);
    }

    return expr;
  }

  FormulaNode _logicalAnd() {
    var expr = _equality();

    while (_match([TokenType.andAnd])) {
      final right = _equality();
      expr = BinaryOpNode(BinaryOperator.and, expr, right);
    }

    return expr;
  }

  FormulaNode _equality() {
    var expr = _comparison();

    while (_match([TokenType.equalEqual, TokenType.bangEqual])) {
      final opToken = _previous();
      final op = opToken.type == TokenType.equalEqual
          ? BinaryOperator.equal
          : BinaryOperator.notEqual;
      final right = _comparison();
      expr = BinaryOpNode(op, expr, right);
    }

    return expr;
  }

  FormulaNode _comparison() {
    var expr = _term();

    while (_match([TokenType.greater, TokenType.greaterEqual, TokenType.less, TokenType.lessEqual])) {
      final opToken = _previous();
      final BinaryOperator op;
      switch (opToken.type) {
        case TokenType.greater:
          op = BinaryOperator.greaterThan;
          break;
        case TokenType.greaterEqual:
          op = BinaryOperator.greaterThanOrEqual;
          break;
        case TokenType.less:
          op = BinaryOperator.lessThan;
          break;
        case TokenType.lessEqual:
          op = BinaryOperator.lessThanOrEqual;
          break;
        default:
          throw FormulaParseException('Unexpected operator', opToken);
      }
      final right = _term();
      expr = BinaryOpNode(op, expr, right);
    }

    return expr;
  }

  FormulaNode _term() {
    var expr = _factor();

    while (_match([TokenType.plus, TokenType.minus])) {
      final opToken = _previous();
      final op = opToken.type == TokenType.plus
          ? BinaryOperator.add
          : BinaryOperator.subtract;
      final right = _factor();
      expr = BinaryOpNode(op, expr, right);
    }

    return expr;
  }

  FormulaNode _factor() {
    var expr = _unary();

    while (_match([TokenType.slash, TokenType.star, TokenType.percent])) {
      final opToken = _previous();
      final BinaryOperator op;
      switch (opToken.type) {
        case TokenType.slash:
          op = BinaryOperator.divide;
          break;
        case TokenType.star:
          op = BinaryOperator.multiply;
          break;
        case TokenType.percent:
          op = BinaryOperator.modulo;
          break;
        default:
          throw FormulaParseException('Unexpected operator', opToken);
      }
      final right = _unary();
      expr = BinaryOpNode(op, expr, right);
    }

    return expr;
  }

  FormulaNode _unary() {
    if (_match([TokenType.bang, TokenType.minus, TokenType.plus])) {
      final opToken = _previous();
      final UnaryOperator op;
      switch (opToken.type) {
        case TokenType.bang:
          op = UnaryOperator.not;
          break;
        case TokenType.minus:
          op = UnaryOperator.negate;
          break;
        case TokenType.plus:
          op = UnaryOperator.plus;
          break;
        default:
          throw FormulaParseException('Unexpected unary operator', opToken);
      }
      final right = _unary();
      return UnaryOpNode(op, right);
    }

    return _primary();
  }

  FormulaNode _primary() {
    if (_match([TokenType.boolean, TokenType.number, TokenType.string])) {
      return LiteralNode(_previous().literal);
    }

    if (_match([TokenType.nullLiteral])) {
      return const LiteralNode(null);
    }

    if (_match([TokenType.prop])) {
      return _propReference();
    }

    // Function calls
    if (_match([
      TokenType.fnIf,
      TokenType.dateAdd,
      TokenType.dateBetween,
      TokenType.format,
      TokenType.concat,
      TokenType.length,
      TokenType.round,
      TokenType.ceil,
      TokenType.floor,
    ])) {
      final fnToken = _previous();
      return _functionCall(fnToken.lexeme);
    }

    if (_match([TokenType.identifier])) {
      final nameToken = _previous();
      if (_check(TokenType.leftParen)) {
        return _functionCall(nameToken.lexeme);
      }
      // Bare identifier without parentheses: fallback to literal string (e.g. 'ACTIVE')
      return LiteralNode(nameToken.lexeme);
    }

    if (_match([TokenType.leftParen])) {
      final expr = _expression();
      _consume(TokenType.rightParen, "Expect ')' after expression.");
      return expr;
    }

    throw FormulaParseException('Unexpected token: ${_peek().lexeme}', _peek());
  }

  FormulaNode _propReference() {
    _consume(TokenType.leftParen, "Expect '(' after 'prop'.");
    final nameToken = _advance();
    if (nameToken.type != TokenType.string && nameToken.type != TokenType.identifier) {
      throw FormulaParseException("Expect property name inside prop('...').", nameToken);
    }
    _consume(TokenType.rightParen, "Expect ')' after property name.");
    final propName = nameToken.literal?.toString() ?? nameToken.lexeme;
    return PropertyRefNode(propName);
  }

  FormulaNode _functionCall(String functionName) {
    _consume(TokenType.leftParen, "Expect '(' after function name '$functionName'.");
    final args = <FormulaNode>[];
    if (!_check(TokenType.rightParen)) {
      do {
        args.add(_expression());
      } while (_match([TokenType.comma]));
    }
    _consume(TokenType.rightParen, "Expect ')' after function arguments.");
    return FunctionCallNode(functionName, args);
  }

  bool _match(List<TokenType> types) {
    for (final type in types) {
      if (_check(type)) {
        _advance();
        return true;
      }
    }
    return false;
  }

  bool _check(TokenType type) {
    if (_isAtEnd) return false;
    return _peek().type == type;
  }

  Token _advance() {
    if (!_isAtEnd) _current++;
    return _previous();
  }

  bool get _isAtEnd => _peek().type == TokenType.eof;

  Token _peek() => tokens[_current];

  Token _previous() => tokens[_current - 1];

  Token _consume(TokenType type, String message) {
    if (_check(type)) return _advance();
    throw FormulaParseException(message, _peek());
  }
}
