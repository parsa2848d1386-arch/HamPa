import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/models/block_entity.dart';

class ChecklistBlockRenderer extends StatefulWidget {
  final BlockEntity block;
  final VoidCallback onToggle;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onEnter;
  final VoidCallback onBackspaceEmpty;
  final VoidCallback? onFocusNow;

  const ChecklistBlockRenderer({
    super.key,
    required this.block,
    required this.onToggle,
    required this.onChanged,
    required this.onEnter,
    required this.onBackspaceEmpty,
    this.onFocusNow,
  });

  @override
  State<ChecklistBlockRenderer> createState() => _ChecklistBlockRendererState();
}

class _ChecklistBlockRendererState extends State<ChecklistBlockRenderer> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.content['text'] ?? '');
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
  void didUpdateWidget(covariant ChecklistBlockRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = widget.block.content['text'] as String? ?? '';
    if (text != _controller.text) {
      _controller.text = text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.block.content['isCompleted'] as bool? ?? false;
    final checkedAt = widget.block.content['checkedAt'] as int?;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: isCompleted,
          onChanged: (_) => widget.onToggle(),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            maxLines: null,
            style: TextStyle(
              fontSize: 15,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: isCompleted
                  ? Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5)
                  : null,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 4),
              hintText: 'To-do item...',
            ),
            onChanged: (val) {
              widget.onChanged({
                ...widget.block.content,
                'text': val,
              });
            },
          ),
        ),
        if (checkedAt != null && isCompleted)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(
              '✓ ${_formatTimestamp(checkedAt)}',
              style: TextStyle(fontSize: 11, color: Colors.green.shade600),
            ),
          ),
        // F29 Focus Now Button for quick study integration
        if (!isCompleted && widget.onFocusNow != null)
          IconButton(
            icon: const Icon(Icons.timer_outlined, size: 18),
            tooltip: 'Focus on this task (YPT Stopwatch)',
            onPressed: widget.onFocusNow,
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }

  String _formatTimestamp(int epoch) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epoch);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
