import 'package:flutter/material.dart';
import '../../../domain/models/block_entity.dart';

class CalloutBlockRenderer extends StatefulWidget {
  final BlockEntity block;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const CalloutBlockRenderer({
    super.key,
    required this.block,
    required this.onChanged,
  });

  @override
  State<CalloutBlockRenderer> createState() => _CalloutBlockRendererState();
}

class _CalloutBlockRendererState extends State<CalloutBlockRenderer> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.content['text'] ?? '');
  }

  @override
  void didUpdateWidget(covariant CalloutBlockRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = widget.block.content['text'] as String? ?? '';
    if (text != _controller.text) {
      _controller.text = text;
    }
  }

  Color _getBackgroundColor(String theme, bool isDark) {
    switch (theme) {
      case 'blue':
        return isDark ? Colors.blue.shade900.withValues(alpha: 0.3) : Colors.blue.shade50;
      case 'green':
        return isDark ? Colors.green.shade900.withValues(alpha: 0.3) : Colors.green.shade50;
      case 'rose':
        return isDark ? Colors.red.shade900.withValues(alpha: 0.3) : Colors.red.shade50;
      case 'purple':
        return isDark ? Colors.purple.shade900.withValues(alpha: 0.3) : Colors.purple.shade50;
      case 'amber':
      default:
        return isDark ? Colors.amber.shade900.withValues(alpha: 0.3) : Colors.amber.shade50;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final icon = widget.block.content['icon'] as String? ?? '💡';
    final theme = widget.block.content['colorTheme'] as String? ?? 'amber';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _getBackgroundColor(theme, isDark),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: null,
              style: const TextStyle(fontSize: 15),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'Type callout message...',
              ),
              onChanged: (val) {
                widget.onChanged({
                  ...widget.block.content,
                  'text': val,
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
