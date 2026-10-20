import 'package:flutter/material.dart';
import '../../../domain/models/block_entity.dart';

class ToggleBlockRenderer extends StatefulWidget {
  final BlockEntity block;
  final VoidCallback onToggle;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final Widget childBlocksWidget;

  const ToggleBlockRenderer({
    super.key,
    required this.block,
    required this.onToggle,
    required this.onChanged,
    required this.childBlocksWidget,
  });

  @override
  State<ToggleBlockRenderer> createState() => _ToggleBlockRendererState();
}

class _ToggleBlockRendererState extends State<ToggleBlockRenderer> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.content['title'] ?? '');
  }

  @override
  void didUpdateWidget(covariant ToggleBlockRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final title = widget.block.content['title'] as String? ?? '';
    if (title != _controller.text) {
      _controller.text = title;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = widget.block.content['isOpen'] as bool? ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InkWell(
              onTap: widget.onToggle,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: AnimatedRotation(
                  turns: isOpen ? 0.25 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.arrow_right, size: 24),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: 'Toggle list title...',
                ),
                onChanged: (val) {
                  widget.onChanged({
                    ...widget.block.content,
                    'title': val,
                  });
                },
              ),
            ),
          ],
        ),
        if (isOpen)
          Padding(
            padding: const EdgeInsets.only(left: 28.0),
            child: widget.childBlocksWidget,
          ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
