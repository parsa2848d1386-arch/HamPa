import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import '../../../domain/models/block_entity.dart';

class CodeBlockRenderer extends StatefulWidget {
  final BlockEntity block;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const CodeBlockRenderer({
    super.key,
    required this.block,
    required this.onChanged,
  });

  @override
  State<CodeBlockRenderer> createState() => _CodeBlockRendererState();
}

class _CodeBlockRendererState extends State<CodeBlockRenderer> {
  late final TextEditingController _controller;
  bool _isEditing = false;
  bool _copied = false;

  static const List<String> supportedLanguages = [
    'plain',
    'dart',
    'python',
    'javascript',
    'sql',
    'json',
    'markdown',
    'html',
    'bash',
    'cpp',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.content['code'] ?? '');
  }

  @override
  void didUpdateWidget(covariant CodeBlockRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final code = widget.block.content['code'] as String? ?? '';
    if (code != _controller.text) {
      _controller.text = code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawLanguage = widget.block.content['language'] as String? ?? 'dart';
    final language = supportedLanguages.contains(rawLanguage) ? rawLanguage : 'plain';
    final code = widget.block.content['code'] as String? ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF282C34) : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: language,
                    items: supportedLanguages
                        .map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontSize: 12))))
                        .toList(),
                    onChanged: (newLang) {
                      if (newLang != null) {
                        widget.onChanged({
                          ...widget.block.content,
                          'language': newLang,
                        });
                      }
                    },
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(_isEditing ? Icons.visibility : Icons.edit, size: 16),
                      tooltip: _isEditing ? 'Preview' : 'Edit code',
                      onPressed: () => setState(() => _isEditing = !_isEditing),
                    ),
                    IconButton(
                      icon: Icon(_copied ? Icons.check : Icons.copy, size: 16),
                      tooltip: 'Copy code',
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: code));
                        setState(() => _copied = true);
                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) setState(() => _copied = false);
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Code Body
          if (_isEditing || code.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _controller,
                maxLines: null,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: '// Write or paste code...',
                ),
                onChanged: (val) {
                  widget.onChanged({
                    ...widget.block.content,
                    'code': val,
                  });
                },
              ),
            )
          else
            InkWell(
              onTap: () => setState(() => _isEditing = true),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: HighlightView(
                  code,
                  language: language,
                  theme: isDark ? atomOneDarkTheme : atomOneLightTheme,
                  textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 13),
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
