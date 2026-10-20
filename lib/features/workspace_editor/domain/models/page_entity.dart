import 'package:flutter/foundation.dart';

@immutable
class PageEntity {
  final String id;
  final String? parentPageId;
  final String title;
  final String? icon;
  final String? coverImageUrl;
  final bool isDatabaseRow;
  final bool isArchived;
  final double sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PageEntity({
    required this.id,
    this.parentPageId,
    required this.title,
    this.icon,
    this.coverImageUrl,
    this.isDatabaseRow = false,
    this.isArchived = false,
    this.sortOrder = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  PageEntity copyWith({
    String? id,
    String? parentPageId,
    bool clearParentPageId = false,
    String? title,
    String? icon,
    bool clearIcon = false,
    String? coverImageUrl,
    bool clearCoverImageUrl = false,
    bool? isDatabaseRow,
    bool? isArchived,
    double? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PageEntity(
      id: id ?? this.id,
      parentPageId: clearParentPageId ? null : (parentPageId ?? this.parentPageId),
      title: title ?? this.title,
      icon: clearIcon ? null : (icon ?? this.icon),
      coverImageUrl: clearCoverImageUrl ? null : (coverImageUrl ?? this.coverImageUrl),
      isDatabaseRow: isDatabaseRow ?? this.isDatabaseRow,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          parentPageId == other.parentPageId &&
          title == other.title &&
          icon == other.icon &&
          coverImageUrl == other.coverImageUrl &&
          isDatabaseRow == other.isDatabaseRow &&
          isArchived == other.isArchived &&
          sortOrder == other.sortOrder;

  @override
  int get hashCode =>
      id.hashCode ^
      parentPageId.hashCode ^
      title.hashCode ^
      icon.hashCode ^
      coverImageUrl.hashCode ^
      isDatabaseRow.hashCode ^
      isArchived.hashCode ^
      sortOrder.hashCode;
}
