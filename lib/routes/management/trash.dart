import 'package:fairy_forum_admin_app/api/types/trash.dart';
import 'package:fairy_forum_admin_app/components/error_ui.dart';
import 'package:fairy_forum_admin_app/components/paged_list.dart';
import 'package:fairy_forum_admin_app/components/selection.dart';
import 'package:fairy_forum_admin_app/providers/api_client.dart';
import 'package:fairy_forum_admin_app/utils/datetime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ManagementTrashPage extends HookConsumerWidget {
  const ManagementTrashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('回收站')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            children: [
              _TrashEntryTile(
                icon: Icons.article_outlined,
                label: '帖子回收站',
                subtitle: '被删除的帖子（含其评论）',
                onTap: () => context.push('/management/trash/posts'),
              ),
              const Divider(height: 16),
              _TrashEntryTile(
                icon: Icons.comment,
                label: '评论回收站',
                subtitle: '被删除的评论',
                onTap: () => context.push('/management/trash/comments'),
              ),
              const Divider(height: 16),
              _TrashEntryTile(
                icon: Icons.person,
                label: '用户回收站',
                subtitle: '被删除的用户（含其帖子、评论）',
                onTap: () => context.push('/management/trash/users'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrashEntryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _TrashEntryTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ListTile(
        leading: Icon(icon),
        trailing: const Icon(Icons.arrow_forward),
        title: Text(label),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class TrashPostsPage extends HookConsumerWidget {
  const TrashPostsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = useSelectionState();
    final searchController = useTextEditingController();
    final query = useState<String?>(null);
    final refreshKey = useState(UniqueKey());
    final isRestoring = useState<String?>(null);
    final isBatchWorking = useState(false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final loadedItems = useState<List<TrashPost>>(const []);

    final q = query.value?.trim();

    Future<PagedResult<TrashPost>> fetchPage(int page) async {
      final client = ref.read(apiClientProvider);
      final list = await client.listTrashPosts(
        page: page,
        size: 20,
        q: (q == null || q.isEmpty) ? null : q,
      );
      return PagedResult(items: list, hasMore: list.length == 20);
    }

    final textTheme = Theme.of(context).textTheme;
    final greyStyle = textTheme.labelMedium!.copyWith(color: Colors.grey);

    Future<void> batchRestore() async {
      final ids = selection.selectedIds.toList();
      if (ids.isEmpty) return;
      isBatchWorking.value = true;
      try {
        final client = ref.read(apiClientProvider);
        final result = await client.batchRestoreTrash(ids, 'posts');
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              result.failedCount == 0
                  ? '已恢复 ${result.successCount} 个帖子'
                  : '已恢复 ${result.successCount} 个，失败 ${result.failedCount} 个',
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

    Future<void> restore(TrashPost item) async {
      final confirmed = await _confirmRestore(
        context,
        title: '恢复帖子',
        message: '确定恢复帖子「${item.originalPost?.title ?? item.id}」及其全部评论吗？',
      );
      if (!confirmed) return;
      isRestoring.value = item.id;
      try {
        final client = ref.read(apiClientProvider);
        await client.restoreTrashPost(item.id);
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('帖子已恢复')));
        refreshKey.value = UniqueKey();
      } on Exception catch (e) {
        showErrorSnackBar(scaffoldMessenger, e, prefix: '恢复失败: ');
      } finally {
        isRestoring.value = null;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('帖子回收站'),
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
          _TrashSearchField(
            controller: searchController,
            hintText: '搜索：帖子 ID',
            isSearching: query.value != null && query.value!.isNotEmpty,
            onSubmitted: (v) => query.value = v,
            onClear: () {
              query.value = null;
              searchController.clear();
            },
          ),
          Expanded(
            child: PagedListView<TrashPost>(
              fetchPage: fetchPage,
              resetKey: Object.hash(q, refreshKey.value),
              emptyText: '回收站暂无帖子',
              onItemsChanged: (list) => loadedItems.value = list,
              itemBuilder: (context, item) {
                final post = item.originalPost;
                return ListTile(
                  title: Text(
                    post?.title ?? '（无标题）',
                    maxLines: 1,
                    overflow: .ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: .start,
                    children: [
                      if (post?.id != null)
                        Text('${post!.id}', style: greyStyle),
                      if (post?.category != null)
                        Text('#${post!.category}', style: greyStyle),
                      _TrashMeta(
                        reason: item.deleteReason,
                        deletedBy: item.deletedByAdminName,
                        deletedAt: item.deletedAt,
                        greyStyle: greyStyle,
                      ),
                    ],
                  ),
                  trailing: selection.selecting
                      ? Checkbox(
                          value: selection.selectedIds.contains(item.id),
                          onChanged: (_) => selection.toggle(item.id),
                        )
                      : _RestoreButton(
                          isRestoring: isRestoring.value == item.id,
                          onRestore: () => restore(item),
                        ),
                );
              },
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
                        final all = loadedItems.value.map((t) => t.id).toList();
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
                          : () => batchRestore(),
                      child: const Text('批量恢复'),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class TrashCommentsPage extends HookConsumerWidget {
  const TrashCommentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = useSelectionState();
    final searchController = useTextEditingController();
    final query = useState<String?>(null);
    final refreshKey = useState(UniqueKey());
    final isRestoring = useState<String?>(null);
    final isBatchWorking = useState(false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final loadedItems = useState<List<TrashComment>>(const []);

    final q = query.value?.trim();

    Future<PagedResult<TrashComment>> fetchPage(int page) async {
      final client = ref.read(apiClientProvider);
      final list = await client.listTrashComments(
        page: page,
        size: 20,
        q: (q == null || q.isEmpty) ? null : q,
      );
      return PagedResult(items: list, hasMore: list.length == 20);
    }

    final textTheme = Theme.of(context).textTheme;
    final greyStyle = textTheme.labelMedium!.copyWith(color: Colors.grey);

    Future<void> batchRestore() async {
      final ids = selection.selectedIds.toList();
      if (ids.isEmpty) return;
      isBatchWorking.value = true;
      try {
        final client = ref.read(apiClientProvider);
        final result = await client.batchRestoreTrash(ids, 'comments');
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              result.failedCount == 0
                  ? '已恢复 ${result.successCount} 条评论'
                  : '已恢复 ${result.successCount} 条，失败 ${result.failedCount} 条',
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

    Future<void> restore(TrashComment item) async {
      final confirmed = await _confirmRestore(
        context,
        title: '恢复评论',
        message: '确定恢复该评论吗？（其所属帖子必须存在，否则需先恢复帖子）',
      );
      if (!confirmed) return;
      isRestoring.value = item.id;
      try {
        final client = ref.read(apiClientProvider);
        await client.restoreTrashComment(item.id);
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('评论已恢复')));
        refreshKey.value = UniqueKey();
      } on Exception catch (e) {
        showErrorSnackBar(scaffoldMessenger, e, prefix: '恢复失败: ');
      } finally {
        isRestoring.value = null;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('评论回收站'),
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
          _TrashSearchField(
            controller: searchController,
            hintText: '搜索：评论 ID',
            isSearching: query.value != null && query.value!.isNotEmpty,
            onSubmitted: (v) => query.value = v,
            onClear: () {
              query.value = null;
              searchController.clear();
            },
          ),
          Expanded(
            child: PagedListView<TrashComment>(
              fetchPage: fetchPage,
              resetKey: Object.hash(q, refreshKey.value),
              emptyText: '回收站暂无评论',
              onItemsChanged: (list) => loadedItems.value = list,
              itemBuilder: (context, item) {
                final comment = item.originalComment;
                return ListTile(
                  title: Text(
                    comment?.content ?? '（无内容）',
                    maxLines: 2,
                    overflow: .ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: .start,
                    children: [
                      if (comment?.id != null)
                        Text('${comment!.id}', style: greyStyle),
                      if (comment?.userName != null)
                        Text('${comment!.userName}', style: greyStyle),
                      _TrashMeta(
                        reason: item.deleteReason,
                        deletedBy: item.deletedByAdminName,
                        deletedAt: item.deletedAt,
                        greyStyle: greyStyle,
                      ),
                    ],
                  ),
                  trailing: selection.selecting
                      ? Checkbox(
                          value: selection.selectedIds.contains(item.id),
                          onChanged: (_) => selection.toggle(item.id),
                        )
                      : _RestoreButton(
                          isRestoring: isRestoring.value == item.id,
                          onRestore: () => restore(item),
                        ),
                );
              },
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
                        final all = loadedItems.value.map((t) => t.id).toList();
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
                          : () => batchRestore(),
                      child: const Text('批量恢复'),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class TrashUsersPage extends HookConsumerWidget {
  const TrashUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = useSelectionState();
    final searchController = useTextEditingController();
    final query = useState<String?>(null);
    final refreshKey = useState(UniqueKey());
    final isRestoring = useState<String?>(null);
    final isBatchWorking = useState(false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final loadedItems = useState<List<TrashUser>>(const []);

    final q = query.value?.trim();

    Future<PagedResult<TrashUser>> fetchPage(int page) async {
      final client = ref.read(apiClientProvider);
      final list = await client.listTrashUsers(
        page: page,
        size: 20,
        q: (q == null || q.isEmpty) ? null : q,
      );
      return PagedResult(items: list, hasMore: list.length == 20);
    }

    final textTheme = Theme.of(context).textTheme;
    final greyStyle = textTheme.labelMedium!.copyWith(color: Colors.grey);

    Future<void> batchRestore() async {
      final ids = selection.selectedIds.toList();
      if (ids.isEmpty) return;
      isBatchWorking.value = true;
      try {
        final client = ref.read(apiClientProvider);
        final result = await client.batchRestoreTrash(ids, 'users');
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              result.failedCount == 0
                  ? '已恢复 ${result.successCount} 个用户'
                  : '已恢复 ${result.successCount} 个，失败 ${result.failedCount} 个',
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

    Future<void> restore(TrashUser item) async {
      final confirmed = await _confirmRestore(
        context,
        title: '恢复用户',
        message: '确定恢复用户「${item.originalUser?.name ?? item.id}」及其所有帖子、评论吗？',
      );
      if (!confirmed) return;
      isRestoring.value = item.id;
      try {
        final client = ref.read(apiClientProvider);
        await client.restoreTrashUser(item.id);
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('用户已恢复')));
        refreshKey.value = UniqueKey();
      } on Exception catch (e) {
        showErrorSnackBar(scaffoldMessenger, e, prefix: '恢复失败: ');
      } finally {
        isRestoring.value = null;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('用户回收站'),
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
          _TrashSearchField(
            controller: searchController,
            hintText: '搜索：用户 ID / 用户名',
            isSearching: query.value != null && query.value!.isNotEmpty,
            onSubmitted: (v) => query.value = v,
            onClear: () {
              query.value = null;
              searchController.clear();
            },
          ),
          Expanded(
            child: PagedListView<TrashUser>(
              fetchPage: fetchPage,
              resetKey: Object.hash(q, refreshKey.value),
              emptyText: '回收站暂无用户',
              onItemsChanged: (list) => loadedItems.value = list,
              itemBuilder: (context, item) {
                final user = item.originalUser;
                return ListTile(
                  title: Text(
                    user?.name ?? '（未知）',
                    maxLines: 1,
                    overflow: .ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: .start,
                    children: [
                      if (user?.id != null) Text(user!.id, style: greyStyle),
                      if (user?.email != null)
                        Text('${user!.email}', style: greyStyle),
                      _TrashMeta(
                        reason: item.deleteReason,
                        deletedBy: item.deletedByAdminName,
                        deletedAt: item.deletedAt,
                        greyStyle: greyStyle,
                      ),
                    ],
                  ),
                  trailing: selection.selecting
                      ? Checkbox(
                          value: selection.selectedIds.contains(item.id),
                          onChanged: (_) => selection.toggle(item.id),
                        )
                      : _RestoreButton(
                          isRestoring: isRestoring.value == item.id,
                          onRestore: () => restore(item),
                        ),
                );
              },
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
                        final all = loadedItems.value.map((t) => t.id).toList();
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
                          : () => batchRestore(),
                      child: const Text('批量恢复'),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class _TrashSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isSearching;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  const _TrashSearchField({
    required this.controller,
    required this.hintText,
    required this.isSearching,
    required this.onSubmitted,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: isSearching
                  ? IconButton(
                      tooltip: '清除搜索',
                      icon: const Icon(Icons.clear),
                      onPressed: onClear,
                    )
                  : null,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onSubmitted: onSubmitted,
          ),
        ),
      ),
    );
  }
}

class _RestoreButton extends StatelessWidget {
  final bool isRestoring;
  final VoidCallback onRestore;

  const _RestoreButton({required this.isRestoring, required this.onRestore});

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: isRestoring ? null : onRestore,
      icon: isRestoring
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.restore),
      label: const Text('恢复'),
    );
  }
}

class _TrashMeta extends StatelessWidget {
  final String? reason;
  final String? deletedBy;
  final DateTime? deletedAt;
  final TextStyle greyStyle;

  const _TrashMeta({
    required this.reason,
    required this.deletedBy,
    required this.deletedAt,
    required this.greyStyle,
  });

  @override
  Widget build(BuildContext context) {
    final reason = this.reason;
    final deletedBy = this.deletedBy;
    final deletedAt = this.deletedAt;

    return Column(
      crossAxisAlignment: .start,
      children: [
        if (deletedBy != null && deletedBy.isNotEmpty)
          Text('$deletedBy 删除', style: greyStyle),
        if (reason != null && reason.isNotEmpty) Text(reason, style: greyStyle),
        if (deletedAt != null)
          Text(formatDateTime(deletedAt), style: greyStyle),
      ],
    );
  }
}

Future<bool> _confirmRestore(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('恢复'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
