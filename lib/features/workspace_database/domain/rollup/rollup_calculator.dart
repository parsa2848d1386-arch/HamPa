import '../models/rollup_function.dart';

class RollupCalculator {
  static dynamic compute({
    required List<dynamic> values,
    required RollupFunction function,
  }) {
    if (values.isEmpty) {
      switch (function) {
        case RollupFunction.sum:
        case RollupFunction.count:
          return 0;
        case RollupFunction.percentChecked:
          return 0.0;
        case RollupFunction.average:
        case RollupFunction.min:
        case RollupFunction.max:
          return null;
      }
    }

    switch (function) {
      case RollupFunction.count:
        return values.length;

      case RollupFunction.sum:
        final nums = values.whereType<num>().toList();
        if (nums.isEmpty) return 0;
        return nums.fold<num>(0, (prev, curr) => prev + curr);

      case RollupFunction.average:
        final nums = values.whereType<num>().toList();
        if (nums.isEmpty) return null;
        final sum = nums.fold<num>(0, (prev, curr) => prev + curr);
        return (sum / nums.length).toDouble();

      case RollupFunction.min:
        final nums = values.whereType<num>().toList();
        if (nums.isEmpty) return null;
        return nums.reduce((a, b) => a < b ? a : b);

      case RollupFunction.max:
        final nums = values.whereType<num>().toList();
        if (nums.isEmpty) return null;
        return nums.reduce((a, b) => a > b ? a : b);

      case RollupFunction.percentChecked:
        final bools = values.whereType<bool>().toList();
        if (bools.isEmpty) return 0.0;
        final checked = bools.where((b) => b).length;
        return (checked / bools.length) * 100.0;
    }
  }
}
