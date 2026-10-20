import 'dart:convert';
import 'block_type.dart';

class BlockEntity {
  final String id;
  final String pageId;
  final String? parentBlockId;
  final BlockType type;
  final String orderKey;
  final Map<String, dynamic> content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived;

  const BlockEntity({
    required this.id,
    required this.pageId,
    this.parentBlockId,
    required this.type,
    required this.orderKey,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
  });

  String get contentJson => jsonEncode(content);

  BlockEntity copyWith({
    String? id,
    String? pageId,
    String? parentBlockId,
    bool clearParentBlockId = false,
    BlockType? type,
    String? orderKey,
    Map<String, dynamic>? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
  }) {
    return BlockEntity(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      parentBlockId: clearParentBlockId ? null : (parentBlockId ?? this.parentBlockId),
      type: type ?? this.type,
      orderKey: orderKey ?? this.orderKey,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  factory BlockEntity.fromJson(Map<String, dynamic> json) {
    return BlockEntity(
      id: json['id'] as String,
      pageId: json['page_id'] as String,
      parentBlockId: json['parent_block_id'] as String?,
      type: BlockType.fromString(json['block_type'] as String),
      orderKey: json['order_key'] as String,
      content: json['content_json'] is String
          ? jsonDecode(json['content_json'] as String) as Map<String, dynamic>
          : json['content_json'] as Map<String, dynamic>,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updated_at'] as int),
      isArchived: json['is_archived'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'page_id': pageId,
      'parent_block_id': parentBlockId,
      'block_type': type.value,
      'order_key': orderKey,
      'content_json': jsonEncode(content),
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'is_archived': isArchived,
    };
  }
}
