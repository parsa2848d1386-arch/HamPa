class CellEntity {
  final String id;
  final String rowId;
  final String propertyId;
  final dynamic value;

  const CellEntity({
    required this.id,
    required this.rowId,
    required this.propertyId,
    this.value,
  });

  CellEntity copyWith({
    String? id,
    String? rowId,
    String? propertyId,
    dynamic value,
  }) {
    return CellEntity(
      id: id ?? this.id,
      rowId: rowId ?? this.rowId,
      propertyId: propertyId ?? this.propertyId,
      value: value ?? this.value,
    );
  }
}
