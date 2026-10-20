enum SortDirection { ascending, descending }

class SortCriteria {
  final String propertyId;
  final SortDirection direction;

  const SortCriteria({
    required this.propertyId,
    this.direction = SortDirection.ascending,
  });

  int compare(dynamic valA, dynamic valB) {
    if (valA == null && valB == null) return 0;
    if (valA == null) return direction == SortDirection.ascending ? 1 : -1;
    if (valB == null) return direction == SortDirection.ascending ? -1 : 1;

    int result = 0;
    if (valA is num && valB is num) {
      result = valA.compareTo(valB);
    } else if (valA is bool && valB is bool) {
      result = (valA == valB) ? 0 : (valA ? 1 : -1);
    } else {
      result = valA.toString().compareTo(valB.toString());
    }
    return direction == SortDirection.ascending ? result : -result;
  }
}
