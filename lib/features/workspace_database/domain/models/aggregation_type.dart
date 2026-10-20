enum AggregationType {
  none,
  countAll,
  countValues,
  countUnique,
  countEmpty,
  countNotEmpty,
  percentEmpty,
  percentNotEmpty,
  sum,
  average,
  median,
  min,
  max,
  range,
  percentChecked,
}

extension AggregationCalculation on AggregationType {
  String formatResult(dynamic result) {
    if (result == null) return '';
    if (result is double) {
      return result.toStringAsFixed(result.truncateToDouble() == result ? 0 : 2);
    }
    return result.toString();
  }

  dynamic compute(List<dynamic> values) {
    switch (this) {
      case AggregationType.none:
        return null;
      case AggregationType.countAll:
        return values.length;
      case AggregationType.countValues:
        return values.where((v) => v != null && v.toString().trim().isNotEmpty).length;
      case AggregationType.countUnique:
        return values.where((v) => v != null).toSet().length;
      case AggregationType.countEmpty:
        return values.where((v) => v == null || v.toString().trim().isEmpty).length;
      case AggregationType.countNotEmpty:
        return values.where((v) => v != null && v.toString().trim().isNotEmpty).length;
      case AggregationType.percentEmpty:
        if (values.isEmpty) return 0.0;
        final emptyCount = values.where((v) => v == null || v.toString().trim().isEmpty).length;
        return (emptyCount / values.length) * 100.0;
      case AggregationType.percentNotEmpty:
        if (values.isEmpty) return 0.0;
        final notEmpty = values.where((v) => v != null && v.toString().trim().isNotEmpty).length;
        return (notEmpty / values.length) * 100.0;
      case AggregationType.sum:
        final nums = values.whereType<num>();
        if (nums.isEmpty) return 0;
        return nums.fold<num>(0, (prev, curr) => prev + curr);
      case AggregationType.average:
        final nums = values.whereType<num>().toList();
        if (nums.isEmpty) return 0.0;
        return nums.fold<num>(0, (prev, curr) => prev + curr) / nums.length;
      case AggregationType.median:
        final nums = values.whereType<num>().toList()..sort();
        if (nums.isEmpty) return 0;
        final mid = nums.length ~/ 2;
        if (nums.length % 2 == 1) return nums[mid];
        return (nums[mid - 1] + nums[mid]) / 2.0;
      case AggregationType.min:
        final nums = values.whereType<num>();
        if (nums.isEmpty) return null;
        return nums.reduce((a, b) => a < b ? a : b);
      case AggregationType.max:
        final nums = values.whereType<num>();
        if (nums.isEmpty) return null;
        return nums.reduce((a, b) => a > b ? a : b);
      case AggregationType.range:
        final nums = values.whereType<num>().toList();
        if (nums.isEmpty) return 0;
        final minVal = nums.reduce((a, b) => a < b ? a : b);
        final maxVal = nums.reduce((a, b) => a > b ? a : b);
        return maxVal - minVal;
      case AggregationType.percentChecked:
        if (values.isEmpty) return 0.0;
        final checked = values.where((v) => v == true || v == 'true' || v == 1).length;
        return (checked / values.length) * 100.0;
    }
  }
}
