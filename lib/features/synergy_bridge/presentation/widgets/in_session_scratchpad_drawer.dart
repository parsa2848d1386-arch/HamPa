import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'package:hampa/core/database/app_database.dart';
import 'package:hampa/core/database/daos/blocks_dao.dart';

class InSessionScratchpadDrawer extends StatefulWidget {
  final String? pageId;
  final BlocksDao? blocksDao;
  final String? initialText;
  final ValueChanged<String>? onSave;
  final Duration debounceDuration;

  const InSessionScratchpadDrawer({
    super.key,
    this.pageId,
    this.blocksDao,
    this.initialText,
    this.onSave,
    this.debounceDuration = const Duration(milliseconds: 500),
  });

  @override
  State<InSessionScratchpadDrawer> createState() => _InSessionScratchpadDrawerState();
}

class _InSessionScratchpadDrawerState extends State<InSessionScratchpadDrawer> {
  late final TextEditingController _controller;
  Timer? _debounceTimer;
  String? _buffer;
  bool _isSaving = false;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
    _buffer = widget.initialText;
    _loadExistingBlocks();
  }

  Future<void> _loadExistingBlocks() async {
    if (widget.pageId == null || widget.blocksDao == null) {
      setState(() => _isLoaded = true);
      return;
    }

    try {
      final blocks = await widget.blocksDao!.getBlocksForPage(widget.pageId!);
      if (blocks.isNotEmpty && _controller.text.isEmpty) {
        final buffer = StringBuffer();
        for (final b in blocks) {
          try {
            final parsed = jsonDecode(b.contentJson);
            if (parsed is Map && parsed.containsKey('text')) {
              buffer.writeln(parsed['text']);
            } else if (parsed is String) {
              buffer.writeln(parsed);
            }
          } catch (_) {
            if (b.contentJson.isNotEmpty && b.contentJson != '{}') {
              buffer.writeln(b.contentJson);
            }
          }
        }
        final loadedText = buffer.toString().trim();
        if (loadedText.isNotEmpty) {
          _controller.text = loadedText;
          _buffer = loadedText;
        }
      }
    } catch (_) {
      // Graceful fallback to initial text
    } finally {
      if (mounted) {
        setState(() => _isLoaded = true);
      }
    }
  }

  void _onTextChanged(String val) {
    _buffer = val;
    widget.onSave?.call(val);

    if (widget.pageId == null || widget.blocksDao == null) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      _flushToDb();
    });
  }

  Future<void> _flushToDb({bool isDisposing = false}) async {
    if (widget.pageId == null || widget.blocksDao == null) return;
    final textToSave = _buffer ?? _controller.text;

    if (mounted && !isDisposing) {
      setState(() => _isSaving = true);
    }

    try {
      final existingBlocks = await widget.blocksDao!.getBlocksForPage(widget.pageId!);
      final scratchBlock = existingBlocks.where((b) {
        return b.id.startsWith('scratch_${widget.pageId}') ||
            (b.blockType == 'text' && b.parentBlockId == null);
      }).firstOrNull;

      final contentJson = jsonEncode({'text': textToSave});

      if (scratchBlock != null) {
        await widget.blocksDao!.updateBlockContentAndType(
          id: scratchBlock.id,
          blockType: 'text',
          contentJson: contentJson,
          updatedAt: DateTime.now(),
        );
      } else {
        final now = DateTime.now();
        await widget.blocksDao!.insertBlock(
          BlocksCompanion.insert(
            id: 'scratch_${widget.pageId}_${now.millisecondsSinceEpoch}',
            pageId: widget.pageId!,
            blockType: 'text',
            orderKey: 'm',
            contentJson: Value(contentJson),
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    } catch (_) {
      // Non-blocking error handling to preserve focus lock
    } finally {
      if (mounted && !isDisposing) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Explicitly flushes current buffer to SQLite database
  Future<void> flush() async {
    _debounceTimer?.cancel();
    await _flushToDb();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (_buffer != null && widget.pageId != null && widget.blocksDao != null) {
      // Fire-and-forget final flush on unmount without setState
      _flushToDb(isDisposing: true);
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            'In-Session Scratchpad',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_isSaving) ...[
                          const SizedBox(width: 8),
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () async {
                      await flush();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              ),
              const Text(
                'Jot down quick thoughts or todos without exiting your focus lock.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: !_isLoaded
                    ? const Center(child: CircularProgressIndicator())
                    : TextField(
                        controller: _controller,
                        maxLines: null,
                        expands: true,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(
                          hintText: '- Key formulas to memorize...\n- Questions to ask instructor...',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: _onTextChanged,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
