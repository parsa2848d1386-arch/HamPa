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
  @override
  dynamic get rawValue => value;
  @override
  bool get isTruthy => value != 0;
  @override
  bool get isError => false;

  @override
  String toString() => 'NumberFormulaValue($value)';
}

class StringFormulaValue extends FormulaValue {
  final String value;
  const StringFormulaValue(this.value);
  @override
  dynamic get rawValue => value;
  @override
  bool get isTruthy => value.isNotEmpty;
  @override
  bool get isError => false;

  @override
  String toString() => 'StringFormulaValue("$value")';
}

class BooleanFormulaValue extends FormulaValue {
  final bool value;
  const BooleanFormulaValue(this.value);
  @override
  dynamic get rawValue => value;
  @override
  bool get isTruthy => value;
  @override
  bool get isError => false;

  @override
  String toString() => 'BooleanFormulaValue($value)';
}

class DateFormulaValue extends FormulaValue {
  final DateTime value;
  const DateFormulaValue(this.value);
  @override
  dynamic get rawValue => value;
  @override
  bool get isTruthy => true;
  @override
  bool get isError => false;

  @override
  String toString() => 'DateFormulaValue($value)';
}

class NullFormulaValue extends FormulaValue {
  const NullFormulaValue();
  @override
  dynamic get rawValue => null;
  @override
  bool get isTruthy => false;
  @override
  bool get isError => false;

  @override
  String toString() => 'NullFormulaValue()';
}

class ErrorFormulaValue extends FormulaValue {
  final String errorCode; // '#DIV/0!', '#CYCLE!', '#ERROR!'
  const ErrorFormulaValue(this.errorCode);
  @override
  dynamic get rawValue => errorCode;
  @override
  bool get isTruthy => false;
  @override
  bool get isError => true;

  @override
  String toString() => 'ErrorFormulaValue("$errorCode")';
}
