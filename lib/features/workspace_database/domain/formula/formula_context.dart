abstract class IFormulaContext {
  /// Retrieve cell value for the given property name or id on the current row
  Future<dynamic> getPropertyValue(String propertyName);

  /// Set of properties currently in active evaluation stack (for dynamic cycle detection)
  Set<String> get activeCallStack;

  /// Creates a child context with an added property on the active call stack
  IFormulaContext pushCallStack(String propertyName);

  /// Checks if a property is already on the call stack
  bool isPropertyInCallStack(String propertyName);
}

class MapFormulaContext implements IFormulaContext {
  final Map<String, dynamic> propertyValues;
  @override
  final Set<String> activeCallStack;

  MapFormulaContext({
    required this.propertyValues,
    Set<String>? activeCallStack,
  }) : activeCallStack = activeCallStack ?? <String>{};

  @override
  Future<dynamic> getPropertyValue(String propertyName) async {
    // Case-insensitive lookup matching
    for (final entry in propertyValues.entries) {
      if (entry.key.toLowerCase() == propertyName.toLowerCase()) {
        return entry.value;
      }
    }
    return null;
  }

  @override
  bool isPropertyInCallStack(String propertyName) =>
      activeCallStack.any((p) => p.toLowerCase() == propertyName.toLowerCase());

  @override
  IFormulaContext pushCallStack(String propertyName) {
    return MapFormulaContext(
      propertyValues: propertyValues,
      activeCallStack: {...activeCallStack, propertyName},
    );
  }
}
