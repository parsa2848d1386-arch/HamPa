enum TokenType {
  // Literals
  number,
  string,
  boolean,
  nullLiteral,

  // Identifiers & Built-in Keywords
  identifier,
  prop,
  fnIf,
  dateAdd,
  dateBetween,
  format,
  concat,
  length,
  round,
  ceil,
  floor,

  // Operators
  plus,
  minus,
  star,
  slash,
  percent,
  equalEqual,
  bangEqual,
  less,
  lessEqual,
  greater,
  greaterEqual,
  andAnd,
  orOr,
  bang,

  // Punctuation
  leftParen,
  rightParen,
  comma,

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
