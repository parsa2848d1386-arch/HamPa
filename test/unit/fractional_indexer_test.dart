import 'package:flutter_test/flutter_test.dart';
import 'package:hampa/core/utils/fractional_indexer.dart';

void main() {
  group('DoubleFractionalIndexer Tests', () {
    test('Calculates initial order when prev and next are null', () {
      expect(FractionalIndexer.betweenDoubles(null, null), equals(1000.0));
    });

    test('Inserts before first item', () {
      expect(FractionalIndexer.betweenDoubles(null, 1000.0), equals(500.0));
    });

    test('Inserts after last item', () {
      expect(FractionalIndexer.betweenDoubles(2000.0, null), equals(3000.0));
    });

    test('Calculates exact midpoint between siblings', () {
      expect(FractionalIndexer.betweenDoubles(1000.0, 2000.0), equals(1500.0));
      expect(FractionalIndexer.betweenDoubles(1000.0, 1500.0), equals(1250.0));
    });

    test('Detects precision rebalance threshold', () {
      expect(FractionalIndexer.needsRebalance(1.0, 1.00000001), isTrue);
      expect(FractionalIndexer.needsRebalance(1.0, 2.0), isFalse);
    });

    test('Rebalances items evenly', () {
      final rebalanced = FractionalIndexer.rebalanceDoubles(4);
      expect(rebalanced, equals([1000.0, 2000.0, 3000.0, 4000.0]));
    });
  });

  group('StringLexoRank Tests', () {
    test('Initial rank is m', () {
      expect(StringLexoRank.between(null, null), equals('m'));
    });

    test('Generates midpoint between a and c', () {
      expect(StringLexoRank.between('a', 'c'), equals('b'));
    });

    test('Generates suffix midpoint between consecutive characters a and b', () {
      final mid = StringLexoRank.between('a', 'b');
      expect(mid.compareTo('a'), greaterThan(0));
      expect(mid.compareTo('b'), lessThan(0));
      expect(mid, equals('ai'));
    });

    test('Generates order before first key', () {
      final beforeM = StringLexoRank.between(null, 'm');
      expect(beforeM.compareTo('m'), lessThan(0));
    });

    test('Generates order after last key', () {
      final afterM = StringLexoRank.between('m', null);
      expect(afterM.compareTo('m'), greaterThan(0));
    });
  });
}
