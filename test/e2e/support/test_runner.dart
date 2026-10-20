// Standalone & Hermetic Test Runner for HamPA E2E Test Suite
// Provides group, test, expect, and matchers compatible with package:test.

import 'dart:async';

int _totalTests = 0;
int _passedTests = 0;
int _failedTests = 0;
final List<String> _failureMessages = [];
String _currentGroup = '';
Future<void> _testExecutionChain = Future.value();

void group(String description, void Function() body) {
  final previousGroup = _currentGroup;
  _currentGroup = previousGroup.isEmpty ? description : '$previousGroup > $description';
  try {
    body();
  } finally {
    _currentGroup = previousGroup;
  }
}

void test(String description, dynamic Function() body) {
  _totalTests++;
  final testName = _currentGroup.isEmpty ? description : '$_currentGroup > $description';

  _testExecutionChain = _testExecutionChain.then((_) async {
    try {
      final result = body();
      if (result is Future) {
        await result;
      }
      _passedTests++;
    } catch (err, st) {
      _failedTests++;
      _failureMessages.add('FAILED: $testName\nError: $err\nStack: $st');
    }
  });
}

Future<void> testAsync(String description, Future<void> Function() body) async {
  test(description, body);
  await _testExecutionChain;
}

class Matcher {
  final bool Function(dynamic item) matches;
  final String description;
  const Matcher(this.matches, this.description);
}

Matcher equals(dynamic expected) => Matcher(
      (item) {
        if (expected is List && item is List) {
          if (expected.length != item.length) return false;
          for (var i = 0; i < expected.length; i++) {
            if (expected[i] != item[i]) return false;
          }
          return true;
        }
        return item == expected;
      },
      'equals $expected',
    );

Matcher isTrue = const Matcher(_isTrue, 'is true');
bool _isTrue(dynamic item) => item == true;

Matcher isFalse = const Matcher(_isFalse, 'is false');
bool _isFalse(dynamic item) => item == false;

Matcher isNull = const Matcher(_isNull, 'is null');
bool _isNull(dynamic item) => item == null;

Matcher isNotNull = const Matcher(_isNotNull, 'is not null');
bool _isNotNull(dynamic item) => item != null;

Matcher greaterThan(num expected) =>
    Matcher((item) => item is num && item > expected, 'greater than $expected');

Matcher greaterThanOrEqualTo(num expected) =>
    Matcher((item) => item is num && item >= expected, 'greater than or equal to $expected');

Matcher lessThan(num expected) =>
    Matcher((item) => item is num && item < expected, 'less than $expected');

Matcher lessThanOrEqualTo(num expected) =>
    Matcher((item) => item is num && item <= expected, 'less than or equal to $expected');

Matcher contains(dynamic expected) => Matcher((item) {
      if (item is String && expected is String) return item.contains(expected);
      if (item is Iterable) return item.contains(expected);
      if (item is Map) return item.containsKey(expected);
      return false;
    }, 'contains $expected');

void expect(dynamic actual, dynamic matcher, {String? reason}) {
  if (matcher is Matcher) {
    if (!matcher.matches(actual)) {
      throw TestFailure(
        'Expected ${matcher.description}, but got: $actual${reason != null ? ' ($reason)' : ''}',
      );
    }
  } else {
    if (actual != matcher) {
      throw TestFailure(
        'Expected $matcher, but got: $actual${reason != null ? ' ($reason)' : ''}',
      );
    }
  }
}

Future<void> expectAsync(Future<dynamic> actualFuture, dynamic matcher, {String? reason}) async {
  final actual = await actualFuture;
  expect(actual, matcher, reason: reason);
}

Future<void> expectThrows<T extends Object>(Future<void> Function() callback) async {
  try {
    await callback();
    throw TestFailure('Expected exception of type $T, but no exception was thrown.');
  } catch (e) {
    if (e is TestFailure) rethrow;
    if (e is! T) {
      throw TestFailure('Expected exception of type $T, but got: ${e.runtimeType} ($e)');
    }
  }
}

class TestFailure implements Exception {
  final String message;
  TestFailure(this.message);
  @override
  String toString() => message;
}

TestSummary getTestSummary() {
  return TestSummary(
    total: _totalTests,
    passed: _passedTests,
    failed: _failedTests,
    failures: List.unmodifiable(_failureMessages),
  );
}

void resetTestStats() {
  _totalTests = 0;
  _passedTests = 0;
  _failedTests = 0;
  _failureMessages.clear();
  _currentGroup = '';
  _testExecutionChain = Future.value();
}

class TestSummary {
  final int total;
  final int passed;
  final int failed;
  final List<String> failures;

  TestSummary({
    required this.total,
    required this.passed,
    required this.failed,
    required this.failures,
  });

  bool get isSuccess => failed == 0 && total > 0;
}
