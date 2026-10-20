import 'token.dart';

class FormulaLexerException implements Exception {
  final String message;
  final int position;
  FormulaLexerException(this.message, this.position);
  @override
  String toString() => 'FormulaLexerException at $position: $message';
}

class FormulaLexer {
  final String source;
  final List<Token> tokens = [];
  int _start = 0;
  int _current = 0;

  FormulaLexer(this.source);

  List<Token> scanTokens() {
    tokens.clear();
    _start = 0;
    _current = 0;

    while (!_isAtEnd) {
      _start = _current;
      _scanToken();
    }

    tokens.add(Token(
      type: TokenType.eof,
      lexeme: '',
      position: _current,
    ));
    return tokens;
  }

  void _scanToken() {
    final c = _advance();
    switch (c) {
      case ' ':
      case '\r':
      case '\t':
      case '\n':
        // Ignore whitespace
        break;
      case '(':
        _addToken(TokenType.leftParen);
        break;
      case ')':
        _addToken(TokenType.rightParen);
        break;
      case ',':
        _addToken(TokenType.comma);
        break;
      case '+':
        _addToken(TokenType.plus);
        break;
      case '-':
        _addToken(TokenType.minus);
        break;
      case '*':
        _addToken(TokenType.star);
        break;
      case '/':
        _addToken(TokenType.slash);
        break;
      case '%':
        _addToken(TokenType.percent);
        break;
      case '!':
        _addToken(_match('=') ? TokenType.bangEqual : TokenType.bang);
        break;
      case '=':
        if (_match('=')) {
          _addToken(TokenType.equalEqual);
        } else {
          // single '=' treated as equal
          _addToken(TokenType.equalEqual);
        }
        break;
      case '<':
        _addToken(_match('=') ? TokenType.lessEqual : TokenType.less);
        break;
      case '>':
        _addToken(_match('=') ? TokenType.greaterEqual : TokenType.greater);
        break;
      case '&':
        if (_match('&')) {
          _addToken(TokenType.andAnd);
        } else {
          throw FormulaLexerException('Unexpected character: &', _start);
        }
        break;
      case '|':
        if (_match('|')) {
          _addToken(TokenType.orOr);
        } else {
          throw FormulaLexerException('Unexpected character: |', _start);
        }
        break;
      case '"':
      case "'":
        _string(c);
        break;
      default:
        if (_isDigit(c)) {
          _number();
        } else if (_isAlpha(c)) {
          _identifier();
        } else {
          throw FormulaLexerException('Unexpected character: $c', _start);
        }
        break;
    }
  }

  void _string(String quoteChar) {
    final buffer = StringBuffer();
    while (!_isAtEnd && _peek() != quoteChar) {
      if (_peek() == '\\') {
        _advance();
        if (!_isAtEnd) {
          final esc = _advance();
          switch (esc) {
            case 'n':
              buffer.write('\n');
              break;
            case 't':
              buffer.write('\t');
              break;
            case 'r':
              buffer.write('\r');
              break;
            case '\\':
              buffer.write('\\');
              break;
            case '"':
              buffer.write('"');
              break;
            case "'":
              buffer.write("'");
              break;
            default:
              buffer.write(esc);
              break;
          }
        }
      } else {
        buffer.write(_advance());
      }
    }

    if (_isAtEnd) {
      throw FormulaLexerException('Unterminated string.', _start);
    }

    // Closing quote
    _advance();

    final value = buffer.toString();
    tokens.add(Token(
      type: TokenType.string,
      lexeme: source.substring(_start, _current),
      literal: value,
      position: _start,
    ));
  }

  void _number() {
    while (_isDigit(_peek())) {
      _advance();
    }

    // Look for fractional part
    if (_peek() == '.' && _isDigit(_peekNext())) {
      // Consume the "."
      _advance();
      while (_isDigit(_peek())) {
        _advance();
      }
    }

    final lexeme = source.substring(_start, _current);
    final value = num.parse(lexeme);
    tokens.add(Token(
      type: TokenType.number,
      lexeme: lexeme,
      literal: value,
      position: _start,
    ));
  }

  void _identifier() {
    while (_isAlphaNumeric(_peek())) {
      _advance();
    }

    final text = source.substring(_start, _current);
    final lower = text.toLowerCase();
    TokenType type;

    switch (lower) {
      case 'prop':
        type = TokenType.prop;
        break;
      case 'if':
        type = TokenType.fnIf;
        break;
      case 'dateadd':
        type = TokenType.dateAdd;
        break;
      case 'datebetween':
        type = TokenType.dateBetween;
        break;
      case 'format':
        type = TokenType.format;
        break;
      case 'concat':
        type = TokenType.concat;
        break;
      case 'length':
        type = TokenType.length;
        break;
      case 'round':
        type = TokenType.round;
        break;
      case 'ceil':
        type = TokenType.ceil;
        break;
      case 'floor':
        type = TokenType.floor;
        break;
      case 'true':
        tokens.add(Token(
          type: TokenType.boolean,
          lexeme: text,
          literal: true,
          position: _start,
        ));
        return;
      case 'false':
        tokens.add(Token(
          type: TokenType.boolean,
          lexeme: text,
          literal: false,
          position: _start,
        ));
        return;
      case 'null':
        tokens.add(Token(
          type: TokenType.nullLiteral,
          lexeme: text,
          literal: null,
          position: _start,
        ));
        return;
      default:
        type = TokenType.identifier;
        break;
    }

    tokens.add(Token(
      type: type,
      lexeme: text,
      literal: text,
      position: _start,
    ));
  }

  bool _match(String expected) {
    if (_isAtEnd) return false;
    if (source[_current] != expected) return false;
    _current++;
    return true;
  }

  String _peek() {
    if (_isAtEnd) return '\x00';
    return source[_current];
  }

  String _peekNext() {
    if (_current + 1 >= source.length) return '\x00';
    return source[_current + 1];
  }

  String _advance() {
    return source[_current++];
  }

  void _addToken(TokenType type) {
    final text = source.substring(_start, _current);
    tokens.add(Token(
      type: type,
      lexeme: text,
      position: _start,
    ));
  }

  bool get _isAtEnd => _current >= source.length;
  bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
  bool _isAlpha(String c) {
    final code = c.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122) || c == '_';
  }
  bool _isAlphaNumeric(String c) => _isAlpha(c) || _isDigit(c);
}
