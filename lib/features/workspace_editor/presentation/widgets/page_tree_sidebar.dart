import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../controllers/page_tree_cubit.dart';
import '../controllers/page_tree_state.dart';
import 'page_tree_item.dart';

class PageTreeSidebar extends StatelessWidget {
  final VoidCallback? onNewPagePressed;

  const PageTreeSidebar({
    super.key,
    this.onNewPagePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Workspace Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('هم‌پا', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'HamPA Workspace',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  tooltip: 'New Root Page',
                  onPressed: () {
                    context.read<PageTreeCubit>().createSubPage(parentPageId: null);
                  },
                ),
              ],
            ),
          ),

          // 2. Search / Quick Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search pages...',
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (query) {
                context.read<PageTreeCubit>().setSearchQuery(query);
              },
            ),
          ),

          const Divider(height: 16),

          // 3. Tree Node List (Virtualized Flattened View)
          Expanded(
            child: BlocConsumer<PageTreeCubit, PageTreeState>(
              listener: (context, state) {
                if (state.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.errorMessage!),
                      backgroundColor: theme.colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state.status == PageTreeStatus.loading && state.allPages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.flattenedNodes.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.note_alt_outlined, size: 40, color: theme.disabledColor),
                          const SizedBox(height: 8),
                          Text(
                            state.searchQuery.isNotEmpty
                                ? 'No pages match "${state.searchQuery}"'
                                : 'No pages yet',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor),
                            textAlign: TextAlign.center,
                          ),
                          if (state.searchQuery.isEmpty) ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Create a page'),
                              onPressed: () {
                                context.read<PageTreeCubit>().createSubPage(parentPageId: null);
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: state.flattenedNodes.length,
                  itemBuilder: (context, index) {
                    final node = state.flattenedNodes[index];
                    return PageTreeItem(
                      key: ValueKey(node.page.id),
                      node: node,
                      isSelected: state.selectedPageId == node.page.id,
                      pageMap: state.pageMap,
                    );
                  },
                );
              },
            ),
          ),

          // 4. Footer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add page'),
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      foregroundColor: theme.textTheme.bodyMedium?.color,
                    ),
                    onPressed: () {
                      context.read<PageTreeCubit>().createSubPage(parentPageId: null);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
