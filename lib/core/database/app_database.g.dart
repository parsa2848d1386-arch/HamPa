// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PagesTable extends Pages with TableInfo<$PagesTable, PageEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _parentPageIdMeta =
      const VerificationMeta('parentPageId');
  @override
  late final GeneratedColumn<String> parentPageId = GeneratedColumn<String>(
      'parent_page_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Untitled'));
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _coverImageUrlMeta =
      const VerificationMeta('coverImageUrl');
  @override
  late final GeneratedColumn<String> coverImageUrl = GeneratedColumn<String>(
      'cover_image_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isDatabaseRowMeta =
      const VerificationMeta('isDatabaseRow');
  @override
  late final GeneratedColumn<bool> isDatabaseRow = GeneratedColumn<bool>(
      'is_database_row', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_database_row" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isArchivedMeta =
      const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
      'is_archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<double> sortOrder = GeneratedColumn<double>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        parentPageId,
        title,
        icon,
        coverImageUrl,
        isDatabaseRow,
        isArchived,
        sortOrder,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pages';
  @override
  VerificationContext validateIntegrity(Insertable<PageEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('parent_page_id')) {
      context.handle(
          _parentPageIdMeta,
          parentPageId.isAcceptableOrUnknown(
              data['parent_page_id']!, _parentPageIdMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('cover_image_url')) {
      context.handle(
          _coverImageUrlMeta,
          coverImageUrl.isAcceptableOrUnknown(
              data['cover_image_url']!, _coverImageUrlMeta));
    }
    if (data.containsKey('is_database_row')) {
      context.handle(
          _isDatabaseRowMeta,
          isDatabaseRow.isAcceptableOrUnknown(
              data['is_database_row']!, _isDatabaseRowMeta));
    }
    if (data.containsKey('is_archived')) {
      context.handle(
          _isArchivedMeta,
          isArchived.isAcceptableOrUnknown(
              data['is_archived']!, _isArchivedMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PageEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PageEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      parentPageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_page_id']),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon']),
      coverImageUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_image_url']),
      isDatabaseRow: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_database_row'])!,
      isArchived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_archived'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $PagesTable createAlias(String alias) {
    return $PagesTable(attachedDatabase, alias);
  }
}

class PageEntry extends DataClass implements Insertable<PageEntry> {
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
  const PageEntry(
      {required this.id,
      this.parentPageId,
      required this.title,
      this.icon,
      this.coverImageUrl,
      required this.isDatabaseRow,
      required this.isArchived,
      required this.sortOrder,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || parentPageId != null) {
      map['parent_page_id'] = Variable<String>(parentPageId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || coverImageUrl != null) {
      map['cover_image_url'] = Variable<String>(coverImageUrl);
    }
    map['is_database_row'] = Variable<bool>(isDatabaseRow);
    map['is_archived'] = Variable<bool>(isArchived);
    map['sort_order'] = Variable<double>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PagesCompanion toCompanion(bool nullToAbsent) {
    return PagesCompanion(
      id: Value(id),
      parentPageId: parentPageId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentPageId),
      title: Value(title),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      coverImageUrl: coverImageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverImageUrl),
      isDatabaseRow: Value(isDatabaseRow),
      isArchived: Value(isArchived),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PageEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PageEntry(
      id: serializer.fromJson<String>(json['id']),
      parentPageId: serializer.fromJson<String?>(json['parentPageId']),
      title: serializer.fromJson<String>(json['title']),
      icon: serializer.fromJson<String?>(json['icon']),
      coverImageUrl: serializer.fromJson<String?>(json['coverImageUrl']),
      isDatabaseRow: serializer.fromJson<bool>(json['isDatabaseRow']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      sortOrder: serializer.fromJson<double>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'parentPageId': serializer.toJson<String?>(parentPageId),
      'title': serializer.toJson<String>(title),
      'icon': serializer.toJson<String?>(icon),
      'coverImageUrl': serializer.toJson<String?>(coverImageUrl),
      'isDatabaseRow': serializer.toJson<bool>(isDatabaseRow),
      'isArchived': serializer.toJson<bool>(isArchived),
      'sortOrder': serializer.toJson<double>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PageEntry copyWith(
          {String? id,
          Value<String?> parentPageId = const Value.absent(),
          String? title,
          Value<String?> icon = const Value.absent(),
          Value<String?> coverImageUrl = const Value.absent(),
          bool? isDatabaseRow,
          bool? isArchived,
          double? sortOrder,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      PageEntry(
        id: id ?? this.id,
        parentPageId:
            parentPageId.present ? parentPageId.value : this.parentPageId,
        title: title ?? this.title,
        icon: icon.present ? icon.value : this.icon,
        coverImageUrl:
            coverImageUrl.present ? coverImageUrl.value : this.coverImageUrl,
        isDatabaseRow: isDatabaseRow ?? this.isDatabaseRow,
        isArchived: isArchived ?? this.isArchived,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  PageEntry copyWithCompanion(PagesCompanion data) {
    return PageEntry(
      id: data.id.present ? data.id.value : this.id,
      parentPageId: data.parentPageId.present
          ? data.parentPageId.value
          : this.parentPageId,
      title: data.title.present ? data.title.value : this.title,
      icon: data.icon.present ? data.icon.value : this.icon,
      coverImageUrl: data.coverImageUrl.present
          ? data.coverImageUrl.value
          : this.coverImageUrl,
      isDatabaseRow: data.isDatabaseRow.present
          ? data.isDatabaseRow.value
          : this.isDatabaseRow,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PageEntry(')
          ..write('id: $id, ')
          ..write('parentPageId: $parentPageId, ')
          ..write('title: $title, ')
          ..write('icon: $icon, ')
          ..write('coverImageUrl: $coverImageUrl, ')
          ..write('isDatabaseRow: $isDatabaseRow, ')
          ..write('isArchived: $isArchived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, parentPageId, title, icon, coverImageUrl,
      isDatabaseRow, isArchived, sortOrder, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PageEntry &&
          other.id == this.id &&
          other.parentPageId == this.parentPageId &&
          other.title == this.title &&
          other.icon == this.icon &&
          other.coverImageUrl == this.coverImageUrl &&
          other.isDatabaseRow == this.isDatabaseRow &&
          other.isArchived == this.isArchived &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PagesCompanion extends UpdateCompanion<PageEntry> {
  final Value<String> id;
  final Value<String?> parentPageId;
  final Value<String> title;
  final Value<String?> icon;
  final Value<String?> coverImageUrl;
  final Value<bool> isDatabaseRow;
  final Value<bool> isArchived;
  final Value<double> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PagesCompanion({
    this.id = const Value.absent(),
    this.parentPageId = const Value.absent(),
    this.title = const Value.absent(),
    this.icon = const Value.absent(),
    this.coverImageUrl = const Value.absent(),
    this.isDatabaseRow = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PagesCompanion.insert({
    required String id,
    this.parentPageId = const Value.absent(),
    this.title = const Value.absent(),
    this.icon = const Value.absent(),
    this.coverImageUrl = const Value.absent(),
    this.isDatabaseRow = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<PageEntry> custom({
    Expression<String>? id,
    Expression<String>? parentPageId,
    Expression<String>? title,
    Expression<String>? icon,
    Expression<String>? coverImageUrl,
    Expression<bool>? isDatabaseRow,
    Expression<bool>? isArchived,
    Expression<double>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parentPageId != null) 'parent_page_id': parentPageId,
      if (title != null) 'title': title,
      if (icon != null) 'icon': icon,
      if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
      if (isDatabaseRow != null) 'is_database_row': isDatabaseRow,
      if (isArchived != null) 'is_archived': isArchived,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PagesCompanion copyWith(
      {Value<String>? id,
      Value<String?>? parentPageId,
      Value<String>? title,
      Value<String?>? icon,
      Value<String?>? coverImageUrl,
      Value<bool>? isDatabaseRow,
      Value<bool>? isArchived,
      Value<double>? sortOrder,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return PagesCompanion(
      id: id ?? this.id,
      parentPageId: parentPageId ?? this.parentPageId,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      isDatabaseRow: isDatabaseRow ?? this.isDatabaseRow,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (parentPageId.present) {
      map['parent_page_id'] = Variable<String>(parentPageId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (coverImageUrl.present) {
      map['cover_image_url'] = Variable<String>(coverImageUrl.value);
    }
    if (isDatabaseRow.present) {
      map['is_database_row'] = Variable<bool>(isDatabaseRow.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<double>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PagesCompanion(')
          ..write('id: $id, ')
          ..write('parentPageId: $parentPageId, ')
          ..write('title: $title, ')
          ..write('icon: $icon, ')
          ..write('coverImageUrl: $coverImageUrl, ')
          ..write('isDatabaseRow: $isDatabaseRow, ')
          ..write('isArchived: $isArchived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BlocksTable extends Blocks with TableInfo<$BlocksTable, BlockEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BlocksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pageIdMeta = const VerificationMeta('pageId');
  @override
  late final GeneratedColumn<String> pageId = GeneratedColumn<String>(
      'page_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _parentBlockIdMeta =
      const VerificationMeta('parentBlockId');
  @override
  late final GeneratedColumn<String> parentBlockId = GeneratedColumn<String>(
      'parent_block_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _blockTypeMeta =
      const VerificationMeta('blockType');
  @override
  late final GeneratedColumn<String> blockType = GeneratedColumn<String>(
      'block_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _orderKeyMeta =
      const VerificationMeta('orderKey');
  @override
  late final GeneratedColumn<String> orderKey = GeneratedColumn<String>(
      'order_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentJsonMeta =
      const VerificationMeta('contentJson');
  @override
  late final GeneratedColumn<String> contentJson = GeneratedColumn<String>(
      'content_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _isArchivedMeta =
      const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
      'is_archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        pageId,
        parentBlockId,
        blockType,
        orderKey,
        contentJson,
        isArchived,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'blocks';
  @override
  VerificationContext validateIntegrity(Insertable<BlockEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('page_id')) {
      context.handle(_pageIdMeta,
          pageId.isAcceptableOrUnknown(data['page_id']!, _pageIdMeta));
    } else if (isInserting) {
      context.missing(_pageIdMeta);
    }
    if (data.containsKey('parent_block_id')) {
      context.handle(
          _parentBlockIdMeta,
          parentBlockId.isAcceptableOrUnknown(
              data['parent_block_id']!, _parentBlockIdMeta));
    }
    if (data.containsKey('block_type')) {
      context.handle(_blockTypeMeta,
          blockType.isAcceptableOrUnknown(data['block_type']!, _blockTypeMeta));
    } else if (isInserting) {
      context.missing(_blockTypeMeta);
    }
    if (data.containsKey('order_key')) {
      context.handle(_orderKeyMeta,
          orderKey.isAcceptableOrUnknown(data['order_key']!, _orderKeyMeta));
    } else if (isInserting) {
      context.missing(_orderKeyMeta);
    }
    if (data.containsKey('content_json')) {
      context.handle(
          _contentJsonMeta,
          contentJson.isAcceptableOrUnknown(
              data['content_json']!, _contentJsonMeta));
    }
    if (data.containsKey('is_archived')) {
      context.handle(
          _isArchivedMeta,
          isArchived.isAcceptableOrUnknown(
              data['is_archived']!, _isArchivedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BlockEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BlockEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      pageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}page_id'])!,
      parentBlockId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_block_id']),
      blockType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}block_type'])!,
      orderKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}order_key'])!,
      contentJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_json'])!,
      isArchived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_archived'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $BlocksTable createAlias(String alias) {
    return $BlocksTable(attachedDatabase, alias);
  }
}

class BlockEntry extends DataClass implements Insertable<BlockEntry> {
  final String id;
  final String pageId;
  final String? parentBlockId;
  final String blockType;
  final String orderKey;
  final String contentJson;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BlockEntry(
      {required this.id,
      required this.pageId,
      this.parentBlockId,
      required this.blockType,
      required this.orderKey,
      required this.contentJson,
      required this.isArchived,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['page_id'] = Variable<String>(pageId);
    if (!nullToAbsent || parentBlockId != null) {
      map['parent_block_id'] = Variable<String>(parentBlockId);
    }
    map['block_type'] = Variable<String>(blockType);
    map['order_key'] = Variable<String>(orderKey);
    map['content_json'] = Variable<String>(contentJson);
    map['is_archived'] = Variable<bool>(isArchived);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BlocksCompanion toCompanion(bool nullToAbsent) {
    return BlocksCompanion(
      id: Value(id),
      pageId: Value(pageId),
      parentBlockId: parentBlockId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentBlockId),
      blockType: Value(blockType),
      orderKey: Value(orderKey),
      contentJson: Value(contentJson),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BlockEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BlockEntry(
      id: serializer.fromJson<String>(json['id']),
      pageId: serializer.fromJson<String>(json['pageId']),
      parentBlockId: serializer.fromJson<String?>(json['parentBlockId']),
      blockType: serializer.fromJson<String>(json['blockType']),
      orderKey: serializer.fromJson<String>(json['orderKey']),
      contentJson: serializer.fromJson<String>(json['contentJson']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pageId': serializer.toJson<String>(pageId),
      'parentBlockId': serializer.toJson<String?>(parentBlockId),
      'blockType': serializer.toJson<String>(blockType),
      'orderKey': serializer.toJson<String>(orderKey),
      'contentJson': serializer.toJson<String>(contentJson),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BlockEntry copyWith(
          {String? id,
          String? pageId,
          Value<String?> parentBlockId = const Value.absent(),
          String? blockType,
          String? orderKey,
          String? contentJson,
          bool? isArchived,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      BlockEntry(
        id: id ?? this.id,
        pageId: pageId ?? this.pageId,
        parentBlockId:
            parentBlockId.present ? parentBlockId.value : this.parentBlockId,
        blockType: blockType ?? this.blockType,
        orderKey: orderKey ?? this.orderKey,
        contentJson: contentJson ?? this.contentJson,
        isArchived: isArchived ?? this.isArchived,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  BlockEntry copyWithCompanion(BlocksCompanion data) {
    return BlockEntry(
      id: data.id.present ? data.id.value : this.id,
      pageId: data.pageId.present ? data.pageId.value : this.pageId,
      parentBlockId: data.parentBlockId.present
          ? data.parentBlockId.value
          : this.parentBlockId,
      blockType: data.blockType.present ? data.blockType.value : this.blockType,
      orderKey: data.orderKey.present ? data.orderKey.value : this.orderKey,
      contentJson:
          data.contentJson.present ? data.contentJson.value : this.contentJson,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BlockEntry(')
          ..write('id: $id, ')
          ..write('pageId: $pageId, ')
          ..write('parentBlockId: $parentBlockId, ')
          ..write('blockType: $blockType, ')
          ..write('orderKey: $orderKey, ')
          ..write('contentJson: $contentJson, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, pageId, parentBlockId, blockType,
      orderKey, contentJson, isArchived, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BlockEntry &&
          other.id == this.id &&
          other.pageId == this.pageId &&
          other.parentBlockId == this.parentBlockId &&
          other.blockType == this.blockType &&
          other.orderKey == this.orderKey &&
          other.contentJson == this.contentJson &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BlocksCompanion extends UpdateCompanion<BlockEntry> {
  final Value<String> id;
  final Value<String> pageId;
  final Value<String?> parentBlockId;
  final Value<String> blockType;
  final Value<String> orderKey;
  final Value<String> contentJson;
  final Value<bool> isArchived;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BlocksCompanion({
    this.id = const Value.absent(),
    this.pageId = const Value.absent(),
    this.parentBlockId = const Value.absent(),
    this.blockType = const Value.absent(),
    this.orderKey = const Value.absent(),
    this.contentJson = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BlocksCompanion.insert({
    required String id,
    required String pageId,
    this.parentBlockId = const Value.absent(),
    required String blockType,
    required String orderKey,
    this.contentJson = const Value.absent(),
    this.isArchived = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        pageId = Value(pageId),
        blockType = Value(blockType),
        orderKey = Value(orderKey),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<BlockEntry> custom({
    Expression<String>? id,
    Expression<String>? pageId,
    Expression<String>? parentBlockId,
    Expression<String>? blockType,
    Expression<String>? orderKey,
    Expression<String>? contentJson,
    Expression<bool>? isArchived,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pageId != null) 'page_id': pageId,
      if (parentBlockId != null) 'parent_block_id': parentBlockId,
      if (blockType != null) 'block_type': blockType,
      if (orderKey != null) 'order_key': orderKey,
      if (contentJson != null) 'content_json': contentJson,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BlocksCompanion copyWith(
      {Value<String>? id,
      Value<String>? pageId,
      Value<String?>? parentBlockId,
      Value<String>? blockType,
      Value<String>? orderKey,
      Value<String>? contentJson,
      Value<bool>? isArchived,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return BlocksCompanion(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      parentBlockId: parentBlockId ?? this.parentBlockId,
      blockType: blockType ?? this.blockType,
      orderKey: orderKey ?? this.orderKey,
      contentJson: contentJson ?? this.contentJson,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pageId.present) {
      map['page_id'] = Variable<String>(pageId.value);
    }
    if (parentBlockId.present) {
      map['parent_block_id'] = Variable<String>(parentBlockId.value);
    }
    if (blockType.present) {
      map['block_type'] = Variable<String>(blockType.value);
    }
    if (orderKey.present) {
      map['order_key'] = Variable<String>(orderKey.value);
    }
    if (contentJson.present) {
      map['content_json'] = Variable<String>(contentJson.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BlocksCompanion(')
          ..write('id: $id, ')
          ..write('pageId: $pageId, ')
          ..write('parentBlockId: $parentBlockId, ')
          ..write('blockType: $blockType, ')
          ..write('orderKey: $orderKey, ')
          ..write('contentJson: $contentJson, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SubjectsTable extends Subjects
    with TableInfo<$SubjectsTable, SubjectEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorHexMeta =
      const VerificationMeta('colorHex');
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
      'color_hex', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dailyGoalMinutesMeta =
      const VerificationMeta('dailyGoalMinutes');
  @override
  late final GeneratedColumn<int> dailyGoalMinutes = GeneratedColumn<int>(
      'daily_goal_minutes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(60));
  static const VerificationMeta _isArchivedMeta =
      const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
      'is_archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<double> sortOrder = GeneratedColumn<double>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        colorHex,
        icon,
        dailyGoalMinutes,
        isArchived,
        sortOrder,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subjects';
  @override
  VerificationContext validateIntegrity(Insertable<SubjectEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(_colorHexMeta,
          colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta));
    } else if (isInserting) {
      context.missing(_colorHexMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('daily_goal_minutes')) {
      context.handle(
          _dailyGoalMinutesMeta,
          dailyGoalMinutes.isAcceptableOrUnknown(
              data['daily_goal_minutes']!, _dailyGoalMinutesMeta));
    }
    if (data.containsKey('is_archived')) {
      context.handle(
          _isArchivedMeta,
          isArchived.isAcceptableOrUnknown(
              data['is_archived']!, _isArchivedMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SubjectEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubjectEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      colorHex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color_hex'])!,
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon']),
      dailyGoalMinutes: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}daily_goal_minutes'])!,
      isArchived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_archived'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SubjectsTable createAlias(String alias) {
    return $SubjectsTable(attachedDatabase, alias);
  }
}

class SubjectEntry extends DataClass implements Insertable<SubjectEntry> {
  final String id;
  final String name;
  final String colorHex;
  final String? icon;
  final int dailyGoalMinutes;
  final bool isArchived;
  final double sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SubjectEntry(
      {required this.id,
      required this.name,
      required this.colorHex,
      this.icon,
      required this.dailyGoalMinutes,
      required this.isArchived,
      required this.sortOrder,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['color_hex'] = Variable<String>(colorHex);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['daily_goal_minutes'] = Variable<int>(dailyGoalMinutes);
    map['is_archived'] = Variable<bool>(isArchived);
    map['sort_order'] = Variable<double>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SubjectsCompanion toCompanion(bool nullToAbsent) {
    return SubjectsCompanion(
      id: Value(id),
      name: Value(name),
      colorHex: Value(colorHex),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      dailyGoalMinutes: Value(dailyGoalMinutes),
      isArchived: Value(isArchived),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SubjectEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubjectEntry(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      icon: serializer.fromJson<String?>(json['icon']),
      dailyGoalMinutes: serializer.fromJson<int>(json['dailyGoalMinutes']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      sortOrder: serializer.fromJson<double>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'colorHex': serializer.toJson<String>(colorHex),
      'icon': serializer.toJson<String?>(icon),
      'dailyGoalMinutes': serializer.toJson<int>(dailyGoalMinutes),
      'isArchived': serializer.toJson<bool>(isArchived),
      'sortOrder': serializer.toJson<double>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SubjectEntry copyWith(
          {String? id,
          String? name,
          String? colorHex,
          Value<String?> icon = const Value.absent(),
          int? dailyGoalMinutes,
          bool? isArchived,
          double? sortOrder,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      SubjectEntry(
        id: id ?? this.id,
        name: name ?? this.name,
        colorHex: colorHex ?? this.colorHex,
        icon: icon.present ? icon.value : this.icon,
        dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
        isArchived: isArchived ?? this.isArchived,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SubjectEntry copyWithCompanion(SubjectsCompanion data) {
    return SubjectEntry(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      icon: data.icon.present ? data.icon.value : this.icon,
      dailyGoalMinutes: data.dailyGoalMinutes.present
          ? data.dailyGoalMinutes.value
          : this.dailyGoalMinutes,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubjectEntry(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorHex: $colorHex, ')
          ..write('icon: $icon, ')
          ..write('dailyGoalMinutes: $dailyGoalMinutes, ')
          ..write('isArchived: $isArchived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, colorHex, icon, dailyGoalMinutes,
      isArchived, sortOrder, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubjectEntry &&
          other.id == this.id &&
          other.name == this.name &&
          other.colorHex == this.colorHex &&
          other.icon == this.icon &&
          other.dailyGoalMinutes == this.dailyGoalMinutes &&
          other.isArchived == this.isArchived &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SubjectsCompanion extends UpdateCompanion<SubjectEntry> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> colorHex;
  final Value<String?> icon;
  final Value<int> dailyGoalMinutes;
  final Value<bool> isArchived;
  final Value<double> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SubjectsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.icon = const Value.absent(),
    this.dailyGoalMinutes = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubjectsCompanion.insert({
    required String id,
    required String name,
    required String colorHex,
    this.icon = const Value.absent(),
    this.dailyGoalMinutes = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        colorHex = Value(colorHex),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<SubjectEntry> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? colorHex,
    Expression<String>? icon,
    Expression<int>? dailyGoalMinutes,
    Expression<bool>? isArchived,
    Expression<double>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (colorHex != null) 'color_hex': colorHex,
      if (icon != null) 'icon': icon,
      if (dailyGoalMinutes != null) 'daily_goal_minutes': dailyGoalMinutes,
      if (isArchived != null) 'is_archived': isArchived,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubjectsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? colorHex,
      Value<String?>? icon,
      Value<int>? dailyGoalMinutes,
      Value<bool>? isArchived,
      Value<double>? sortOrder,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return SubjectsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      icon: icon ?? this.icon,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (dailyGoalMinutes.present) {
      map['daily_goal_minutes'] = Variable<int>(dailyGoalMinutes.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<double>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubjectsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorHex: $colorHex, ')
          ..write('icon: $icon, ')
          ..write('dailyGoalMinutes: $dailyGoalMinutes, ')
          ..write('isArchived: $isArchived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DatabasesTableTable extends DatabasesTable
    with TableInfo<$DatabasesTableTable, DatabaseEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DatabasesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pageIdMeta = const VerificationMeta('pageId');
  @override
  late final GeneratedColumn<String> pageId = GeneratedColumn<String>(
      'page_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Untitled Database'));
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _coverImageUrlMeta =
      const VerificationMeta('coverImageUrl');
  @override
  late final GeneratedColumn<String> coverImageUrl = GeneratedColumn<String>(
      'cover_image_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isArchivedMeta =
      const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
      'is_archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        pageId,
        title,
        icon,
        coverImageUrl,
        isArchived,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'databases';
  @override
  VerificationContext validateIntegrity(Insertable<DatabaseEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('page_id')) {
      context.handle(_pageIdMeta,
          pageId.isAcceptableOrUnknown(data['page_id']!, _pageIdMeta));
    } else if (isInserting) {
      context.missing(_pageIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('cover_image_url')) {
      context.handle(
          _coverImageUrlMeta,
          coverImageUrl.isAcceptableOrUnknown(
              data['cover_image_url']!, _coverImageUrlMeta));
    }
    if (data.containsKey('is_archived')) {
      context.handle(
          _isArchivedMeta,
          isArchived.isAcceptableOrUnknown(
              data['is_archived']!, _isArchivedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DatabaseEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DatabaseEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      pageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}page_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon']),
      coverImageUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_image_url']),
      isArchived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_archived'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $DatabasesTableTable createAlias(String alias) {
    return $DatabasesTableTable(attachedDatabase, alias);
  }
}

class DatabaseEntry extends DataClass implements Insertable<DatabaseEntry> {
  final String id;
  final String pageId;
  final String title;
  final String? icon;
  final String? coverImageUrl;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DatabaseEntry(
      {required this.id,
      required this.pageId,
      required this.title,
      this.icon,
      this.coverImageUrl,
      required this.isArchived,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['page_id'] = Variable<String>(pageId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || coverImageUrl != null) {
      map['cover_image_url'] = Variable<String>(coverImageUrl);
    }
    map['is_archived'] = Variable<bool>(isArchived);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DatabasesTableCompanion toCompanion(bool nullToAbsent) {
    return DatabasesTableCompanion(
      id: Value(id),
      pageId: Value(pageId),
      title: Value(title),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      coverImageUrl: coverImageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverImageUrl),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DatabaseEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DatabaseEntry(
      id: serializer.fromJson<String>(json['id']),
      pageId: serializer.fromJson<String>(json['pageId']),
      title: serializer.fromJson<String>(json['title']),
      icon: serializer.fromJson<String?>(json['icon']),
      coverImageUrl: serializer.fromJson<String?>(json['coverImageUrl']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pageId': serializer.toJson<String>(pageId),
      'title': serializer.toJson<String>(title),
      'icon': serializer.toJson<String?>(icon),
      'coverImageUrl': serializer.toJson<String?>(coverImageUrl),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DatabaseEntry copyWith(
          {String? id,
          String? pageId,
          String? title,
          Value<String?> icon = const Value.absent(),
          Value<String?> coverImageUrl = const Value.absent(),
          bool? isArchived,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      DatabaseEntry(
        id: id ?? this.id,
        pageId: pageId ?? this.pageId,
        title: title ?? this.title,
        icon: icon.present ? icon.value : this.icon,
        coverImageUrl:
            coverImageUrl.present ? coverImageUrl.value : this.coverImageUrl,
        isArchived: isArchived ?? this.isArchived,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  DatabaseEntry copyWithCompanion(DatabasesTableCompanion data) {
    return DatabaseEntry(
      id: data.id.present ? data.id.value : this.id,
      pageId: data.pageId.present ? data.pageId.value : this.pageId,
      title: data.title.present ? data.title.value : this.title,
      icon: data.icon.present ? data.icon.value : this.icon,
      coverImageUrl: data.coverImageUrl.present
          ? data.coverImageUrl.value
          : this.coverImageUrl,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DatabaseEntry(')
          ..write('id: $id, ')
          ..write('pageId: $pageId, ')
          ..write('title: $title, ')
          ..write('icon: $icon, ')
          ..write('coverImageUrl: $coverImageUrl, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, pageId, title, icon, coverImageUrl, isArchived, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DatabaseEntry &&
          other.id == this.id &&
          other.pageId == this.pageId &&
          other.title == this.title &&
          other.icon == this.icon &&
          other.coverImageUrl == this.coverImageUrl &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DatabasesTableCompanion extends UpdateCompanion<DatabaseEntry> {
  final Value<String> id;
  final Value<String> pageId;
  final Value<String> title;
  final Value<String?> icon;
  final Value<String?> coverImageUrl;
  final Value<bool> isArchived;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DatabasesTableCompanion({
    this.id = const Value.absent(),
    this.pageId = const Value.absent(),
    this.title = const Value.absent(),
    this.icon = const Value.absent(),
    this.coverImageUrl = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DatabasesTableCompanion.insert({
    required String id,
    required String pageId,
    this.title = const Value.absent(),
    this.icon = const Value.absent(),
    this.coverImageUrl = const Value.absent(),
    this.isArchived = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        pageId = Value(pageId),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<DatabaseEntry> custom({
    Expression<String>? id,
    Expression<String>? pageId,
    Expression<String>? title,
    Expression<String>? icon,
    Expression<String>? coverImageUrl,
    Expression<bool>? isArchived,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pageId != null) 'page_id': pageId,
      if (title != null) 'title': title,
      if (icon != null) 'icon': icon,
      if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DatabasesTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? pageId,
      Value<String>? title,
      Value<String?>? icon,
      Value<String?>? coverImageUrl,
      Value<bool>? isArchived,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return DatabasesTableCompanion(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pageId.present) {
      map['page_id'] = Variable<String>(pageId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (coverImageUrl.present) {
      map['cover_image_url'] = Variable<String>(coverImageUrl.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DatabasesTableCompanion(')
          ..write('id: $id, ')
          ..write('pageId: $pageId, ')
          ..write('title: $title, ')
          ..write('icon: $icon, ')
          ..write('coverImageUrl: $coverImageUrl, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DatabasePropertiesTableTable extends DatabasePropertiesTable
    with TableInfo<$DatabasePropertiesTableTable, DatabasePropertyEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DatabasePropertiesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _databaseIdMeta =
      const VerificationMeta('databaseId');
  @override
  late final GeneratedColumn<String> databaseId = GeneratedColumn<String>(
      'database_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _propertyTypeMeta =
      const VerificationMeta('propertyType');
  @override
  late final GeneratedColumn<String> propertyType = GeneratedColumn<String>(
      'property_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<double> sortOrder = GeneratedColumn<double>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _configJsonMeta =
      const VerificationMeta('configJson');
  @override
  late final GeneratedColumn<String> configJson = GeneratedColumn<String>(
      'config_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        databaseId,
        name,
        propertyType,
        sortOrder,
        configJson,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'database_properties';
  @override
  VerificationContext validateIntegrity(
      Insertable<DatabasePropertyEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('database_id')) {
      context.handle(
          _databaseIdMeta,
          databaseId.isAcceptableOrUnknown(
              data['database_id']!, _databaseIdMeta));
    } else if (isInserting) {
      context.missing(_databaseIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('property_type')) {
      context.handle(
          _propertyTypeMeta,
          propertyType.isAcceptableOrUnknown(
              data['property_type']!, _propertyTypeMeta));
    } else if (isInserting) {
      context.missing(_propertyTypeMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('config_json')) {
      context.handle(
          _configJsonMeta,
          configJson.isAcceptableOrUnknown(
              data['config_json']!, _configJsonMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DatabasePropertyEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DatabasePropertyEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      databaseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}database_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      propertyType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}property_type'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}sort_order'])!,
      configJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}config_json'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $DatabasePropertiesTableTable createAlias(String alias) {
    return $DatabasePropertiesTableTable(attachedDatabase, alias);
  }
}

class DatabasePropertyEntry extends DataClass
    implements Insertable<DatabasePropertyEntry> {
  final String id;
  final String databaseId;
  final String name;
  final String propertyType;
  final double sortOrder;
  final String configJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DatabasePropertyEntry(
      {required this.id,
      required this.databaseId,
      required this.name,
      required this.propertyType,
      required this.sortOrder,
      required this.configJson,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['database_id'] = Variable<String>(databaseId);
    map['name'] = Variable<String>(name);
    map['property_type'] = Variable<String>(propertyType);
    map['sort_order'] = Variable<double>(sortOrder);
    map['config_json'] = Variable<String>(configJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DatabasePropertiesTableCompanion toCompanion(bool nullToAbsent) {
    return DatabasePropertiesTableCompanion(
      id: Value(id),
      databaseId: Value(databaseId),
      name: Value(name),
      propertyType: Value(propertyType),
      sortOrder: Value(sortOrder),
      configJson: Value(configJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DatabasePropertyEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DatabasePropertyEntry(
      id: serializer.fromJson<String>(json['id']),
      databaseId: serializer.fromJson<String>(json['databaseId']),
      name: serializer.fromJson<String>(json['name']),
      propertyType: serializer.fromJson<String>(json['propertyType']),
      sortOrder: serializer.fromJson<double>(json['sortOrder']),
      configJson: serializer.fromJson<String>(json['configJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'databaseId': serializer.toJson<String>(databaseId),
      'name': serializer.toJson<String>(name),
      'propertyType': serializer.toJson<String>(propertyType),
      'sortOrder': serializer.toJson<double>(sortOrder),
      'configJson': serializer.toJson<String>(configJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DatabasePropertyEntry copyWith(
          {String? id,
          String? databaseId,
          String? name,
          String? propertyType,
          double? sortOrder,
          String? configJson,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      DatabasePropertyEntry(
        id: id ?? this.id,
        databaseId: databaseId ?? this.databaseId,
        name: name ?? this.name,
        propertyType: propertyType ?? this.propertyType,
        sortOrder: sortOrder ?? this.sortOrder,
        configJson: configJson ?? this.configJson,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  DatabasePropertyEntry copyWithCompanion(
      DatabasePropertiesTableCompanion data) {
    return DatabasePropertyEntry(
      id: data.id.present ? data.id.value : this.id,
      databaseId:
          data.databaseId.present ? data.databaseId.value : this.databaseId,
      name: data.name.present ? data.name.value : this.name,
      propertyType: data.propertyType.present
          ? data.propertyType.value
          : this.propertyType,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      configJson:
          data.configJson.present ? data.configJson.value : this.configJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DatabasePropertyEntry(')
          ..write('id: $id, ')
          ..write('databaseId: $databaseId, ')
          ..write('name: $name, ')
          ..write('propertyType: $propertyType, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('configJson: $configJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, databaseId, name, propertyType, sortOrder,
      configJson, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DatabasePropertyEntry &&
          other.id == this.id &&
          other.databaseId == this.databaseId &&
          other.name == this.name &&
          other.propertyType == this.propertyType &&
          other.sortOrder == this.sortOrder &&
          other.configJson == this.configJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DatabasePropertiesTableCompanion
    extends UpdateCompanion<DatabasePropertyEntry> {
  final Value<String> id;
  final Value<String> databaseId;
  final Value<String> name;
  final Value<String> propertyType;
  final Value<double> sortOrder;
  final Value<String> configJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DatabasePropertiesTableCompanion({
    this.id = const Value.absent(),
    this.databaseId = const Value.absent(),
    this.name = const Value.absent(),
    this.propertyType = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.configJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DatabasePropertiesTableCompanion.insert({
    required String id,
    required String databaseId,
    required String name,
    required String propertyType,
    this.sortOrder = const Value.absent(),
    this.configJson = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        databaseId = Value(databaseId),
        name = Value(name),
        propertyType = Value(propertyType),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<DatabasePropertyEntry> custom({
    Expression<String>? id,
    Expression<String>? databaseId,
    Expression<String>? name,
    Expression<String>? propertyType,
    Expression<double>? sortOrder,
    Expression<String>? configJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (databaseId != null) 'database_id': databaseId,
      if (name != null) 'name': name,
      if (propertyType != null) 'property_type': propertyType,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (configJson != null) 'config_json': configJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DatabasePropertiesTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? databaseId,
      Value<String>? name,
      Value<String>? propertyType,
      Value<double>? sortOrder,
      Value<String>? configJson,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return DatabasePropertiesTableCompanion(
      id: id ?? this.id,
      databaseId: databaseId ?? this.databaseId,
      name: name ?? this.name,
      propertyType: propertyType ?? this.propertyType,
      sortOrder: sortOrder ?? this.sortOrder,
      configJson: configJson ?? this.configJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (databaseId.present) {
      map['database_id'] = Variable<String>(databaseId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (propertyType.present) {
      map['property_type'] = Variable<String>(propertyType.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<double>(sortOrder.value);
    }
    if (configJson.present) {
      map['config_json'] = Variable<String>(configJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DatabasePropertiesTableCompanion(')
          ..write('id: $id, ')
          ..write('databaseId: $databaseId, ')
          ..write('name: $name, ')
          ..write('propertyType: $propertyType, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('configJson: $configJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DatabaseRowsTableTable extends DatabaseRowsTable
    with TableInfo<$DatabaseRowsTableTable, DatabaseRowEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DatabaseRowsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _databaseIdMeta =
      const VerificationMeta('databaseId');
  @override
  late final GeneratedColumn<String> databaseId = GeneratedColumn<String>(
      'database_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pageIdMeta = const VerificationMeta('pageId');
  @override
  late final GeneratedColumn<String> pageId = GeneratedColumn<String>(
      'page_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<double> sortOrder = GeneratedColumn<double>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, databaseId, pageId, sortOrder, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'database_rows';
  @override
  VerificationContext validateIntegrity(Insertable<DatabaseRowEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('database_id')) {
      context.handle(
          _databaseIdMeta,
          databaseId.isAcceptableOrUnknown(
              data['database_id']!, _databaseIdMeta));
    } else if (isInserting) {
      context.missing(_databaseIdMeta);
    }
    if (data.containsKey('page_id')) {
      context.handle(_pageIdMeta,
          pageId.isAcceptableOrUnknown(data['page_id']!, _pageIdMeta));
    } else if (isInserting) {
      context.missing(_pageIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DatabaseRowEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DatabaseRowEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      databaseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}database_id'])!,
      pageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}page_id'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $DatabaseRowsTableTable createAlias(String alias) {
    return $DatabaseRowsTableTable(attachedDatabase, alias);
  }
}

class DatabaseRowEntry extends DataClass
    implements Insertable<DatabaseRowEntry> {
  final String id;
  final String databaseId;
  final String pageId;
  final double sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DatabaseRowEntry(
      {required this.id,
      required this.databaseId,
      required this.pageId,
      required this.sortOrder,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['database_id'] = Variable<String>(databaseId);
    map['page_id'] = Variable<String>(pageId);
    map['sort_order'] = Variable<double>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DatabaseRowsTableCompanion toCompanion(bool nullToAbsent) {
    return DatabaseRowsTableCompanion(
      id: Value(id),
      databaseId: Value(databaseId),
      pageId: Value(pageId),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DatabaseRowEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DatabaseRowEntry(
      id: serializer.fromJson<String>(json['id']),
      databaseId: serializer.fromJson<String>(json['databaseId']),
      pageId: serializer.fromJson<String>(json['pageId']),
      sortOrder: serializer.fromJson<double>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'databaseId': serializer.toJson<String>(databaseId),
      'pageId': serializer.toJson<String>(pageId),
      'sortOrder': serializer.toJson<double>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DatabaseRowEntry copyWith(
          {String? id,
          String? databaseId,
          String? pageId,
          double? sortOrder,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      DatabaseRowEntry(
        id: id ?? this.id,
        databaseId: databaseId ?? this.databaseId,
        pageId: pageId ?? this.pageId,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  DatabaseRowEntry copyWithCompanion(DatabaseRowsTableCompanion data) {
    return DatabaseRowEntry(
      id: data.id.present ? data.id.value : this.id,
      databaseId:
          data.databaseId.present ? data.databaseId.value : this.databaseId,
      pageId: data.pageId.present ? data.pageId.value : this.pageId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DatabaseRowEntry(')
          ..write('id: $id, ')
          ..write('databaseId: $databaseId, ')
          ..write('pageId: $pageId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, databaseId, pageId, sortOrder, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DatabaseRowEntry &&
          other.id == this.id &&
          other.databaseId == this.databaseId &&
          other.pageId == this.pageId &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DatabaseRowsTableCompanion extends UpdateCompanion<DatabaseRowEntry> {
  final Value<String> id;
  final Value<String> databaseId;
  final Value<String> pageId;
  final Value<double> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DatabaseRowsTableCompanion({
    this.id = const Value.absent(),
    this.databaseId = const Value.absent(),
    this.pageId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DatabaseRowsTableCompanion.insert({
    required String id,
    required String databaseId,
    required String pageId,
    this.sortOrder = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        databaseId = Value(databaseId),
        pageId = Value(pageId),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<DatabaseRowEntry> custom({
    Expression<String>? id,
    Expression<String>? databaseId,
    Expression<String>? pageId,
    Expression<double>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (databaseId != null) 'database_id': databaseId,
      if (pageId != null) 'page_id': pageId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DatabaseRowsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? databaseId,
      Value<String>? pageId,
      Value<double>? sortOrder,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return DatabaseRowsTableCompanion(
      id: id ?? this.id,
      databaseId: databaseId ?? this.databaseId,
      pageId: pageId ?? this.pageId,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (databaseId.present) {
      map['database_id'] = Variable<String>(databaseId.value);
    }
    if (pageId.present) {
      map['page_id'] = Variable<String>(pageId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<double>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DatabaseRowsTableCompanion(')
          ..write('id: $id, ')
          ..write('databaseId: $databaseId, ')
          ..write('pageId: $pageId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DatabaseCellsTableTable extends DatabaseCellsTable
    with TableInfo<$DatabaseCellsTableTable, DatabaseCellEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DatabaseCellsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<String> rowId = GeneratedColumn<String>(
      'row_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _propertyIdMeta =
      const VerificationMeta('propertyId');
  @override
  late final GeneratedColumn<String> propertyId = GeneratedColumn<String>(
      'property_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueJsonMeta =
      const VerificationMeta('valueJson');
  @override
  late final GeneratedColumn<String> valueJson = GeneratedColumn<String>(
      'value_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, rowId, propertyId, valueJson, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'database_cells';
  @override
  VerificationContext validateIntegrity(Insertable<DatabaseCellEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('row_id')) {
      context.handle(
          _rowIdMeta, rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta));
    } else if (isInserting) {
      context.missing(_rowIdMeta);
    }
    if (data.containsKey('property_id')) {
      context.handle(
          _propertyIdMeta,
          propertyId.isAcceptableOrUnknown(
              data['property_id']!, _propertyIdMeta));
    } else if (isInserting) {
      context.missing(_propertyIdMeta);
    }
    if (data.containsKey('value_json')) {
      context.handle(_valueJsonMeta,
          valueJson.isAcceptableOrUnknown(data['value_json']!, _valueJsonMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DatabaseCellEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DatabaseCellEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      rowId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}row_id'])!,
      propertyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}property_id'])!,
      valueJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value_json']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $DatabaseCellsTableTable createAlias(String alias) {
    return $DatabaseCellsTableTable(attachedDatabase, alias);
  }
}

class DatabaseCellEntry extends DataClass
    implements Insertable<DatabaseCellEntry> {
  final String id;
  final String rowId;
  final String propertyId;
  final String? valueJson;
  final DateTime updatedAt;
  const DatabaseCellEntry(
      {required this.id,
      required this.rowId,
      required this.propertyId,
      this.valueJson,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['row_id'] = Variable<String>(rowId);
    map['property_id'] = Variable<String>(propertyId);
    if (!nullToAbsent || valueJson != null) {
      map['value_json'] = Variable<String>(valueJson);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DatabaseCellsTableCompanion toCompanion(bool nullToAbsent) {
    return DatabaseCellsTableCompanion(
      id: Value(id),
      rowId: Value(rowId),
      propertyId: Value(propertyId),
      valueJson: valueJson == null && nullToAbsent
          ? const Value.absent()
          : Value(valueJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory DatabaseCellEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DatabaseCellEntry(
      id: serializer.fromJson<String>(json['id']),
      rowId: serializer.fromJson<String>(json['rowId']),
      propertyId: serializer.fromJson<String>(json['propertyId']),
      valueJson: serializer.fromJson<String?>(json['valueJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'rowId': serializer.toJson<String>(rowId),
      'propertyId': serializer.toJson<String>(propertyId),
      'valueJson': serializer.toJson<String?>(valueJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DatabaseCellEntry copyWith(
          {String? id,
          String? rowId,
          String? propertyId,
          Value<String?> valueJson = const Value.absent(),
          DateTime? updatedAt}) =>
      DatabaseCellEntry(
        id: id ?? this.id,
        rowId: rowId ?? this.rowId,
        propertyId: propertyId ?? this.propertyId,
        valueJson: valueJson.present ? valueJson.value : this.valueJson,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  DatabaseCellEntry copyWithCompanion(DatabaseCellsTableCompanion data) {
    return DatabaseCellEntry(
      id: data.id.present ? data.id.value : this.id,
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      propertyId:
          data.propertyId.present ? data.propertyId.value : this.propertyId,
      valueJson: data.valueJson.present ? data.valueJson.value : this.valueJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DatabaseCellEntry(')
          ..write('id: $id, ')
          ..write('rowId: $rowId, ')
          ..write('propertyId: $propertyId, ')
          ..write('valueJson: $valueJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, rowId, propertyId, valueJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DatabaseCellEntry &&
          other.id == this.id &&
          other.rowId == this.rowId &&
          other.propertyId == this.propertyId &&
          other.valueJson == this.valueJson &&
          other.updatedAt == this.updatedAt);
}

class DatabaseCellsTableCompanion extends UpdateCompanion<DatabaseCellEntry> {
  final Value<String> id;
  final Value<String> rowId;
  final Value<String> propertyId;
  final Value<String?> valueJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DatabaseCellsTableCompanion({
    this.id = const Value.absent(),
    this.rowId = const Value.absent(),
    this.propertyId = const Value.absent(),
    this.valueJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DatabaseCellsTableCompanion.insert({
    required String id,
    required String rowId,
    required String propertyId,
    this.valueJson = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        rowId = Value(rowId),
        propertyId = Value(propertyId),
        updatedAt = Value(updatedAt);
  static Insertable<DatabaseCellEntry> custom({
    Expression<String>? id,
    Expression<String>? rowId,
    Expression<String>? propertyId,
    Expression<String>? valueJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rowId != null) 'row_id': rowId,
      if (propertyId != null) 'property_id': propertyId,
      if (valueJson != null) 'value_json': valueJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DatabaseCellsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? rowId,
      Value<String>? propertyId,
      Value<String?>? valueJson,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return DatabaseCellsTableCompanion(
      id: id ?? this.id,
      rowId: rowId ?? this.rowId,
      propertyId: propertyId ?? this.propertyId,
      valueJson: valueJson ?? this.valueJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (rowId.present) {
      map['row_id'] = Variable<String>(rowId.value);
    }
    if (propertyId.present) {
      map['property_id'] = Variable<String>(propertyId.value);
    }
    if (valueJson.present) {
      map['value_json'] = Variable<String>(valueJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DatabaseCellsTableCompanion(')
          ..write('id: $id, ')
          ..write('rowId: $rowId, ')
          ..write('propertyId: $propertyId, ')
          ..write('valueJson: $valueJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DatabaseViewsTableTable extends DatabaseViewsTable
    with TableInfo<$DatabaseViewsTableTable, DatabaseViewEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DatabaseViewsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _databaseIdMeta =
      const VerificationMeta('databaseId');
  @override
  late final GeneratedColumn<String> databaseId = GeneratedColumn<String>(
      'database_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Default View'));
  static const VerificationMeta _viewTypeMeta =
      const VerificationMeta('viewType');
  @override
  late final GeneratedColumn<String> viewType = GeneratedColumn<String>(
      'view_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<double> sortOrder = GeneratedColumn<double>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _configJsonMeta =
      const VerificationMeta('configJson');
  @override
  late final GeneratedColumn<String> configJson = GeneratedColumn<String>(
      'config_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        databaseId,
        name,
        viewType,
        sortOrder,
        configJson,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'database_views';
  @override
  VerificationContext validateIntegrity(Insertable<DatabaseViewEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('database_id')) {
      context.handle(
          _databaseIdMeta,
          databaseId.isAcceptableOrUnknown(
              data['database_id']!, _databaseIdMeta));
    } else if (isInserting) {
      context.missing(_databaseIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('view_type')) {
      context.handle(_viewTypeMeta,
          viewType.isAcceptableOrUnknown(data['view_type']!, _viewTypeMeta));
    } else if (isInserting) {
      context.missing(_viewTypeMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('config_json')) {
      context.handle(
          _configJsonMeta,
          configJson.isAcceptableOrUnknown(
              data['config_json']!, _configJsonMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DatabaseViewEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DatabaseViewEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      databaseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}database_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      viewType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}view_type'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}sort_order'])!,
      configJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}config_json'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $DatabaseViewsTableTable createAlias(String alias) {
    return $DatabaseViewsTableTable(attachedDatabase, alias);
  }
}

class DatabaseViewEntry extends DataClass
    implements Insertable<DatabaseViewEntry> {
  final String id;
  final String databaseId;
  final String name;
  final String viewType;
  final double sortOrder;
  final String configJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DatabaseViewEntry(
      {required this.id,
      required this.databaseId,
      required this.name,
      required this.viewType,
      required this.sortOrder,
      required this.configJson,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['database_id'] = Variable<String>(databaseId);
    map['name'] = Variable<String>(name);
    map['view_type'] = Variable<String>(viewType);
    map['sort_order'] = Variable<double>(sortOrder);
    map['config_json'] = Variable<String>(configJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DatabaseViewsTableCompanion toCompanion(bool nullToAbsent) {
    return DatabaseViewsTableCompanion(
      id: Value(id),
      databaseId: Value(databaseId),
      name: Value(name),
      viewType: Value(viewType),
      sortOrder: Value(sortOrder),
      configJson: Value(configJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DatabaseViewEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DatabaseViewEntry(
      id: serializer.fromJson<String>(json['id']),
      databaseId: serializer.fromJson<String>(json['databaseId']),
      name: serializer.fromJson<String>(json['name']),
      viewType: serializer.fromJson<String>(json['viewType']),
      sortOrder: serializer.fromJson<double>(json['sortOrder']),
      configJson: serializer.fromJson<String>(json['configJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'databaseId': serializer.toJson<String>(databaseId),
      'name': serializer.toJson<String>(name),
      'viewType': serializer.toJson<String>(viewType),
      'sortOrder': serializer.toJson<double>(sortOrder),
      'configJson': serializer.toJson<String>(configJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DatabaseViewEntry copyWith(
          {String? id,
          String? databaseId,
          String? name,
          String? viewType,
          double? sortOrder,
          String? configJson,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      DatabaseViewEntry(
        id: id ?? this.id,
        databaseId: databaseId ?? this.databaseId,
        name: name ?? this.name,
        viewType: viewType ?? this.viewType,
        sortOrder: sortOrder ?? this.sortOrder,
        configJson: configJson ?? this.configJson,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  DatabaseViewEntry copyWithCompanion(DatabaseViewsTableCompanion data) {
    return DatabaseViewEntry(
      id: data.id.present ? data.id.value : this.id,
      databaseId:
          data.databaseId.present ? data.databaseId.value : this.databaseId,
      name: data.name.present ? data.name.value : this.name,
      viewType: data.viewType.present ? data.viewType.value : this.viewType,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      configJson:
          data.configJson.present ? data.configJson.value : this.configJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DatabaseViewEntry(')
          ..write('id: $id, ')
          ..write('databaseId: $databaseId, ')
          ..write('name: $name, ')
          ..write('viewType: $viewType, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('configJson: $configJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, databaseId, name, viewType, sortOrder,
      configJson, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DatabaseViewEntry &&
          other.id == this.id &&
          other.databaseId == this.databaseId &&
          other.name == this.name &&
          other.viewType == this.viewType &&
          other.sortOrder == this.sortOrder &&
          other.configJson == this.configJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DatabaseViewsTableCompanion extends UpdateCompanion<DatabaseViewEntry> {
  final Value<String> id;
  final Value<String> databaseId;
  final Value<String> name;
  final Value<String> viewType;
  final Value<double> sortOrder;
  final Value<String> configJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DatabaseViewsTableCompanion({
    this.id = const Value.absent(),
    this.databaseId = const Value.absent(),
    this.name = const Value.absent(),
    this.viewType = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.configJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DatabaseViewsTableCompanion.insert({
    required String id,
    required String databaseId,
    this.name = const Value.absent(),
    required String viewType,
    this.sortOrder = const Value.absent(),
    this.configJson = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        databaseId = Value(databaseId),
        viewType = Value(viewType),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<DatabaseViewEntry> custom({
    Expression<String>? id,
    Expression<String>? databaseId,
    Expression<String>? name,
    Expression<String>? viewType,
    Expression<double>? sortOrder,
    Expression<String>? configJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (databaseId != null) 'database_id': databaseId,
      if (name != null) 'name': name,
      if (viewType != null) 'view_type': viewType,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (configJson != null) 'config_json': configJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DatabaseViewsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? databaseId,
      Value<String>? name,
      Value<String>? viewType,
      Value<double>? sortOrder,
      Value<String>? configJson,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return DatabaseViewsTableCompanion(
      id: id ?? this.id,
      databaseId: databaseId ?? this.databaseId,
      name: name ?? this.name,
      viewType: viewType ?? this.viewType,
      sortOrder: sortOrder ?? this.sortOrder,
      configJson: configJson ?? this.configJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (databaseId.present) {
      map['database_id'] = Variable<String>(databaseId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (viewType.present) {
      map['view_type'] = Variable<String>(viewType.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<double>(sortOrder.value);
    }
    if (configJson.present) {
      map['config_json'] = Variable<String>(configJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DatabaseViewsTableCompanion(')
          ..write('id: $id, ')
          ..write('databaseId: $databaseId, ')
          ..write('name: $name, ')
          ..write('viewType: $viewType, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('configJson: $configJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StudySessionsTableTable extends StudySessionsTable
    with TableInfo<$StudySessionsTableTable, StudySessionEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudySessionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subjectIdMeta =
      const VerificationMeta('subjectId');
  @override
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
      'subject_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pageIdMeta = const VerificationMeta('pageId');
  @override
  late final GeneratedColumn<String> pageId = GeneratedColumn<String>(
      'page_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sessionTypeMeta =
      const VerificationMeta('sessionType');
  @override
  late final GeneratedColumn<String> sessionType = GeneratedColumn<String>(
      'session_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
      'start_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
      'end_time', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
      'duration_seconds', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _targetSecondsMeta =
      const VerificationMeta('targetSeconds');
  @override
  late final GeneratedColumn<int> targetSeconds = GeneratedColumn<int>(
      'target_seconds', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _pauseDurationSecondsMeta =
      const VerificationMeta('pauseDurationSeconds');
  @override
  late final GeneratedColumn<int> pauseDurationSeconds = GeneratedColumn<int>(
      'pause_duration_seconds', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lapCountMeta =
      const VerificationMeta('lapCount');
  @override
  late final GeneratedColumn<int> lapCount = GeneratedColumn<int>(
      'lap_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isCompletedMeta =
      const VerificationMeta('isCompleted');
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
      'is_completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isDiscardedMeta =
      const VerificationMeta('isDiscarded');
  @override
  late final GeneratedColumn<bool> isDiscarded = GeneratedColumn<bool>(
      'is_discarded', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_discarded" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        subjectId,
        pageId,
        sessionType,
        startTime,
        endTime,
        durationSeconds,
        targetSeconds,
        pauseDurationSeconds,
        lapCount,
        isCompleted,
        isDiscarded,
        notes,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'study_sessions_table';
  @override
  VerificationContext validateIntegrity(Insertable<StudySessionEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(_subjectIdMeta,
          subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta));
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('page_id')) {
      context.handle(_pageIdMeta,
          pageId.isAcceptableOrUnknown(data['page_id']!, _pageIdMeta));
    }
    if (data.containsKey('session_type')) {
      context.handle(
          _sessionTypeMeta,
          sessionType.isAcceptableOrUnknown(
              data['session_type']!, _sessionTypeMeta));
    } else if (isInserting) {
      context.missing(_sessionTypeMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    }
    if (data.containsKey('target_seconds')) {
      context.handle(
          _targetSecondsMeta,
          targetSeconds.isAcceptableOrUnknown(
              data['target_seconds']!, _targetSecondsMeta));
    }
    if (data.containsKey('pause_duration_seconds')) {
      context.handle(
          _pauseDurationSecondsMeta,
          pauseDurationSeconds.isAcceptableOrUnknown(
              data['pause_duration_seconds']!, _pauseDurationSecondsMeta));
    }
    if (data.containsKey('lap_count')) {
      context.handle(_lapCountMeta,
          lapCount.isAcceptableOrUnknown(data['lap_count']!, _lapCountMeta));
    }
    if (data.containsKey('is_completed')) {
      context.handle(
          _isCompletedMeta,
          isCompleted.isAcceptableOrUnknown(
              data['is_completed']!, _isCompletedMeta));
    }
    if (data.containsKey('is_discarded')) {
      context.handle(
          _isDiscardedMeta,
          isDiscarded.isAcceptableOrUnknown(
              data['is_discarded']!, _isDiscardedMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StudySessionEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudySessionEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      subjectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject_id'])!,
      pageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}page_id']),
      sessionType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_type'])!,
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_time'])!,
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_time']),
      durationSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_seconds'])!,
      targetSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_seconds']),
      pauseDurationSeconds: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}pause_duration_seconds'])!,
      lapCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}lap_count'])!,
      isCompleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_completed'])!,
      isDiscarded: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_discarded'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $StudySessionsTableTable createAlias(String alias) {
    return $StudySessionsTableTable(attachedDatabase, alias);
  }
}

class StudySessionEntry extends DataClass
    implements Insertable<StudySessionEntry> {
  final String id;
  final String subjectId;
  final String? pageId;
  final String sessionType;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final int? targetSeconds;
  final int pauseDurationSeconds;
  final int lapCount;
  final bool isCompleted;
  final bool isDiscarded;
  final String? notes;
  final DateTime createdAt;
  const StudySessionEntry(
      {required this.id,
      required this.subjectId,
      this.pageId,
      required this.sessionType,
      required this.startTime,
      this.endTime,
      required this.durationSeconds,
      this.targetSeconds,
      required this.pauseDurationSeconds,
      required this.lapCount,
      required this.isCompleted,
      required this.isDiscarded,
      this.notes,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['subject_id'] = Variable<String>(subjectId);
    if (!nullToAbsent || pageId != null) {
      map['page_id'] = Variable<String>(pageId);
    }
    map['session_type'] = Variable<String>(sessionType);
    map['start_time'] = Variable<DateTime>(startTime);
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<DateTime>(endTime);
    }
    map['duration_seconds'] = Variable<int>(durationSeconds);
    if (!nullToAbsent || targetSeconds != null) {
      map['target_seconds'] = Variable<int>(targetSeconds);
    }
    map['pause_duration_seconds'] = Variable<int>(pauseDurationSeconds);
    map['lap_count'] = Variable<int>(lapCount);
    map['is_completed'] = Variable<bool>(isCompleted);
    map['is_discarded'] = Variable<bool>(isDiscarded);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  StudySessionsTableCompanion toCompanion(bool nullToAbsent) {
    return StudySessionsTableCompanion(
      id: Value(id),
      subjectId: Value(subjectId),
      pageId:
          pageId == null && nullToAbsent ? const Value.absent() : Value(pageId),
      sessionType: Value(sessionType),
      startTime: Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      durationSeconds: Value(durationSeconds),
      targetSeconds: targetSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(targetSeconds),
      pauseDurationSeconds: Value(pauseDurationSeconds),
      lapCount: Value(lapCount),
      isCompleted: Value(isCompleted),
      isDiscarded: Value(isDiscarded),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory StudySessionEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudySessionEntry(
      id: serializer.fromJson<String>(json['id']),
      subjectId: serializer.fromJson<String>(json['subjectId']),
      pageId: serializer.fromJson<String?>(json['pageId']),
      sessionType: serializer.fromJson<String>(json['sessionType']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime?>(json['endTime']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      targetSeconds: serializer.fromJson<int?>(json['targetSeconds']),
      pauseDurationSeconds:
          serializer.fromJson<int>(json['pauseDurationSeconds']),
      lapCount: serializer.fromJson<int>(json['lapCount']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      isDiscarded: serializer.fromJson<bool>(json['isDiscarded']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'subjectId': serializer.toJson<String>(subjectId),
      'pageId': serializer.toJson<String?>(pageId),
      'sessionType': serializer.toJson<String>(sessionType),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime?>(endTime),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'targetSeconds': serializer.toJson<int?>(targetSeconds),
      'pauseDurationSeconds': serializer.toJson<int>(pauseDurationSeconds),
      'lapCount': serializer.toJson<int>(lapCount),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'isDiscarded': serializer.toJson<bool>(isDiscarded),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  StudySessionEntry copyWith(
          {String? id,
          String? subjectId,
          Value<String?> pageId = const Value.absent(),
          String? sessionType,
          DateTime? startTime,
          Value<DateTime?> endTime = const Value.absent(),
          int? durationSeconds,
          Value<int?> targetSeconds = const Value.absent(),
          int? pauseDurationSeconds,
          int? lapCount,
          bool? isCompleted,
          bool? isDiscarded,
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt}) =>
      StudySessionEntry(
        id: id ?? this.id,
        subjectId: subjectId ?? this.subjectId,
        pageId: pageId.present ? pageId.value : this.pageId,
        sessionType: sessionType ?? this.sessionType,
        startTime: startTime ?? this.startTime,
        endTime: endTime.present ? endTime.value : this.endTime,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        targetSeconds:
            targetSeconds.present ? targetSeconds.value : this.targetSeconds,
        pauseDurationSeconds: pauseDurationSeconds ?? this.pauseDurationSeconds,
        lapCount: lapCount ?? this.lapCount,
        isCompleted: isCompleted ?? this.isCompleted,
        isDiscarded: isDiscarded ?? this.isDiscarded,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
      );
  StudySessionEntry copyWithCompanion(StudySessionsTableCompanion data) {
    return StudySessionEntry(
      id: data.id.present ? data.id.value : this.id,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      pageId: data.pageId.present ? data.pageId.value : this.pageId,
      sessionType:
          data.sessionType.present ? data.sessionType.value : this.sessionType,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      targetSeconds: data.targetSeconds.present
          ? data.targetSeconds.value
          : this.targetSeconds,
      pauseDurationSeconds: data.pauseDurationSeconds.present
          ? data.pauseDurationSeconds.value
          : this.pauseDurationSeconds,
      lapCount: data.lapCount.present ? data.lapCount.value : this.lapCount,
      isCompleted:
          data.isCompleted.present ? data.isCompleted.value : this.isCompleted,
      isDiscarded:
          data.isDiscarded.present ? data.isDiscarded.value : this.isDiscarded,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudySessionEntry(')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('pageId: $pageId, ')
          ..write('sessionType: $sessionType, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('targetSeconds: $targetSeconds, ')
          ..write('pauseDurationSeconds: $pauseDurationSeconds, ')
          ..write('lapCount: $lapCount, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('isDiscarded: $isDiscarded, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      subjectId,
      pageId,
      sessionType,
      startTime,
      endTime,
      durationSeconds,
      targetSeconds,
      pauseDurationSeconds,
      lapCount,
      isCompleted,
      isDiscarded,
      notes,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudySessionEntry &&
          other.id == this.id &&
          other.subjectId == this.subjectId &&
          other.pageId == this.pageId &&
          other.sessionType == this.sessionType &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.durationSeconds == this.durationSeconds &&
          other.targetSeconds == this.targetSeconds &&
          other.pauseDurationSeconds == this.pauseDurationSeconds &&
          other.lapCount == this.lapCount &&
          other.isCompleted == this.isCompleted &&
          other.isDiscarded == this.isDiscarded &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class StudySessionsTableCompanion extends UpdateCompanion<StudySessionEntry> {
  final Value<String> id;
  final Value<String> subjectId;
  final Value<String?> pageId;
  final Value<String> sessionType;
  final Value<DateTime> startTime;
  final Value<DateTime?> endTime;
  final Value<int> durationSeconds;
  final Value<int?> targetSeconds;
  final Value<int> pauseDurationSeconds;
  final Value<int> lapCount;
  final Value<bool> isCompleted;
  final Value<bool> isDiscarded;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const StudySessionsTableCompanion({
    this.id = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.pageId = const Value.absent(),
    this.sessionType = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.targetSeconds = const Value.absent(),
    this.pauseDurationSeconds = const Value.absent(),
    this.lapCount = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.isDiscarded = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StudySessionsTableCompanion.insert({
    required String id,
    required String subjectId,
    this.pageId = const Value.absent(),
    required String sessionType,
    required DateTime startTime,
    this.endTime = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.targetSeconds = const Value.absent(),
    this.pauseDurationSeconds = const Value.absent(),
    this.lapCount = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.isDiscarded = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        subjectId = Value(subjectId),
        sessionType = Value(sessionType),
        startTime = Value(startTime),
        createdAt = Value(createdAt);
  static Insertable<StudySessionEntry> custom({
    Expression<String>? id,
    Expression<String>? subjectId,
    Expression<String>? pageId,
    Expression<String>? sessionType,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<int>? durationSeconds,
    Expression<int>? targetSeconds,
    Expression<int>? pauseDurationSeconds,
    Expression<int>? lapCount,
    Expression<bool>? isCompleted,
    Expression<bool>? isDiscarded,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subjectId != null) 'subject_id': subjectId,
      if (pageId != null) 'page_id': pageId,
      if (sessionType != null) 'session_type': sessionType,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (targetSeconds != null) 'target_seconds': targetSeconds,
      if (pauseDurationSeconds != null)
        'pause_duration_seconds': pauseDurationSeconds,
      if (lapCount != null) 'lap_count': lapCount,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (isDiscarded != null) 'is_discarded': isDiscarded,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StudySessionsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? subjectId,
      Value<String?>? pageId,
      Value<String>? sessionType,
      Value<DateTime>? startTime,
      Value<DateTime?>? endTime,
      Value<int>? durationSeconds,
      Value<int?>? targetSeconds,
      Value<int>? pauseDurationSeconds,
      Value<int>? lapCount,
      Value<bool>? isCompleted,
      Value<bool>? isDiscarded,
      Value<String?>? notes,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return StudySessionsTableCompanion(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      pageId: pageId ?? this.pageId,
      sessionType: sessionType ?? this.sessionType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      targetSeconds: targetSeconds ?? this.targetSeconds,
      pauseDurationSeconds: pauseDurationSeconds ?? this.pauseDurationSeconds,
      lapCount: lapCount ?? this.lapCount,
      isCompleted: isCompleted ?? this.isCompleted,
      isDiscarded: isDiscarded ?? this.isDiscarded,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (pageId.present) {
      map['page_id'] = Variable<String>(pageId.value);
    }
    if (sessionType.present) {
      map['session_type'] = Variable<String>(sessionType.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (targetSeconds.present) {
      map['target_seconds'] = Variable<int>(targetSeconds.value);
    }
    if (pauseDurationSeconds.present) {
      map['pause_duration_seconds'] = Variable<int>(pauseDurationSeconds.value);
    }
    if (lapCount.present) {
      map['lap_count'] = Variable<int>(lapCount.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (isDiscarded.present) {
      map['is_discarded'] = Variable<bool>(isDiscarded.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudySessionsTableCompanion(')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('pageId: $pageId, ')
          ..write('sessionType: $sessionType, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('targetSeconds: $targetSeconds, ')
          ..write('pauseDurationSeconds: $pauseDurationSeconds, ')
          ..write('lapCount: $lapCount, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('isDiscarded: $isDiscarded, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PagesTable pages = $PagesTable(this);
  late final $BlocksTable blocks = $BlocksTable(this);
  late final $SubjectsTable subjects = $SubjectsTable(this);
  late final $DatabasesTableTable databasesTable = $DatabasesTableTable(this);
  late final $DatabasePropertiesTableTable databasePropertiesTable =
      $DatabasePropertiesTableTable(this);
  late final $DatabaseRowsTableTable databaseRowsTable =
      $DatabaseRowsTableTable(this);
  late final $DatabaseCellsTableTable databaseCellsTable =
      $DatabaseCellsTableTable(this);
  late final $DatabaseViewsTableTable databaseViewsTable =
      $DatabaseViewsTableTable(this);
  late final $StudySessionsTableTable studySessionsTable =
      $StudySessionsTableTable(this);
  late final Index idxPagesParent = Index('idx_pages_parent',
      'CREATE INDEX idx_pages_parent ON pages (parent_page_id)');
  late final Index idxPagesParentSort = Index('idx_pages_parent_sort',
      'CREATE INDEX idx_pages_parent_sort ON pages (parent_page_id, sort_order)');
  late final Index idxBlocksPageOrder = Index('idx_blocks_page_order',
      'CREATE INDEX idx_blocks_page_order ON blocks (page_id, order_key)');
  late final Index idxBlocksParent = Index('idx_blocks_parent',
      'CREATE INDEX idx_blocks_parent ON blocks (parent_block_id)');
  late final Index idxSubjectsSort = Index('idx_subjects_sort',
      'CREATE INDEX idx_subjects_sort ON subjects (sort_order)');
  late final Index idxDatabasesPageId = Index('idx_databases_page_id',
      'CREATE INDEX idx_databases_page_id ON databases (page_id)');
  late final Index idxPropertiesDatabaseSort = Index(
      'idx_properties_database_sort',
      'CREATE INDEX idx_properties_database_sort ON database_properties (database_id, sort_order)');
  late final Index idxRowsDatabaseSort = Index('idx_rows_database_sort',
      'CREATE INDEX idx_rows_database_sort ON database_rows (database_id, sort_order)');
  late final Index idxRowsPageId = Index('idx_rows_page_id',
      'CREATE UNIQUE INDEX idx_rows_page_id ON database_rows (page_id)');
  late final Index idxCellsRowProperty = Index('idx_cells_row_property',
      'CREATE UNIQUE INDEX idx_cells_row_property ON database_cells (row_id, property_id)');
  late final Index idxCellsProperty = Index('idx_cells_property',
      'CREATE INDEX idx_cells_property ON database_cells (property_id)');
  late final Index idxViewsDatabaseSort = Index('idx_views_database_sort',
      'CREATE INDEX idx_views_database_sort ON database_views (database_id, sort_order)');
  late final Index idxStudySessionsSubject = Index('idx_study_sessions_subject',
      'CREATE INDEX idx_study_sessions_subject ON study_sessions_table (subject_id)');
  late final Index idxStudySessionsStart = Index('idx_study_sessions_start',
      'CREATE INDEX idx_study_sessions_start ON study_sessions_table (start_time)');
  late final PagesDao pagesDao = PagesDao(this as AppDatabase);
  late final BlocksDao blocksDao = BlocksDao(this as AppDatabase);
  late final SubjectsDao subjectsDao = SubjectsDao(this as AppDatabase);
  late final DatabasesDao databasesDao = DatabasesDao(this as AppDatabase);
  late final DatabasePropertiesDao databasePropertiesDao =
      DatabasePropertiesDao(this as AppDatabase);
  late final DatabaseRowsDao databaseRowsDao =
      DatabaseRowsDao(this as AppDatabase);
  late final DatabaseCellsDao databaseCellsDao =
      DatabaseCellsDao(this as AppDatabase);
  late final DatabaseViewsDao databaseViewsDao =
      DatabaseViewsDao(this as AppDatabase);
  late final StudySessionsDao studySessionsDao =
      StudySessionsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        pages,
        blocks,
        subjects,
        databasesTable,
        databasePropertiesTable,
        databaseRowsTable,
        databaseCellsTable,
        databaseViewsTable,
        studySessionsTable,
        idxPagesParent,
        idxPagesParentSort,
        idxBlocksPageOrder,
        idxBlocksParent,
        idxSubjectsSort,
        idxDatabasesPageId,
        idxPropertiesDatabaseSort,
        idxRowsDatabaseSort,
        idxRowsPageId,
        idxCellsRowProperty,
        idxCellsProperty,
        idxViewsDatabaseSort,
        idxStudySessionsSubject,
        idxStudySessionsStart
      ];
}

typedef $$PagesTableCreateCompanionBuilder = PagesCompanion Function({
  required String id,
  Value<String?> parentPageId,
  Value<String> title,
  Value<String?> icon,
  Value<String?> coverImageUrl,
  Value<bool> isDatabaseRow,
  Value<bool> isArchived,
  Value<double> sortOrder,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$PagesTableUpdateCompanionBuilder = PagesCompanion Function({
  Value<String> id,
  Value<String?> parentPageId,
  Value<String> title,
  Value<String?> icon,
  Value<String?> coverImageUrl,
  Value<bool> isDatabaseRow,
  Value<bool> isArchived,
  Value<double> sortOrder,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$PagesTableFilterComposer extends Composer<_$AppDatabase, $PagesTable> {
  $$PagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentPageId => $composableBuilder(
      column: $table.parentPageId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverImageUrl => $composableBuilder(
      column: $table.coverImageUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDatabaseRow => $composableBuilder(
      column: $table.isDatabaseRow, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$PagesTableOrderingComposer
    extends Composer<_$AppDatabase, $PagesTable> {
  $$PagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentPageId => $composableBuilder(
      column: $table.parentPageId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverImageUrl => $composableBuilder(
      column: $table.coverImageUrl,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDatabaseRow => $composableBuilder(
      column: $table.isDatabaseRow,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$PagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PagesTable> {
  $$PagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get parentPageId => $composableBuilder(
      column: $table.parentPageId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get coverImageUrl => $composableBuilder(
      column: $table.coverImageUrl, builder: (column) => column);

  GeneratedColumn<bool> get isDatabaseRow => $composableBuilder(
      column: $table.isDatabaseRow, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => column);

  GeneratedColumn<double> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PagesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PagesTable,
    PageEntry,
    $$PagesTableFilterComposer,
    $$PagesTableOrderingComposer,
    $$PagesTableAnnotationComposer,
    $$PagesTableCreateCompanionBuilder,
    $$PagesTableUpdateCompanionBuilder,
    (PageEntry, BaseReferences<_$AppDatabase, $PagesTable, PageEntry>),
    PageEntry,
    PrefetchHooks Function()> {
  $$PagesTableTableManager(_$AppDatabase db, $PagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> parentPageId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<String?> coverImageUrl = const Value.absent(),
            Value<bool> isDatabaseRow = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<double> sortOrder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PagesCompanion(
            id: id,
            parentPageId: parentPageId,
            title: title,
            icon: icon,
            coverImageUrl: coverImageUrl,
            isDatabaseRow: isDatabaseRow,
            isArchived: isArchived,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> parentPageId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<String?> coverImageUrl = const Value.absent(),
            Value<bool> isDatabaseRow = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<double> sortOrder = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PagesCompanion.insert(
            id: id,
            parentPageId: parentPageId,
            title: title,
            icon: icon,
            coverImageUrl: coverImageUrl,
            isDatabaseRow: isDatabaseRow,
            isArchived: isArchived,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PagesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PagesTable,
    PageEntry,
    $$PagesTableFilterComposer,
    $$PagesTableOrderingComposer,
    $$PagesTableAnnotationComposer,
    $$PagesTableCreateCompanionBuilder,
    $$PagesTableUpdateCompanionBuilder,
    (PageEntry, BaseReferences<_$AppDatabase, $PagesTable, PageEntry>),
    PageEntry,
    PrefetchHooks Function()>;
typedef $$BlocksTableCreateCompanionBuilder = BlocksCompanion Function({
  required String id,
  required String pageId,
  Value<String?> parentBlockId,
  required String blockType,
  required String orderKey,
  Value<String> contentJson,
  Value<bool> isArchived,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$BlocksTableUpdateCompanionBuilder = BlocksCompanion Function({
  Value<String> id,
  Value<String> pageId,
  Value<String?> parentBlockId,
  Value<String> blockType,
  Value<String> orderKey,
  Value<String> contentJson,
  Value<bool> isArchived,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$BlocksTableFilterComposer
    extends Composer<_$AppDatabase, $BlocksTable> {
  $$BlocksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pageId => $composableBuilder(
      column: $table.pageId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentBlockId => $composableBuilder(
      column: $table.parentBlockId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get blockType => $composableBuilder(
      column: $table.blockType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get orderKey => $composableBuilder(
      column: $table.orderKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentJson => $composableBuilder(
      column: $table.contentJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$BlocksTableOrderingComposer
    extends Composer<_$AppDatabase, $BlocksTable> {
  $$BlocksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pageId => $composableBuilder(
      column: $table.pageId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentBlockId => $composableBuilder(
      column: $table.parentBlockId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get blockType => $composableBuilder(
      column: $table.blockType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get orderKey => $composableBuilder(
      column: $table.orderKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentJson => $composableBuilder(
      column: $table.contentJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$BlocksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BlocksTable> {
  $$BlocksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pageId =>
      $composableBuilder(column: $table.pageId, builder: (column) => column);

  GeneratedColumn<String> get parentBlockId => $composableBuilder(
      column: $table.parentBlockId, builder: (column) => column);

  GeneratedColumn<String> get blockType =>
      $composableBuilder(column: $table.blockType, builder: (column) => column);

  GeneratedColumn<String> get orderKey =>
      $composableBuilder(column: $table.orderKey, builder: (column) => column);

  GeneratedColumn<String> get contentJson => $composableBuilder(
      column: $table.contentJson, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BlocksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BlocksTable,
    BlockEntry,
    $$BlocksTableFilterComposer,
    $$BlocksTableOrderingComposer,
    $$BlocksTableAnnotationComposer,
    $$BlocksTableCreateCompanionBuilder,
    $$BlocksTableUpdateCompanionBuilder,
    (BlockEntry, BaseReferences<_$AppDatabase, $BlocksTable, BlockEntry>),
    BlockEntry,
    PrefetchHooks Function()> {
  $$BlocksTableTableManager(_$AppDatabase db, $BlocksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BlocksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BlocksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BlocksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> pageId = const Value.absent(),
            Value<String?> parentBlockId = const Value.absent(),
            Value<String> blockType = const Value.absent(),
            Value<String> orderKey = const Value.absent(),
            Value<String> contentJson = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BlocksCompanion(
            id: id,
            pageId: pageId,
            parentBlockId: parentBlockId,
            blockType: blockType,
            orderKey: orderKey,
            contentJson: contentJson,
            isArchived: isArchived,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String pageId,
            Value<String?> parentBlockId = const Value.absent(),
            required String blockType,
            required String orderKey,
            Value<String> contentJson = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              BlocksCompanion.insert(
            id: id,
            pageId: pageId,
            parentBlockId: parentBlockId,
            blockType: blockType,
            orderKey: orderKey,
            contentJson: contentJson,
            isArchived: isArchived,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BlocksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BlocksTable,
    BlockEntry,
    $$BlocksTableFilterComposer,
    $$BlocksTableOrderingComposer,
    $$BlocksTableAnnotationComposer,
    $$BlocksTableCreateCompanionBuilder,
    $$BlocksTableUpdateCompanionBuilder,
    (BlockEntry, BaseReferences<_$AppDatabase, $BlocksTable, BlockEntry>),
    BlockEntry,
    PrefetchHooks Function()>;
typedef $$SubjectsTableCreateCompanionBuilder = SubjectsCompanion Function({
  required String id,
  required String name,
  required String colorHex,
  Value<String?> icon,
  Value<int> dailyGoalMinutes,
  Value<bool> isArchived,
  Value<double> sortOrder,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$SubjectsTableUpdateCompanionBuilder = SubjectsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> colorHex,
  Value<String?> icon,
  Value<int> dailyGoalMinutes,
  Value<bool> isArchived,
  Value<double> sortOrder,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$SubjectsTableFilterComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dailyGoalMinutes => $composableBuilder(
      column: $table.dailyGoalMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SubjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dailyGoalMinutes => $composableBuilder(
      column: $table.dailyGoalMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SubjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get dailyGoalMinutes => $composableBuilder(
      column: $table.dailyGoalMinutes, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => column);

  GeneratedColumn<double> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SubjectsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SubjectsTable,
    SubjectEntry,
    $$SubjectsTableFilterComposer,
    $$SubjectsTableOrderingComposer,
    $$SubjectsTableAnnotationComposer,
    $$SubjectsTableCreateCompanionBuilder,
    $$SubjectsTableUpdateCompanionBuilder,
    (SubjectEntry, BaseReferences<_$AppDatabase, $SubjectsTable, SubjectEntry>),
    SubjectEntry,
    PrefetchHooks Function()> {
  $$SubjectsTableTableManager(_$AppDatabase db, $SubjectsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> colorHex = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<int> dailyGoalMinutes = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<double> sortOrder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SubjectsCompanion(
            id: id,
            name: name,
            colorHex: colorHex,
            icon: icon,
            dailyGoalMinutes: dailyGoalMinutes,
            isArchived: isArchived,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String colorHex,
            Value<String?> icon = const Value.absent(),
            Value<int> dailyGoalMinutes = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<double> sortOrder = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SubjectsCompanion.insert(
            id: id,
            name: name,
            colorHex: colorHex,
            icon: icon,
            dailyGoalMinutes: dailyGoalMinutes,
            isArchived: isArchived,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SubjectsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SubjectsTable,
    SubjectEntry,
    $$SubjectsTableFilterComposer,
    $$SubjectsTableOrderingComposer,
    $$SubjectsTableAnnotationComposer,
    $$SubjectsTableCreateCompanionBuilder,
    $$SubjectsTableUpdateCompanionBuilder,
    (SubjectEntry, BaseReferences<_$AppDatabase, $SubjectsTable, SubjectEntry>),
    SubjectEntry,
    PrefetchHooks Function()>;
typedef $$DatabasesTableTableCreateCompanionBuilder = DatabasesTableCompanion
    Function({
  required String id,
  required String pageId,
  Value<String> title,
  Value<String?> icon,
  Value<String?> coverImageUrl,
  Value<bool> isArchived,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$DatabasesTableTableUpdateCompanionBuilder = DatabasesTableCompanion
    Function({
  Value<String> id,
  Value<String> pageId,
  Value<String> title,
  Value<String?> icon,
  Value<String?> coverImageUrl,
  Value<bool> isArchived,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$DatabasesTableTableFilterComposer
    extends Composer<_$AppDatabase, $DatabasesTableTable> {
  $$DatabasesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pageId => $composableBuilder(
      column: $table.pageId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverImageUrl => $composableBuilder(
      column: $table.coverImageUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$DatabasesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DatabasesTableTable> {
  $$DatabasesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pageId => $composableBuilder(
      column: $table.pageId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverImageUrl => $composableBuilder(
      column: $table.coverImageUrl,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$DatabasesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DatabasesTableTable> {
  $$DatabasesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pageId =>
      $composableBuilder(column: $table.pageId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get coverImageUrl => $composableBuilder(
      column: $table.coverImageUrl, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DatabasesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DatabasesTableTable,
    DatabaseEntry,
    $$DatabasesTableTableFilterComposer,
    $$DatabasesTableTableOrderingComposer,
    $$DatabasesTableTableAnnotationComposer,
    $$DatabasesTableTableCreateCompanionBuilder,
    $$DatabasesTableTableUpdateCompanionBuilder,
    (
      DatabaseEntry,
      BaseReferences<_$AppDatabase, $DatabasesTableTable, DatabaseEntry>
    ),
    DatabaseEntry,
    PrefetchHooks Function()> {
  $$DatabasesTableTableTableManager(
      _$AppDatabase db, $DatabasesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DatabasesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DatabasesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DatabasesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> pageId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<String?> coverImageUrl = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DatabasesTableCompanion(
            id: id,
            pageId: pageId,
            title: title,
            icon: icon,
            coverImageUrl: coverImageUrl,
            isArchived: isArchived,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String pageId,
            Value<String> title = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<String?> coverImageUrl = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              DatabasesTableCompanion.insert(
            id: id,
            pageId: pageId,
            title: title,
            icon: icon,
            coverImageUrl: coverImageUrl,
            isArchived: isArchived,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DatabasesTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DatabasesTableTable,
    DatabaseEntry,
    $$DatabasesTableTableFilterComposer,
    $$DatabasesTableTableOrderingComposer,
    $$DatabasesTableTableAnnotationComposer,
    $$DatabasesTableTableCreateCompanionBuilder,
    $$DatabasesTableTableUpdateCompanionBuilder,
    (
      DatabaseEntry,
      BaseReferences<_$AppDatabase, $DatabasesTableTable, DatabaseEntry>
    ),
    DatabaseEntry,
    PrefetchHooks Function()>;
typedef $$DatabasePropertiesTableTableCreateCompanionBuilder
    = DatabasePropertiesTableCompanion Function({
  required String id,
  required String databaseId,
  required String name,
  required String propertyType,
  Value<double> sortOrder,
  Value<String> configJson,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$DatabasePropertiesTableTableUpdateCompanionBuilder
    = DatabasePropertiesTableCompanion Function({
  Value<String> id,
  Value<String> databaseId,
  Value<String> name,
  Value<String> propertyType,
  Value<double> sortOrder,
  Value<String> configJson,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$DatabasePropertiesTableTableFilterComposer
    extends Composer<_$AppDatabase, $DatabasePropertiesTableTable> {
  $$DatabasePropertiesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get databaseId => $composableBuilder(
      column: $table.databaseId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get propertyType => $composableBuilder(
      column: $table.propertyType, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get configJson => $composableBuilder(
      column: $table.configJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$DatabasePropertiesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DatabasePropertiesTableTable> {
  $$DatabasePropertiesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get databaseId => $composableBuilder(
      column: $table.databaseId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get propertyType => $composableBuilder(
      column: $table.propertyType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get configJson => $composableBuilder(
      column: $table.configJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$DatabasePropertiesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DatabasePropertiesTableTable> {
  $$DatabasePropertiesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get databaseId => $composableBuilder(
      column: $table.databaseId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get propertyType => $composableBuilder(
      column: $table.propertyType, builder: (column) => column);

  GeneratedColumn<double> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get configJson => $composableBuilder(
      column: $table.configJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DatabasePropertiesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DatabasePropertiesTableTable,
    DatabasePropertyEntry,
    $$DatabasePropertiesTableTableFilterComposer,
    $$DatabasePropertiesTableTableOrderingComposer,
    $$DatabasePropertiesTableTableAnnotationComposer,
    $$DatabasePropertiesTableTableCreateCompanionBuilder,
    $$DatabasePropertiesTableTableUpdateCompanionBuilder,
    (
      DatabasePropertyEntry,
      BaseReferences<_$AppDatabase, $DatabasePropertiesTableTable,
          DatabasePropertyEntry>
    ),
    DatabasePropertyEntry,
    PrefetchHooks Function()> {
  $$DatabasePropertiesTableTableTableManager(
      _$AppDatabase db, $DatabasePropertiesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DatabasePropertiesTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$DatabasePropertiesTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DatabasePropertiesTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> databaseId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> propertyType = const Value.absent(),
            Value<double> sortOrder = const Value.absent(),
            Value<String> configJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DatabasePropertiesTableCompanion(
            id: id,
            databaseId: databaseId,
            name: name,
            propertyType: propertyType,
            sortOrder: sortOrder,
            configJson: configJson,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String databaseId,
            required String name,
            required String propertyType,
            Value<double> sortOrder = const Value.absent(),
            Value<String> configJson = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              DatabasePropertiesTableCompanion.insert(
            id: id,
            databaseId: databaseId,
            name: name,
            propertyType: propertyType,
            sortOrder: sortOrder,
            configJson: configJson,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DatabasePropertiesTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $DatabasePropertiesTableTable,
        DatabasePropertyEntry,
        $$DatabasePropertiesTableTableFilterComposer,
        $$DatabasePropertiesTableTableOrderingComposer,
        $$DatabasePropertiesTableTableAnnotationComposer,
        $$DatabasePropertiesTableTableCreateCompanionBuilder,
        $$DatabasePropertiesTableTableUpdateCompanionBuilder,
        (
          DatabasePropertyEntry,
          BaseReferences<_$AppDatabase, $DatabasePropertiesTableTable,
              DatabasePropertyEntry>
        ),
        DatabasePropertyEntry,
        PrefetchHooks Function()>;
typedef $$DatabaseRowsTableTableCreateCompanionBuilder
    = DatabaseRowsTableCompanion Function({
  required String id,
  required String databaseId,
  required String pageId,
  Value<double> sortOrder,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$DatabaseRowsTableTableUpdateCompanionBuilder
    = DatabaseRowsTableCompanion Function({
  Value<String> id,
  Value<String> databaseId,
  Value<String> pageId,
  Value<double> sortOrder,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$DatabaseRowsTableTableFilterComposer
    extends Composer<_$AppDatabase, $DatabaseRowsTableTable> {
  $$DatabaseRowsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get databaseId => $composableBuilder(
      column: $table.databaseId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pageId => $composableBuilder(
      column: $table.pageId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$DatabaseRowsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DatabaseRowsTableTable> {
  $$DatabaseRowsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get databaseId => $composableBuilder(
      column: $table.databaseId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pageId => $composableBuilder(
      column: $table.pageId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$DatabaseRowsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DatabaseRowsTableTable> {
  $$DatabaseRowsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get databaseId => $composableBuilder(
      column: $table.databaseId, builder: (column) => column);

  GeneratedColumn<String> get pageId =>
      $composableBuilder(column: $table.pageId, builder: (column) => column);

  GeneratedColumn<double> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DatabaseRowsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DatabaseRowsTableTable,
    DatabaseRowEntry,
    $$DatabaseRowsTableTableFilterComposer,
    $$DatabaseRowsTableTableOrderingComposer,
    $$DatabaseRowsTableTableAnnotationComposer,
    $$DatabaseRowsTableTableCreateCompanionBuilder,
    $$DatabaseRowsTableTableUpdateCompanionBuilder,
    (
      DatabaseRowEntry,
      BaseReferences<_$AppDatabase, $DatabaseRowsTableTable, DatabaseRowEntry>
    ),
    DatabaseRowEntry,
    PrefetchHooks Function()> {
  $$DatabaseRowsTableTableTableManager(
      _$AppDatabase db, $DatabaseRowsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DatabaseRowsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DatabaseRowsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DatabaseRowsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> databaseId = const Value.absent(),
            Value<String> pageId = const Value.absent(),
            Value<double> sortOrder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DatabaseRowsTableCompanion(
            id: id,
            databaseId: databaseId,
            pageId: pageId,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String databaseId,
            required String pageId,
            Value<double> sortOrder = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              DatabaseRowsTableCompanion.insert(
            id: id,
            databaseId: databaseId,
            pageId: pageId,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DatabaseRowsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DatabaseRowsTableTable,
    DatabaseRowEntry,
    $$DatabaseRowsTableTableFilterComposer,
    $$DatabaseRowsTableTableOrderingComposer,
    $$DatabaseRowsTableTableAnnotationComposer,
    $$DatabaseRowsTableTableCreateCompanionBuilder,
    $$DatabaseRowsTableTableUpdateCompanionBuilder,
    (
      DatabaseRowEntry,
      BaseReferences<_$AppDatabase, $DatabaseRowsTableTable, DatabaseRowEntry>
    ),
    DatabaseRowEntry,
    PrefetchHooks Function()>;
typedef $$DatabaseCellsTableTableCreateCompanionBuilder
    = DatabaseCellsTableCompanion Function({
  required String id,
  required String rowId,
  required String propertyId,
  Value<String?> valueJson,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$DatabaseCellsTableTableUpdateCompanionBuilder
    = DatabaseCellsTableCompanion Function({
  Value<String> id,
  Value<String> rowId,
  Value<String> propertyId,
  Value<String?> valueJson,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$DatabaseCellsTableTableFilterComposer
    extends Composer<_$AppDatabase, $DatabaseCellsTableTable> {
  $$DatabaseCellsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rowId => $composableBuilder(
      column: $table.rowId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get propertyId => $composableBuilder(
      column: $table.propertyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get valueJson => $composableBuilder(
      column: $table.valueJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$DatabaseCellsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DatabaseCellsTableTable> {
  $$DatabaseCellsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rowId => $composableBuilder(
      column: $table.rowId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get propertyId => $composableBuilder(
      column: $table.propertyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get valueJson => $composableBuilder(
      column: $table.valueJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$DatabaseCellsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DatabaseCellsTableTable> {
  $$DatabaseCellsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get propertyId => $composableBuilder(
      column: $table.propertyId, builder: (column) => column);

  GeneratedColumn<String> get valueJson =>
      $composableBuilder(column: $table.valueJson, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DatabaseCellsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DatabaseCellsTableTable,
    DatabaseCellEntry,
    $$DatabaseCellsTableTableFilterComposer,
    $$DatabaseCellsTableTableOrderingComposer,
    $$DatabaseCellsTableTableAnnotationComposer,
    $$DatabaseCellsTableTableCreateCompanionBuilder,
    $$DatabaseCellsTableTableUpdateCompanionBuilder,
    (
      DatabaseCellEntry,
      BaseReferences<_$AppDatabase, $DatabaseCellsTableTable, DatabaseCellEntry>
    ),
    DatabaseCellEntry,
    PrefetchHooks Function()> {
  $$DatabaseCellsTableTableTableManager(
      _$AppDatabase db, $DatabaseCellsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DatabaseCellsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DatabaseCellsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DatabaseCellsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> rowId = const Value.absent(),
            Value<String> propertyId = const Value.absent(),
            Value<String?> valueJson = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DatabaseCellsTableCompanion(
            id: id,
            rowId: rowId,
            propertyId: propertyId,
            valueJson: valueJson,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String rowId,
            required String propertyId,
            Value<String?> valueJson = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              DatabaseCellsTableCompanion.insert(
            id: id,
            rowId: rowId,
            propertyId: propertyId,
            valueJson: valueJson,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DatabaseCellsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DatabaseCellsTableTable,
    DatabaseCellEntry,
    $$DatabaseCellsTableTableFilterComposer,
    $$DatabaseCellsTableTableOrderingComposer,
    $$DatabaseCellsTableTableAnnotationComposer,
    $$DatabaseCellsTableTableCreateCompanionBuilder,
    $$DatabaseCellsTableTableUpdateCompanionBuilder,
    (
      DatabaseCellEntry,
      BaseReferences<_$AppDatabase, $DatabaseCellsTableTable, DatabaseCellEntry>
    ),
    DatabaseCellEntry,
    PrefetchHooks Function()>;
typedef $$DatabaseViewsTableTableCreateCompanionBuilder
    = DatabaseViewsTableCompanion Function({
  required String id,
  required String databaseId,
  Value<String> name,
  required String viewType,
  Value<double> sortOrder,
  Value<String> configJson,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$DatabaseViewsTableTableUpdateCompanionBuilder
    = DatabaseViewsTableCompanion Function({
  Value<String> id,
  Value<String> databaseId,
  Value<String> name,
  Value<String> viewType,
  Value<double> sortOrder,
  Value<String> configJson,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$DatabaseViewsTableTableFilterComposer
    extends Composer<_$AppDatabase, $DatabaseViewsTableTable> {
  $$DatabaseViewsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get databaseId => $composableBuilder(
      column: $table.databaseId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get viewType => $composableBuilder(
      column: $table.viewType, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get configJson => $composableBuilder(
      column: $table.configJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$DatabaseViewsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DatabaseViewsTableTable> {
  $$DatabaseViewsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get databaseId => $composableBuilder(
      column: $table.databaseId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get viewType => $composableBuilder(
      column: $table.viewType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get configJson => $composableBuilder(
      column: $table.configJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$DatabaseViewsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DatabaseViewsTableTable> {
  $$DatabaseViewsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get databaseId => $composableBuilder(
      column: $table.databaseId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get viewType =>
      $composableBuilder(column: $table.viewType, builder: (column) => column);

  GeneratedColumn<double> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get configJson => $composableBuilder(
      column: $table.configJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DatabaseViewsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DatabaseViewsTableTable,
    DatabaseViewEntry,
    $$DatabaseViewsTableTableFilterComposer,
    $$DatabaseViewsTableTableOrderingComposer,
    $$DatabaseViewsTableTableAnnotationComposer,
    $$DatabaseViewsTableTableCreateCompanionBuilder,
    $$DatabaseViewsTableTableUpdateCompanionBuilder,
    (
      DatabaseViewEntry,
      BaseReferences<_$AppDatabase, $DatabaseViewsTableTable, DatabaseViewEntry>
    ),
    DatabaseViewEntry,
    PrefetchHooks Function()> {
  $$DatabaseViewsTableTableTableManager(
      _$AppDatabase db, $DatabaseViewsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DatabaseViewsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DatabaseViewsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DatabaseViewsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> databaseId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> viewType = const Value.absent(),
            Value<double> sortOrder = const Value.absent(),
            Value<String> configJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DatabaseViewsTableCompanion(
            id: id,
            databaseId: databaseId,
            name: name,
            viewType: viewType,
            sortOrder: sortOrder,
            configJson: configJson,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String databaseId,
            Value<String> name = const Value.absent(),
            required String viewType,
            Value<double> sortOrder = const Value.absent(),
            Value<String> configJson = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              DatabaseViewsTableCompanion.insert(
            id: id,
            databaseId: databaseId,
            name: name,
            viewType: viewType,
            sortOrder: sortOrder,
            configJson: configJson,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DatabaseViewsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DatabaseViewsTableTable,
    DatabaseViewEntry,
    $$DatabaseViewsTableTableFilterComposer,
    $$DatabaseViewsTableTableOrderingComposer,
    $$DatabaseViewsTableTableAnnotationComposer,
    $$DatabaseViewsTableTableCreateCompanionBuilder,
    $$DatabaseViewsTableTableUpdateCompanionBuilder,
    (
      DatabaseViewEntry,
      BaseReferences<_$AppDatabase, $DatabaseViewsTableTable, DatabaseViewEntry>
    ),
    DatabaseViewEntry,
    PrefetchHooks Function()>;
typedef $$StudySessionsTableTableCreateCompanionBuilder
    = StudySessionsTableCompanion Function({
  required String id,
  required String subjectId,
  Value<String?> pageId,
  required String sessionType,
  required DateTime startTime,
  Value<DateTime?> endTime,
  Value<int> durationSeconds,
  Value<int?> targetSeconds,
  Value<int> pauseDurationSeconds,
  Value<int> lapCount,
  Value<bool> isCompleted,
  Value<bool> isDiscarded,
  Value<String?> notes,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$StudySessionsTableTableUpdateCompanionBuilder
    = StudySessionsTableCompanion Function({
  Value<String> id,
  Value<String> subjectId,
  Value<String?> pageId,
  Value<String> sessionType,
  Value<DateTime> startTime,
  Value<DateTime?> endTime,
  Value<int> durationSeconds,
  Value<int?> targetSeconds,
  Value<int> pauseDurationSeconds,
  Value<int> lapCount,
  Value<bool> isCompleted,
  Value<bool> isDiscarded,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$StudySessionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $StudySessionsTableTable> {
  $$StudySessionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subjectId => $composableBuilder(
      column: $table.subjectId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pageId => $composableBuilder(
      column: $table.pageId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionType => $composableBuilder(
      column: $table.sessionType, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetSeconds => $composableBuilder(
      column: $table.targetSeconds, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pauseDurationSeconds => $composableBuilder(
      column: $table.pauseDurationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lapCount => $composableBuilder(
      column: $table.lapCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDiscarded => $composableBuilder(
      column: $table.isDiscarded, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$StudySessionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $StudySessionsTableTable> {
  $$StudySessionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subjectId => $composableBuilder(
      column: $table.subjectId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pageId => $composableBuilder(
      column: $table.pageId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionType => $composableBuilder(
      column: $table.sessionType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetSeconds => $composableBuilder(
      column: $table.targetSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pauseDurationSeconds => $composableBuilder(
      column: $table.pauseDurationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lapCount => $composableBuilder(
      column: $table.lapCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDiscarded => $composableBuilder(
      column: $table.isDiscarded, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$StudySessionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $StudySessionsTableTable> {
  $$StudySessionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get subjectId =>
      $composableBuilder(column: $table.subjectId, builder: (column) => column);

  GeneratedColumn<String> get pageId =>
      $composableBuilder(column: $table.pageId, builder: (column) => column);

  GeneratedColumn<String> get sessionType => $composableBuilder(
      column: $table.sessionType, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds, builder: (column) => column);

  GeneratedColumn<int> get targetSeconds => $composableBuilder(
      column: $table.targetSeconds, builder: (column) => column);

  GeneratedColumn<int> get pauseDurationSeconds => $composableBuilder(
      column: $table.pauseDurationSeconds, builder: (column) => column);

  GeneratedColumn<int> get lapCount =>
      $composableBuilder(column: $table.lapCount, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => column);

  GeneratedColumn<bool> get isDiscarded => $composableBuilder(
      column: $table.isDiscarded, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$StudySessionsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StudySessionsTableTable,
    StudySessionEntry,
    $$StudySessionsTableTableFilterComposer,
    $$StudySessionsTableTableOrderingComposer,
    $$StudySessionsTableTableAnnotationComposer,
    $$StudySessionsTableTableCreateCompanionBuilder,
    $$StudySessionsTableTableUpdateCompanionBuilder,
    (
      StudySessionEntry,
      BaseReferences<_$AppDatabase, $StudySessionsTableTable, StudySessionEntry>
    ),
    StudySessionEntry,
    PrefetchHooks Function()> {
  $$StudySessionsTableTableTableManager(
      _$AppDatabase db, $StudySessionsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudySessionsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudySessionsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudySessionsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> subjectId = const Value.absent(),
            Value<String?> pageId = const Value.absent(),
            Value<String> sessionType = const Value.absent(),
            Value<DateTime> startTime = const Value.absent(),
            Value<DateTime?> endTime = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            Value<int?> targetSeconds = const Value.absent(),
            Value<int> pauseDurationSeconds = const Value.absent(),
            Value<int> lapCount = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            Value<bool> isDiscarded = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StudySessionsTableCompanion(
            id: id,
            subjectId: subjectId,
            pageId: pageId,
            sessionType: sessionType,
            startTime: startTime,
            endTime: endTime,
            durationSeconds: durationSeconds,
            targetSeconds: targetSeconds,
            pauseDurationSeconds: pauseDurationSeconds,
            lapCount: lapCount,
            isCompleted: isCompleted,
            isDiscarded: isDiscarded,
            notes: notes,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String subjectId,
            Value<String?> pageId = const Value.absent(),
            required String sessionType,
            required DateTime startTime,
            Value<DateTime?> endTime = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            Value<int?> targetSeconds = const Value.absent(),
            Value<int> pauseDurationSeconds = const Value.absent(),
            Value<int> lapCount = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            Value<bool> isDiscarded = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              StudySessionsTableCompanion.insert(
            id: id,
            subjectId: subjectId,
            pageId: pageId,
            sessionType: sessionType,
            startTime: startTime,
            endTime: endTime,
            durationSeconds: durationSeconds,
            targetSeconds: targetSeconds,
            pauseDurationSeconds: pauseDurationSeconds,
            lapCount: lapCount,
            isCompleted: isCompleted,
            isDiscarded: isDiscarded,
            notes: notes,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StudySessionsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StudySessionsTableTable,
    StudySessionEntry,
    $$StudySessionsTableTableFilterComposer,
    $$StudySessionsTableTableOrderingComposer,
    $$StudySessionsTableTableAnnotationComposer,
    $$StudySessionsTableTableCreateCompanionBuilder,
    $$StudySessionsTableTableUpdateCompanionBuilder,
    (
      StudySessionEntry,
      BaseReferences<_$AppDatabase, $StudySessionsTableTable, StudySessionEntry>
    ),
    StudySessionEntry,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PagesTableTableManager get pages =>
      $$PagesTableTableManager(_db, _db.pages);
  $$BlocksTableTableManager get blocks =>
      $$BlocksTableTableManager(_db, _db.blocks);
  $$SubjectsTableTableManager get subjects =>
      $$SubjectsTableTableManager(_db, _db.subjects);
  $$DatabasesTableTableTableManager get databasesTable =>
      $$DatabasesTableTableTableManager(_db, _db.databasesTable);
  $$DatabasePropertiesTableTableTableManager get databasePropertiesTable =>
      $$DatabasePropertiesTableTableTableManager(
          _db, _db.databasePropertiesTable);
  $$DatabaseRowsTableTableTableManager get databaseRowsTable =>
      $$DatabaseRowsTableTableTableManager(_db, _db.databaseRowsTable);
  $$DatabaseCellsTableTableTableManager get databaseCellsTable =>
      $$DatabaseCellsTableTableTableManager(_db, _db.databaseCellsTable);
  $$DatabaseViewsTableTableTableManager get databaseViewsTable =>
      $$DatabaseViewsTableTableTableManager(_db, _db.databaseViewsTable);
  $$StudySessionsTableTableTableManager get studySessionsTable =>
      $$StudySessionsTableTableTableManager(_db, _db.studySessionsTable);
}
