import '../models/rollup_function.dart';
import 'rollup_calculator.dart';

abstract class IRollupDataSource {
  Future<List<String>> getRelatedRowIds(String rowId, String relationPropertyId);
  Future<List<dynamic>> getPropertyValuesForRows(List<String> rowIds, String targetPropertyId);
}

class RollupEvaluator {
  final IRollupDataSource dataSource;
  RollupEvaluator(this.dataSource);

  Future<dynamic> evaluate({
    required String rowId,
    required String relationPropertyId,
    required String targetPropertyId,
    required RollupFunction function,
  }) async {
    final relatedRowIds = await dataSource.getRelatedRowIds(rowId, relationPropertyId);
    if (relatedRowIds.isEmpty) {
      return RollupCalculator.compute(values: [], function: function);
    }
    final targetValues = await dataSource.getPropertyValuesForRows(relatedRowIds, targetPropertyId);
    return RollupCalculator.compute(values: targetValues, function: function);
  }
}
