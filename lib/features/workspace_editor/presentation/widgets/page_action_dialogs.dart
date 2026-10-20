import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/page_entity.dart';
import '../controllers/page_tree_cubit.dart';

class PageActionDialogs {
  /// Opens options menu for a page.
  static void showPageMenu(BuildContext context, PageEntity page) {
    final cubit = context.read<PageTreeCubit>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Text(page.icon ?? '📄', style: const TextStyle(fontSize: 22)),
              title: Text(page.title.isEmpty ? 'Untitled' : page.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(page.isDatabaseRow ? 'Database Record' : 'Workspace Document'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename page'),
              onTap: () {
                Navigator.pop(ctx);
                showRenameDialog(context, page);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_box_outlined),
              title: const Text('Add sub-page'),
              onTap: () {
                Navigator.pop(ctx);
                cubit.createSubPage(parentPageId: page.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_emotions_outlined),
              title: const Text('Change icon'),
              onTap: () {
                Navigator.pop(ctx);
                showEmojiPicker(context, page);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete page', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                showDeleteConfirmation(context, page);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog to rename a page.
  static void showRenameDialog(BuildContext context, PageEntity page) {
    final controller = TextEditingController(text: page.title);
    final cubit = context.read<PageTreeCubit>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Page'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Page Title',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              cubit.renamePage(pageId: page.id, newTitle: value.trim());
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                cubit.renamePage(pageId: page.id, newTitle: controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Emoji and icon selection sheet.
  static void showEmojiPicker(BuildContext context, PageEntity page) {
    const emojis = ['📄', '📝', '📚', '🎯', '💡', '🔬', '💻', '📅', '⏰', '⚡', '🏆', '🔥', '📊', '🎨', '🧠', '🌿'];
    final cubit = context.read<PageTreeCubit>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose Page Icon'),
        content: SizedBox(
          width: 280,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: emojis
                .map(
                  (emoji) => InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      cubit.updatePageIcon(pageId: page.id, newIcon: emoji);
                      Navigator.pop(ctx);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              cubit.updatePageIcon(pageId: page.id, newIcon: null);
              Navigator.pop(ctx);
            },
            child: const Text('Remove Icon'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  /// Delete confirmation dialog.
  static void showDeleteConfirmation(BuildContext context, PageEntity page) {
    final cubit = context.read<PageTreeCubit>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Page?'),
        content: Text('Are you sure you want to delete "${page.title.isEmpty ? 'Untitled' : page.title}"? Sub-pages will also be archived.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              cubit.archivePage(page.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
