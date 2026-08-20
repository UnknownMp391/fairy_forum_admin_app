import 'package:fairy_forum_admin_app/api/types/comments.dart';
import 'package:fairy_forum_admin_app/components/error_ui.dart';
import 'package:fairy_forum_admin_app/components/paged_list.dart';
import 'package:fairy_forum_admin_app/components/selection.dart';
import 'package:fairy_forum_admin_app/providers/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ManagementCommentsPage extends HookConsumerWidget {
  const ManagementCommentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = useSelectionState();
    final searchController = useTextEditingController();
    final postIdController = useTextEditingController();
    final query = useState<String?>(null);
    final postId = useState<String?>(null);
    final refreshKey = useState(UniqueKey());
    final isDeleting = useState<String?>(null);
    final isBatchWorking = useState(false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final loadedComments = useState<List<Comment>>(const []);

    final q = query.value?.trim();
    final pid = postId.value?.trim();

    Future<PagedResult<Comment>> fetchPage(int page) async {
      final client = ref.read(apiClientProvider);
      final list = await client.listComments(
        page: page,
        size: 20,
        q: (q == null || q.isEmpty) ? null : q,
        postId: (pid == null || pid.isEmpty) ? null : pid,
      );
      return PagedResult(items: list, hasMore: list.length == 20);
    }

    final textTheme = Theme.of(context).textTheme;
    final greyStyle = textTheme.labelMedium!.copyWith(color: Colors.grey);

    Future<void> deleteComment(Comment comment) async {
      final id = comment.id;
      if (id == null) return;
      isDeleting.value = id;
      try {
        final client = ref.read(apiClientProvider);
        await client.deleteComment(id);
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('评论已删除')));
        refreshKey.value = UniqueKey();
      } on Exception catch (e) {
        showErrorSnackBar(scaffoldMessenger, e, prefix: '删除失败: ');
      } finally {
        isDeleting.value = null;
      }
    }

    Future<void> batchDelete() async {
      final ids = selection.selectedIds.toList();
      if (ids.isEmpty) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('批量删除评论'),
          content: Text(
            '确定删除所选 ${ids.length} 条评论吗？'
            '评论将移入回收站，此操作可恢复。',
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
        final result = await client.batchDeleteComments(ids);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              result.failedCount == 0
                  ? '已删除 ${result.successCount} 条评论'
                  : '已删除 ${result.successCount} 条，失败 ${result.failedCount} 条',
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
        title: const Text('评论'),
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
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: '搜索：评论内容 / 用户名',
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (value) => query.value = value,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: postIdController,
                      decoration: InputDecoration(
                        hintText: '按帖子 ID 筛选（可选）',
                        prefixIcon: const Icon(Icons.article_outlined),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (value) => postId.value = value,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: PagedListView<Comment>(
              fetchPage: fetchPage,
              resetKey: Object.hash(q, pid, refreshKey.value),
              emptyText: '暂无评论',
              onItemsChanged: (list) => loadedComments.value = list,
              itemBuilder: (context, comment) => _CommentTile(
                comment: comment,
                isDeleting: isDeleting.value == comment.id,
                onDelete: () => deleteComment(comment),
                selecting: selection.selecting,
                selected: selection.selectedIds.contains(comment.id),
                onToggle: () => selection.toggle(comment.id ?? ''),
                greyStyle: greyStyle,
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
                        final all = loadedComments.value
                            .map((c) => c.id)
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

class _CommentTile extends StatelessWidget {
  final Comment comment;
  final bool isDeleting;
  final Future<void> Function() onDelete;
  final bool selecting;
  final bool selected;
  final VoidCallback? onToggle;
  final TextStyle greyStyle;

  const _CommentTile({
    required this.comment,
    required this.isDeleting,
    required this.onDelete,
    required this.selecting,
    required this.selected,
    required this.onToggle,
    required this.greyStyle,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final deleted = comment.status != null && comment.status != 1;
    final postId = comment.postId;

    return InkWell(
      onTap: selecting
          ? onToggle
          : postId == null || comment.id == null
          ? null
          : () {
              context.push(
                '/management/comment/${Uri.encodeComponent(comment.id!)}/replies?postId=${Uri.encodeComponent(postId)}',
              );
            },
      child: ListTile(
        title: Text(
          comment.content ?? '（无内容）',
          maxLines: 2,
          overflow: .ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: .start,
          children: [
            if (comment.id != null) Text('${comment.id}', style: greyStyle),
            if (comment.userName != null)
              Text('${comment.userName}', style: greyStyle),
            /*if (comment.createdAt != null)
              Text(
                'at ${formatDateTime(comment.createdAt!)}',
                style: greyStyle,
              ),*/
            if (deleted)
              Text(
                '已删除',
                style: textTheme.labelSmall!.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
          ],
        ),
        trailing: selecting
            ? Checkbox(value: selected, onChanged: (_) => onToggle?.call())
            : comment.id == null
            ? null
            : IconButton(
                tooltip: '删除评论',
                onPressed: isDeleting ? null : onDelete,
                icon: isDeleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline),
              ),
      ),
    );
  }
}
