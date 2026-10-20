import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/page_entity.dart';
import '../../domain/utils/page_tree_utils.dart';
import '../controllers/page_tree_cubit.dart';
import '../controllers/page_tree_state.dart';

class PageBreadcrumbs extends StatelessWidget {
  const PageBreadcrumbs({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const treeUtils = PageTreeUtils();

    return BlocBuilder<PageTreeCubit, PageTreeState>(
      buildWhen: (prev, curr) =>
          prev.selectedPageId != curr.selectedPageId || prev.allPages != curr.allPages,
      builder: (context, state) {
        if (state.selectedPageId == null) {
          return const SizedBox.shrink();
        }

        final breadcrumbs = treeUtils.getBreadcrumbs(
          pageId: state.selectedPageId!,
          pageMap: state.pageMap,
        );

        if (breadcrumbs.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Workspace root icon
              const Icon(Icons.home_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 4),

              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: _buildBreadcrumbItems(context, breadcrumbs, theme),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildBreadcrumbItems(
    BuildContext context,
    List<PageEntity> items,
    ThemeData theme,
  ) {
    final List<Widget> widgets = [];
    final cubit = context.read<PageTreeCubit>();

    // Handle deep nesting (> 3 ancestors) with ellipsis dropdown
    if (items.length > 3) {
      // First item
      widgets.add(_crumbButton(context, items.first, cubit, theme));
      widgets.add(const Icon(Icons.chevron_right, size: 16, color: Colors.grey));

      // Middle collapsed dropdown
      final middleItems = items.sublist(1, items.length - 1);
      widgets.add(
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_horiz, size: 16),
          padding: EdgeInsets.zero,
          itemBuilder: (ctx) => middleItems
              .map(
                (p) => PopupMenuItem<String>(
                  value: p.id,
                  child: Row(
                    children: [
                      Text(p.icon ?? '📄'),
                      const SizedBox(width: 8),
                      Text(p.title.isEmpty ? 'Untitled' : p.title),
                    ],
                  ),
                ),
              )
              .toList(),
          onSelected: (id) => cubit.selectPage(id),
        ),
      );
      widgets.add(const Icon(Icons.chevron_right, size: 16, color: Colors.grey));

      // Last item (active)
      widgets.add(_activeCrumb(items.last, theme));
    } else {
      // 1 to 3 items
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final isLast = i == items.length - 1;

        if (isLast) {
          widgets.add(_activeCrumb(item, theme));
        } else {
          widgets.add(_crumbButton(context, item, cubit, theme));
          widgets.add(const Icon(Icons.chevron_right, size: 16, color: Colors.grey));
        }
      }
    }

    return widgets;
  }

  Widget _crumbButton(BuildContext context, PageEntity page, PageTreeCubit cubit, ThemeData theme) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () => cubit.selectPage(page.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(page.icon ?? '📄', style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              page.title.isEmpty ? 'Untitled' : page.title,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activeCrumb(PageEntity page, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(page.icon ?? '📄', style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            page.title.isEmpty ? 'Untitled' : page.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
