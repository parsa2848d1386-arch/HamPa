enum FilterOperator {
  equals,
  notEquals,
  contains,
  doesNotContain,
  startsWith,
  endsWith,
  isEmpty,
  isNotEmpty,
  greaterThan,
  lessThan,
  greaterThanOrEqual,
  lessThanOrEqual,
  dateIs,
  dateBefore,
  dateAfter,
  dateToday,
  isChecked,
  isNotChecked,
}

enum Conjunction { and, or }

class FilterCriteria {
  final String id;
  final String propertyId;
  final FilterOperator operator;
  final dynamic value;
  final Conjunction conjunction;

  const FilterCriteria({
    required this.id,
    required this.propertyId,
    required this.operator,
    this.value,
    this.conjunction = Conjunction.and,
  });

  bool evaluate(dynamic cellValue) {
    switch (operator) {
      case FilterOperator.equals:
        return cellValue?.toString().toLowerCase() == value?.toString().toLowerCase();
      case FilterOperator.notEquals:
        return cellValue?.toString().toLowerCase() != value?.toString().toLowerCase();
      case FilterOperator.contains:
        return cellValue?.toString().toLowerCase().contains(value?.toString().toLowerCase() ?? '') ?? false;
      case FilterOperator.doesNotContain:
        return !(cellValue?.toString().toLowerCase().contains(value?.toString().toLowerCase() ?? '') ?? false);
      case FilterOperator.startsWith:
        return cellValue?.toString().toLowerCase().startsWith(value?.toString().toLowerCase() ?? '') ?? false;
      case FilterOperator.endsWith:
        return cellValue?.toString().toLowerCase().endsWith(value?.toString().toLowerCase() ?? '') ?? false;
      case FilterOperator.isEmpty:
        return cellValue == null || cellValue.toString().trim().isEmpty;
      case FilterOperator.isNotEmpty:
        return cellValue != null && cellValue.toString().trim().isNotEmpty;
      case FilterOperator.greaterThan:
        if (cellValue is num && value is num) return cellValue > value;
        return false;
      case FilterOperator.lessThan:
        if (cellValue is num && value is num) return cellValue < value;
        return false;
      case FilterOperator.greaterThanOrEqual:
        if (cellValue is num && value is num) return cellValue >= value;
        return false;
      case FilterOperator.lessThanOrEqual:
        if (cellValue is num && value is num) return cellValue <= value;
        return false;
      case FilterOperator.isChecked:
        return cellValue == true;
      case FilterOperator.isNotChecked:
        return cellValue != true;
      case FilterOperator.dateIs:
      case FilterOperator.dateBefore:
      case FilterOperator.dateAfter:
      case FilterOperator.dateToday:
        if (cellValue == null) return false;
        final cellDate = DateTime.tryParse(cellValue.toString());
        if (cellDate == null) return false;
        if (operator == FilterOperator.dateToday) {
          final now = DateTime.now();
          return cellDate.year == now.year && cellDate.month == now.month && cellDate.day == now.day;
        }
        final targetDate = DateTime.tryParse(value.toString());
        if (targetDate == null) return false;
        if (operator == FilterOperator.dateIs) {
          return cellDate.year == targetDate.year && cellDate.month == targetDate.month && cellDate.day == targetDate.day;
        } else if (operator == FilterOperator.dateBefore) {
          return cellDate.isBefore(targetDate);
        } else {
          return cellDate.isAfter(targetDate);
        }
    }
  }
}
