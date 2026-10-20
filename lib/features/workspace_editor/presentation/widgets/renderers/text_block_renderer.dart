import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/models/block_entity.dart';
import '../../../domain/models/block_type.dart';

class TextBlockRenderer extends StatefulWidget {
  final BlockEntity block;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onEnter;
  final VoidCallback onBackspaceEmpty;
  final ValueChanged<String>? onSlashTriggered;
  final VoidCallback? onSlashDismissed;

  const TextBlockRenderer({
    super.key,
    required this.block,
    required this.onChanged,
    required this.onEnter,
    required this.onBackspaceEmpty,
    this.onSlashTriggered,
    this.onSlashDismissed,
  });

  @override
  State<TextBlockRenderer> createState() => _TextBlockRendererState();
}

class _TextBlockRendererState extends State<TextBlockRenderer> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    final text = widget.block.content['text'] as String? ?? '';
    _controller = TextEditingController(text: text);
    _focusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if ((event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.numpadEnter) &&
              !HardwareKeyboard.instance.isShiftPressed) {
            widget.onEnter();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.backspace &&
              _controller.text.isEmpty) {
            widget.onBackspaceEmpty();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
    );
  }

  @override
  void didUpdateWidget(covariant TextBlockRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = widget.block.content['text'] as String? ?? '';
    if (text != _controller.text) {
      _controller.text = text;
    }
  }

  TextStyle _getStyle(BuildContext context) {
    final theme = Theme.of(context);
    switch (widget.block.type) {
      case BlockType.heading1:
        return theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.3,
            ) ??
            const TextStyle(fontSize: 26, fontWeight: FontWeight.bold);
      case BlockType.heading2:
        return theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.3,
            ) ??
            const TextStyle(fontSize: 21, fontWeight: FontWeight.bold);
      case BlockType.heading3:
        return theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.3,
            ) ??
            const TextStyle(fontSize: 17, fontWeight: FontWeight.w600);
      case BlockType.quote:
        return theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              fontSize: 15,
              height: 1.5,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
            ) ??
            const TextStyle(fontSize: 15, fontStyle: FontStyle.italic);
      default:
        return theme.textTheme.bodyMedium?.copyWith(
              fontSize: 15,
              height: 1.5,
            ) ??
            const TextStyle(fontSize: 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isQuote = widget.block.type == BlockType.quote;

    Widget input = TextField(
      controller: _controller,
      focusNode: _focusNode,
      maxLines: null,
      style: _getStyle(context),
      decoration: InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        hintText: widget.block.type.placeholderText,
        hintStyle: TextStyle(
          color: Theme.of(context).hintColor.withValues(alpha: 0.4),
        ),
      ),
      onChanged: (val) {
        if (val.startsWith('/')) {
          widget.onSlashTriggered?.call(val.substring(1));
        } else {
          widget.onSlashDismissed?.call();
        }
        widget.onChanged({'text': val});
      },
    );

    if (isQuote) {
      return Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 3.5,
            ),
          ),
        ),
        padding: const EdgeInsets.only(left: 12.0),
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        child: input,
      );
    }

    return input;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
