import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../../../domain/models/block_entity.dart';

class MathBlockRenderer extends StatefulWidget {
  final BlockEntity block;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const MathBlockRenderer({
    super.key,
    required this.block,
    required this.onChanged,
  });

  @override
  State<MathBlockRenderer> createState() => _MathBlockRendererState();
}

class _MathBlockRendererState extends State<MathBlockRenderer> {
  late final TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final latex = widget.block.content['latex'] as String? ?? 'E = mc^2';
    _controller = TextEditingController(text: latex);
  }

  @override
  void didUpdateWidget(covariant MathBlockRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final latex = widget.block.content['latex'] as String? ?? '';
    if (latex != _controller.text) {
      _controller.text = latex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final latex = widget.block.content['latex'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.functions, size: 16, color: Colors.blueAccent),
                  SizedBox(width: 6),
                  Text('TeX Formula', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                icon: Icon(_isEditing ? Icons.visibility : Icons.edit, size: 16),
                tooltip: _isEditing ? 'Preview formula' : 'Edit LaTeX',
                onPressed: () => setState(() => _isEditing = !_isEditing),
              ),
            ],
          ),
          if (_isEditing || latex.isEmpty)
            TextField(
              controller: _controller,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
              decoration: const InputDecoration(
                hintText: r'\int_{a}^{b} f(x)dx',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (val) {
                widget.onChanged({
                  ...widget.block.content,
                  'latex': val,
                });
              },
            )
          else
            Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Math.tex(
                    latex,
                    mathStyle: MathStyle.display,
                    textStyle: const TextStyle(fontSize: 18),
                    onErrorFallback: (err) => Text(
                      'LaTeX Error: ${err.message}',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ),
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
