/// High-performance Fractional Indexing & LexoRank Utility in pure Dart.
///
/// Provides:
/// 1. [FractionalIndexer] for Float64 database columns (`pages.sort_order`).
/// 2. [StringLexoRank] for infinite-precision string keys (`blocks.order_key`).
class FractionalIndexer {
  static const double defaultStep = 1000.0;
  static const double initialOrder = 1000.0;
  static const double minRebalanceDelta = 1e-6;

  /// Generates a midpoint double sort order between [prev] and [next].
  static double betweenDoubles(double? prev, double? next) {
    if (prev == null && next == null) {
      return initialOrder;
    }
    if (prev == null && next != null) {
      return next <= 0 ? next - defaultStep : next / 2.0;
    }
    if (prev != null && next == null) {
      return prev + defaultStep;
    }
    // Both non-null
    final p = prev!;
    final n = next!;
    if (p >= n) {
      // Degenerate condition: fallback to offset
      return p + (defaultStep / 2.0);
    }
    return (p + n) / 2.0;
  }

  /// Determines if precision limit is reached between siblings, requiring a rebalance.
  static bool needsRebalance(double prev, double next, {double minDelta = minRebalanceDelta}) {
    return (next - prev).abs() < minDelta;
  }

  /// Rebalances an entire sibling group evenly.
  static List<double> rebalanceDoubles(int count, {double start = defaultStep, double step = defaultStep}) {
    return List.generate(count, (index) => start + (index * step));
  }
}

/// Pure Dart Base-36 LexoRank string generator for Notion blocks & custom properties.
class StringLexoRank {
  static const String alphabet = '0123456789abcdefghijklmnopqrstuvwxyz';
  static const int base = 36;
  static const String initial = 'm';

  /// Prefix character used when stepping strictly below '0' (ASCII 47 < 48).
  static const String minPrefix = '/';

  static final Map<String, int> _charToVal = {
    for (int i = 0; i < alphabet.length; i++) alphabet[i]: i,
  };

  static int _charVal(String ch) {
    if (ch == minPrefix) return -1;
    return _charToVal[ch] ?? 0;
  }

  /// Generates a lexicographical midpoint string between [prev] and [next].
  static String between(String? prev, String? next) {
    if (prev == null && next == null) return initial;
    if (prev == null && next != null) return _before(next);
    if (prev != null && next == null) return _after(prev);

    final p = prev!;
    final n = next!;
    assert(p.compareTo(n) < 0, 'prev "$p" must be lexicographically smaller than next "$n"');

    int index = 0;
    while (index < p.length && index < n.length && p[index] == n[index]) {
      index++;
    }

    // Case 1: p is a proper prefix of n (e.g. p = 'a', n = 'a1')
    // Identity: between(P, P + S) = P + _before(S)
    if (index >= p.length) {
      final suffixN = n.substring(index);
      return p + _before(suffixN);
    }

    // Case 2: Characters differ at index (index < p.length and index < n.length)
    final pVal = _charVal(p[index]);
    final nVal = _charVal(n[index]);

    if (nVal - pVal > 1) {
      // Middle character available at this index
      final midVal = (pVal + nVal) ~/ 2;
      return p.substring(0, index) + alphabet[midVal];
    }

    // Consecutive characters at index (nVal - pVal == 1):
    // Retain p[0..index] and append suffix strictly greater than p.substring(index + 1)
    if (index + 1 < p.length) {
      final subMid = _after(p.substring(index + 1));
      return p.substring(0, index + 1) + subMid;
    }

    return p + alphabet[base ~/ 2];
  }

  static String _before(String next) {
    if (next.isEmpty) return initial;

    // If next starts with minPrefix ('/'), recurse or prepend another minPrefix
    if (next.startsWith(minPrefix)) {
      final rest = next.substring(1);
      return '$minPrefix${_before(rest)}';
    }

    final firstCharVal = _charToVal[next[0]];
    if (firstCharVal != null && firstCharVal > 0) {
      if (firstCharVal == 1) {
        // Between 0 and 1: append '0' followed by midpoint of next interval ('i')
        return '0${alphabet[base ~/ 2]}';
      }
      final mid = firstCharVal ~/ 2;
      return alphabet[mid];
    }

    // Starts with '0': check if there are subsequent non-zero characters
    int zeroCount = 0;
    while (zeroCount < next.length && next[zeroCount] == '0') {
      zeroCount++;
    }

    if (zeroCount == next.length) {
      // Entire string is all '0's (e.g. "0", "00"): step below '0' into minPrefix
      return '$minPrefix$initial';
    }

    // Has positive character after zeros (e.g. "05" -> "0" + _before("5"))
    return next.substring(0, zeroCount) + _before(next.substring(zeroCount));
  }

  static String _after(String prev) {
    if (prev.isEmpty) return initial;
    final lastChar = prev[prev.length - 1];
    final lastCharVal = _charToVal[lastChar];
    if (lastCharVal != null && lastCharVal < base - 1) {
      final mid = (lastCharVal + base) ~/ 2;
      return prev.substring(0, prev.length - 1) + alphabet[mid];
    }
    return prev + alphabet[base ~/ 2];
  }
}
