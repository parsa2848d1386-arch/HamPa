class ColumnLayout {
  final String propertyId;
  final double width;
  final bool isVisible;
  final int orderIndex;

  const ColumnLayout({
    required this.propertyId,
    this.width = 160.0,
    this.isVisible = true,
    required this.orderIndex,
  });

  ColumnLayout copyWith({
    String? propertyId,
    double? width,
    bool? isVisible,
    int? orderIndex,
  }) {
    return ColumnLayout(
      propertyId: propertyId ?? this.propertyId,
      width: width ?? this.width,
      isVisible: isVisible ?? this.isVisible,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}
