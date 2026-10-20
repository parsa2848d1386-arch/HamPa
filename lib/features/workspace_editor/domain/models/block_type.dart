import 'package:flutter/material.dart';

enum BlockType {
  text('text'),
  heading1('heading_1'),
  heading2('heading_2'),
  heading3('heading_3'),
  checklist('checklist'),
  callout('callout'),
  toggle('toggle'),
  code('code'),
  math('math'),
  divider('divider'),
  quote('quote'),
  databaseInline('database_inline');

  final String value;
  const BlockType(this.value);

  static BlockType fromString(String value) {
    return BlockType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BlockType.text,
    );
  }

  String toDbString() => value;
  static BlockType fromDbString(String str) => fromString(str);

  String get displayName {
    switch (this) {
      case BlockType.text:
        return 'Text';
      case BlockType.heading1:
        return 'Heading 1';
      case BlockType.heading2:
        return 'Heading 2';
      case BlockType.heading3:
        return 'Heading 3';
      case BlockType.checklist:
        return 'To-do List';
      case BlockType.callout:
        return 'Callout';
      case BlockType.toggle:
        return 'Toggle List';
      case BlockType.code:
        return 'Code Block';
      case BlockType.math:
        return 'Math Equation';
      case BlockType.divider:
        return 'Divider';
      case BlockType.quote:
        return 'Quote';
      case BlockType.databaseInline:
        return 'Inline Database';
    }
  }

  IconData get iconData {
    switch (this) {
      case BlockType.text:
        return Icons.short_text;
      case BlockType.heading1:
        return Icons.title;
      case BlockType.heading2:
        return Icons.format_size;
      case BlockType.heading3:
        return Icons.format_size;
      case BlockType.checklist:
        return Icons.check_box_outlined;
      case BlockType.callout:
        return Icons.lightbulb_outline;
      case BlockType.toggle:
        return Icons.arrow_right;
      case BlockType.code:
        return Icons.code;
      case BlockType.math:
        return Icons.functions;
      case BlockType.divider:
        return Icons.horizontal_rule;
      case BlockType.quote:
        return Icons.format_quote;
      case BlockType.databaseInline:
        return Icons.table_chart;
    }
  }

  String get placeholderText {
    switch (this) {
      case BlockType.text:
        return "Type '/' for commands...";
      case BlockType.heading1:
        return 'Heading 1';
      case BlockType.heading2:
        return 'Heading 2';
      case BlockType.heading3:
        return 'Heading 3';
      case BlockType.checklist:
        return 'To-do';
      case BlockType.callout:
        return 'Callout content...';
      case BlockType.toggle:
        return 'Toggle title...';
      case BlockType.code:
        return '// Enter code here';
      case BlockType.math:
        return 'E = mc^2';
      case BlockType.divider:
        return '';
      case BlockType.quote:
        return 'Quote text...';
      case BlockType.databaseInline:
        return '';
    }
  }

  bool get isHeader =>
      this == BlockType.heading1 ||
      this == BlockType.heading2 ||
      this == BlockType.heading3;

  bool get supportsChildren => this == BlockType.toggle;
}
