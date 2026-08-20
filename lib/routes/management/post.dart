import 'package:fairy_forum_admin_app/api/types/posts.dart';
import 'package:fairy_forum_admin_app/components/error_ui.dart';
import 'package:fairy_forum_admin_app/components/paged_list.dart';
import 'package:fairy_forum_admin_app/components/selection.dart';
import 'package:fairy_forum_admin_app/providers/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ManagementPostPage extends HookConsumerWidget {
  const ManagementPostPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = useSelectionState();
    final searchController = useTextEditingController();
    final query = useState<String?>(null);
    final refreshKey = useState(UniqueKey());
    final isBatchWorking = useState(false);
    final loadedPosts = useState<List<PostDetail>>(const []);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final textTheme = Theme.of(context).textTheme;
    final greyStyle = textTheme.labelMedium!.copyWith(color: Colors.grey);
    final isSearching = query.value != null && query.value!.isNotEmpty;
    final q = query.value?.trim();

    Future<PagedResult<PostDetail>> fetchPage(int page) async {
      final client = ref.read(apiClientProvider);
      final list = await client.listPosts(
        page: page,
        size: 20,
        q: (q == null || q.isEmpty) ? null : q,
      );
      return PagedResult(items: list, hasMore: list.length == 20);
    }

    Future<void> batchDelete() async {
      final ids = selection.selectedIds.toList();
      if (ids.isEmpty) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('批量删除帖子'),
          content: Text(
            '确定删除所选 ${ids.length} 个帖子吗？'
            '帖子及其评论将移入回收站，此操作可恢复。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('删除'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      isBatchWorking.value = true;
      try {
        final client = ref.read(apiClientProvider);
        final result = await client.batchDeletePosts(ids);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              result.failedCount == 0
                  ? '已删除 ${result.successCount} 个帖子'
                  : '已删除 ${result.successCount} 个，失败 ${result.failedCount} 个',
            ),
          ),
        );
        selection.exit();
        refreshKey.value = UniqueKey();
      } on Exception catch (e) {
        showErrorSnackBar(scaffoldMessenger, e, prefix: '操作失败: ');
      } finally {
        isBatchWorking.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('帖子'),
        actions: [
          if (selection.selecting)
            IconButton(
              tooltip: '完成',
              icon: const Icon(Icons.check),
              onPressed: isBatchWorking.value ? null : selection.exit,
            )
          else
            IconButton(
              tooltip: '多选',
              icon: const Icon(Icons.checklist),
              onPressed: () => selection.enter(),
            ),
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: () => refreshKey.value = UniqueKey(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: '搜索：帖子 ID / 标题 / 内容',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: isSearching
                        ? IconButton(
                            tooltip: '清除搜索',
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              query.value = null;
                              searchController.clear();
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (value) => query.value = value,
                ),
              ),
            ),
          ),
          Expanded(
            child: PagedListView<PostDetail>(
              fetchPage: fetchPage,
              resetKey: Object.hash(q, refreshKey.value),
              emptyText: isSearching ? '未找到匹配的帖子' : '暂无帖子',
              onItemsChanged: (list) => loadedPosts.value = list,
              itemBuilder: (context, post) => _PostTile(
                post: post,
                greyStyle: greyStyle,
                selecting: selection.selecting,
                selected: selection.selectedIds.contains(post.id),
                onToggle: () => selection.toggle(post.id ?? ''),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: selection.selecting
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('已选 ${selection.selectedIds.length}'),
                    TextButton(
                      onPressed: () {
                        final all = loadedPosts.value
                            .map((p) => p.id)
                            .whereType<String>()
                            .toList();
                        selection.replace(
                          all.length == selection.selectedIds.length
                              ? <String>{}
                              : all.toSet(),
                        );
                      },
                      child: const Text('全选/清空'),
                    ),
                    FilledButton.tonal(
                      onPressed: isBatchWorking.value
                          ? null
                          : () => batchDelete(),
                      child: const Text('批量删除'),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class _PostTile extends StatelessWidget {
  final PostDetail post;
  final TextStyle greyStyle;
  final bool selecting;
  final bool selected;
  final VoidCallback? onToggle;

  const _PostTile({
    required this.post,
    required this.greyStyle,
    required this.selecting,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final deleted = post.status != null && post.status != 1;

    return InkWell(
      onTap: selecting
          ? onToggle
          : () {
              context.push(
                '/management/post/${Uri.encodeComponent(post.id ?? '')}',
              );
            },
      child: ListTile(
        title: Text(post.title ?? '无标题', maxLines: 1, overflow: .ellipsis),
        subtitle: Column(
          crossAxisAlignment: .start,
          children: [
            if (post.id != null) Text(post.id ?? '', style: greyStyle),
            if (post.category != null)
              Text('#${post.category}', style: greyStyle),
            if (post.userName != null)
              Text('${post.userName}', style: greyStyle),
          ],
        ),
        trailing: selecting
            ? Checkbox(value: selected, onChanged: (_) => onToggle?.call())
            : deleted
            ? Text(
                '已删除',
                style: textTheme.labelLarge!.copyWith(color: colorScheme.error),
              )
            : null,
      ),
    );
  }
}
