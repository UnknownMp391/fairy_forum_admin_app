import 'package:cached_network_image/cached_network_image.dart';
import 'package:fairy_forum_admin_app/api/client.dart';
import 'package:fairy_forum_admin_app/api/types/users.dart';
import 'package:fairy_forum_admin_app/components/error_ui.dart';
import 'package:fairy_forum_admin_app/components/reason_dialog.dart';
import 'package:fairy_forum_admin_app/components/paged_list.dart';
import 'package:fairy_forum_admin_app/components/selection.dart';
import 'package:fairy_forum_admin_app/dto/routes/user.dart';
import 'package:fairy_forum_admin_app/providers/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ManagementUserListPage extends HookConsumerWidget {
  const ManagementUserListPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = useSelectionState();
    final searchController = useTextEditingController();
    final query = useState<String?>(null);
    final refreshKey = useState(UniqueKey());
    final isBatchWorking = useState(false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final loadedUsers = useState<List<UserListItem>>(const []);

    final q = query.value?.trim();
    final isSearching = q != null && q.isNotEmpty;

    Future<PagedResult<UserListItem>> fetchPage(int page) async {
      final client = ref.read(apiClientProvider);
      if (isSearching) {
        final list = await client.searchUsers(q);
        return PagedResult(items: list, hasMore: false);
      }
      final list = await client.listUsers(page: page, size: 20);
      return PagedResult(items: list, hasMore: list.length == 20);
    }

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final idTextTheme = textTheme.labelMedium!.copyWith(color: Colors.grey);
    final emailTextTheme = textTheme.labelSmall!.copyWith(color: Colors.grey);
    final banLabelTextTheme = textTheme.labelLarge!.copyWith(
      color: colorScheme.error,
    );

    Future<void> batchBan() async {
      final ids = selection.selectedIds.toList();
      if (ids.isEmpty) return;
      final reason = await showReasonDialog(
        context,
        title: '批量封禁 ${ids.length} 个用户',
      );
      if (reason == null) return;
      isBatchWorking.value = true;
      try {
        final client = ref.read(apiClientProvider);
        final result = await client.batchBanUsers(
          ids,
          reason: reason.isEmpty ? null : reason,
        );
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              result.failedCount == 0
                  ? '已封禁 ${result.successCount} 个用户'
                  : '已封禁 ${result.successCount} 个，失败 ${result.failedCount} 个',
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

    Future<void> batchUnban() async {
      final ids = selection.selectedIds.toList();
      if (ids.isEmpty) return;
      isBatchWorking.value = true;
      try {
        final client = ref.read(apiClientProvider);
        final result = await client.batchUnbanUsers(ids);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              result.failedCount == 0
                  ? '已解封 ${result.successCount} 个用户'
                  : '已解封 ${result.successCount} 个，失败 ${result.failedCount} 个',
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

    Future<void> batchDeleteUsers() async {
      final ids = selection.selectedIds.toList();
      if (ids.isEmpty) return;

      final byId = {for (final u in loadedUsers.value) u.id: u};
      final missing = ids.where((id) {
        final user = byId[id];
        return user == null || user.name.isEmpty || (user.email ?? '').isEmpty;
      }).toList();
      if (missing.isNotEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('部分用户缺少用户名/邮箱信息，无法批量删除（请刷新后重试）')),
        );
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => _BatchDeleteConfirmDialog(count: ids.length),
      );
      if (confirmed != true) return;

      isBatchWorking.value = true;
      try {
        final client = ref.read(apiClientProvider);
        final items = [
          for (final id in ids)
            UserDeleteItem(
              id: id,
              userName: byId[id]!.name,
              userEmail: byId[id]!.email!,
            ),
        ];
        final result = await client.batchDeleteUsers(items);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              result.failedCount == 0
                  ? '已删除 ${result.successCount} 个用户'
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
        title: const Text('用户 '),
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
                    hintText: '搜索：用户名 / ID / 邮箱',
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
            child: PagedListView<UserListItem>(
              fetchPage: fetchPage,
              resetKey: Object.hash(q, refreshKey.value),
              emptyText: isSearching ? '未找到匹配的用户' : '暂无用户',
              onItemsChanged: (list) => loadedUsers.value = list,
              itemBuilder: (context, user) {
                final avatarHeroTag = 'user ${user.id}';

                return InkWell(
                  onTap: selection.selecting
                      ? () => selection.toggle(user.id)
                      : () {
                          context.push(
                            '/management/user/${Uri.encodeComponent(user.id)}',
                            extra: ManagementUserDetailPageExtra(
                              name: user.name,
                              avatarUrl: user.avatarUrl,
                              age: user.age,
                              bio: user.bio,
                              createdAt: user.createdAt,
                              email: user.email,
                              gender: user.gender,
                              isBanned: user.isBanned,
                              heroTag: avatarHeroTag,
                            ),
                          );
                        },
                  child: ListTile(
                    leading: SizedBox(
                      width: 64,
                      height: 64,
                      child: Hero(
                        tag: avatarHeroTag,
                        child: Material(
                          child: user.avatarUrl == null
                              ? const Icon(
                                  Icons.person,
                                  size: 48,
                                  color: Colors.grey,
                                )
                              : CachedNetworkImage(
                                  imageUrl: avatarProxyUrl(user.avatarUrl),
                                ),
                        ),
                      ),
                    ),
                    title: SizedBox(
                      height: 64,
                      child: Column(
                        crossAxisAlignment: .start,
                        mainAxisAlignment: .start,
                        children: [
                          Text(
                            user.name,
                            style: textTheme.labelLarge,
                            maxLines: 1,
                            overflow: .ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            user.id,
                            style: idTextTheme,
                            maxLines: 1,
                            overflow: .ellipsis,
                          ),
                          Text(
                            user.email ?? '',
                            style: emailTextTheme,
                            maxLines: 1,
                            overflow: .ellipsis,
                          ),
                        ],
                      ),
                    ),
                    trailing: selection.selecting
                        ? Checkbox(
                            value: selection.selectedIds.contains(user.id),
                            onChanged: (_) => selection.toggle(user.id),
                          )
                        : user.isBanned == true
                        ? Text('已封禁', style: banLabelTextTheme)
                        : null,
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
                        final all = loadedUsers.value.map((u) => u.id).toList();
                        selection.replace(
                          all.length == selection.selectedIds.length
                              ? <String>{}
                              : all.toSet(),
                        );
                      },
                      child: const Text('全选/清空'),
                    ),
                    FilledButton.tonal(
                      onPressed: isBatchWorking.value ? null : () => batchBan(),
                      child: const Text('封禁'),
                    ),
                    FilledButton.tonal(
                      onPressed: isBatchWorking.value
                          ? null
                          : () => batchUnban(),
                      child: const Text('解封'),
                    ),
                    FilledButton(
                      onPressed: isBatchWorking.value
                          ? null
                          : () => batchDeleteUsers(),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.error,
                      ),
                      child: const Text('删除'),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class _BatchDeleteConfirmDialog extends StatefulWidget {
  final int count;

  const _BatchDeleteConfirmDialog({required this.count});

  @override
  State<_BatchDeleteConfirmDialog> createState() =>
      _BatchDeleteConfirmDialogState();
}

class _BatchDeleteConfirmDialogState extends State<_BatchDeleteConfirmDialog> {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      title: const Text('批量删除用户（最高危）'),
      content: Text(
        '确定删除所选 ${widget.count} 个用户吗？'
        '将联动删除其帖子与评论（移入回收站）。',
        style: textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('删除'),
        ),
      ],
    );
  }
}
