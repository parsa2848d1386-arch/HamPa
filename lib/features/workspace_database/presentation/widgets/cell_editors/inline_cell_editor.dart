import 'package:flutter/material.dart';
import '../../../domain/models/property_entity.dart';
import '../../../domain/models/property_type.dart';

class InlineCellEditor extends StatefulWidget {
  final PropertyEntity property;
  final String rowId;
  final dynamic value;
  final ValueChanged<dynamic> onValueChanged;
  final VoidCallback? onOpenDocument;

  const InlineCellEditor({
    super.key,
    required this.property,
    required this.rowId,
    required this.value,
    required this.onValueChanged,
    this.onOpenDocument,
  });

  @override
  State<InlineCellEditor> createState() => _InlineCellEditorState();
}

class _InlineCellEditorState extends State<InlineCellEditor> {
  bool _isEditing = false;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.value?.toString() ?? '');
  }

  @override
  void didUpdateWidget(InlineCellEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_isEditing) {
      _textController.text = widget.value?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _commitText() {
    setState(() => _isEditing = false);
    final text = _textController.text.trim();
    if (widget.property.type == PropertyType.number) {
      final numVal = num.tryParse(text);
      widget.onValueChanged(numVal);
    } else {
      widget.onValueChanged(text.isEmpty ? null : text);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.property.type) {
      case PropertyType.checkbox:
        final isChecked = widget.value == true || widget.value == 1 || widget.value == 'true';
        return Checkbox(
          value: isChecked,
          onChanged: (val) => widget.onValueChanged(val),
        );

      case PropertyType.select:
      case PropertyType.status:
        final options = (widget.property.config['options'] as List?)?.cast<String>() ?? [];
        return InkWell(
          onTap: () => _showSelectDialog(options),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: widget.value != null
                ? Chip(
                    label: Text(widget.value.toString(), style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )
                : const Text('Empty', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ),
        );

      case PropertyType.date:
        return InkWell(
          onTap: _pickDate,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              widget.value?.toString() ?? 'Empty',
              style: TextStyle(
                color: widget.value != null ? null : Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
        );

      case PropertyType.title:
        if (_isEditing) {
          return TextField(
            controller: _textController,
            autofocus: true,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(8),
            ),
            onSubmitted: (_) => _commitText(),
            onEditingComplete: _commitText,
          );
        }
        return Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _isEditing = true),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Text(
                    widget.value?.toString() ?? 'Untitled',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
            ),
            if (widget.onOpenDocument != null)
              IconButton(
                icon: const Icon(Icons.open_in_new, size: 16),
                tooltip: 'Open Page',
                onPressed: widget.onOpenDocument,
              ),
          ],
        );

      case PropertyType.formula:
      case PropertyType.rollup:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(
            widget.value?.toString() ?? '',
            style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
          ),
        );

      case PropertyType.relation:
        final dynamic val = widget.value;
        final count = (val is List) ? val.length : (val != null ? 1 : 0);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: count > 0
              ? Chip(
                  label: Text('$count linked', style: const TextStyle(fontSize: 12)),
                  visualDensity: VisualDensity.compact,
                )
              : const Text('Empty', style: TextStyle(color: Colors.grey, fontSize: 13)),
        );

      case PropertyType.number:
      case PropertyType.text:
      default:
        if (_isEditing) {
          return TextField(
            controller: _textController,
            autofocus: true,
            keyboardType: widget.property.type == PropertyType.number
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(8),
            ),
            onSubmitted: (_) => _commitText(),
            onEditingComplete: _commitText,
          );
        }
        return InkWell(
          onTap: () => setState(() => _isEditing = true),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              widget.value?.toString() ?? '',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        );
    }
  }

  void _showSelectDialog(List<String> options) {
    showDialog(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: Text('Select ${widget.property.name}'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                widget.onValueChanged(null);
                Navigator.pop(ctx);
              },
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
            ...options.map(
              (opt) => SimpleDialogOption(
                onPressed: () {
                  widget.onValueChanged(opt);
                  Navigator.pop(ctx);
                },
                child: Text(opt),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final iso = picked.toIso8601String().substring(0, 10);
      widget.onValueChanged(iso);
    }
  }
}
