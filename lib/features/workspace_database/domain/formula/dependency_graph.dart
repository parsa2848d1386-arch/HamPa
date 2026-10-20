class CircularDependencyException implements Exception {
  final String message;
  CircularDependencyException(this.message);
  @override
  String toString() => 'CircularDependencyException: $message';
}

class FormulaDependencyGraph {
  final Map<String, Set<String>> _dependencies = {}; // node -> outgoing edges (dependencies)

  void addProperty(String propertyId, Set<String> dependencies) {
    _dependencies[propertyId] = Set.from(dependencies);
  }

  void removeProperty(String propertyId) {
    _dependencies.remove(propertyId);
    for (final deps in _dependencies.values) {
      deps.remove(propertyId);
    }
  }

  bool hasCycle() => findCyclePath() != null;

  List<String>? findCyclePath() {
    final visited = <String, int>{}; // 0 = unvisited, 1 = visiting, 2 = visited
    final path = <String>[];

    for (final node in _dependencies.keys) {
      if (!visited.containsKey(node)) {
        final cycle = _dfsFindCycle(node, visited, path);
        if (cycle != null) return cycle;
      }
    }
    return null;
  }

  List<String>? _dfsFindCycle(String current, Map<String, int> visited, List<String> path) {
    visited[current] = 1;
    path.add(current);

    final neighbors = _dependencies[current] ?? {};
    for (final neighbor in neighbors) {
      if (visited[neighbor] == 1) {
        // Cycle found
        final cycleStart = path.indexOf(neighbor);
        return path.sublist(cycleStart)..add(neighbor);
      } else if (!visited.containsKey(neighbor)) {
        final res = _dfsFindCycle(neighbor, visited, path);
        if (res != null) return res;
      }
    }

    path.removeLast();
    visited[current] = 2;
    return null;
  }

  List<String> getTopologicalOrder() {
    // node -> dependents (which nodes depend on this node)
    final dependents = <String, Set<String>>{};
    final inDegree = <String, int>{};

    for (final node in _dependencies.keys) {
      dependents.putIfAbsent(node, () => {});
      inDegree.putIfAbsent(node, () => 0);
    }

    for (final entry in _dependencies.entries) {
      final node = entry.key;
      final deps = entry.value;
      inDegree[node] = deps.length;
      for (final dep in deps) {
        dependents.putIfAbsent(dep, () => {}).add(node);
        inDegree.putIfAbsent(dep, () => 0);
      }
    }

    final queue = inDegree.keys.where((k) => inDegree[k] == 0).toList();
    final order = <String>[];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      order.add(current);

      for (final dep in dependents[current] ?? {}) {
        inDegree[dep] = (inDegree[dep] ?? 1) - 1;
        if (inDegree[dep] == 0) {
          queue.add(dep);
        }
      }
    }

    if (order.length < inDegree.length) {
      throw CircularDependencyException('Cycle detected in formula dependencies');
    }
    return order;
  }
}
