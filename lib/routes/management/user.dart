import 'package:cached_network_image/cached_network_image.dart';
import 'package:fairy_forum_admin_app/api/types/posts.dart';
import 'package:fairy_forum_admin_app/api/client.dart';
import 'package:fairy_forum_admin_app/api/types/users.dart';
import 'package:fairy_forum_admin_app/components/copyable.dart';
import 'package:fairy_forum_admin_app/components/error_ui.dart';
import 'package:fairy_forum_admin_app/components/reason_dialog.dart';
import 'package:fairy_forum_admin_app/dto/routes/user.dart';
import 'package:fairy_forum_admin_app/providers/api_client.dart';
import 'package:fairy_forum_admin_app/utils/datetime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ManagementUserDetailPage extends HookConsumerWidget {
  final String id;
  final Object? extra;

  const ManagementUserDetailPage({super.key, required this.id, this.extra});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reloadKey = useState(UniqueKey());

    final isProcessing = useState(false);
    final isDeletingUser = useState(false);

    final preload = extra is ManagementUserDetailPageExtra
        ? extra as ManagementUserDetailPageExtra
        : null;

    final snapshot = useFuture(
      useMemoized(() async {
        final client = ref.read(apiClientProvider);
        return client.getUser(id);
      }, [reloadKey.value]),
      preserveState: false,
    );

    final name = snapshot.data?.name ?? preload?.name;
    final createdAt = snapshot.data?.createdAt ?? preload?.createdAt;
    final age = snapshot.data?.age ?? preload?.age;
    final avatarUrl = snapshot.data?.avatarUrl ?? preload?.avatarUrl;
    final bio = snapshot.data?.bio ?? preload?.bio;
    final email = snapshot.data?.email ?? preload?.email;
    final gender = snapshot.data?.gender ?? preload?.gender;
    final isBanned = snapshot.data?.isBanned ?? preload?.isBanned;
    final avatarHeroTag = preload?.heroTag;

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    Future<void> deleteUser() async {
      final result =
          await showDialog<
            ({String userName, String userEmail, String? reason})
          >(
            context: context,
            builder: (ctx) =>
                _DeleteUserDialog(userName: name ?? '', userEmail: email ?? ''),
          );
      if (result == null) return;
      isDeletingUser.value = true;
      try {
        final client = ref.read(apiClientProvider);
        await client.deleteUser(
          id,
          reason: result.reason,
          userName: result.userName,
          userEmail: result.userEmail,
        );
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('用户已删除')));
        if (context.mounted) {
          context.pop();
        }
      } on Exception catch (e) {
        showErrorSnackBar(scaffoldMessenger, e, prefix: '删除失败: ');
      } finally {
        isDeletingUser.value = false;
      }
    }

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final infoLabelTextTheme = textTheme.labelLarge!.copyWith(
      color: Colors.grey,
    );

    return Scaffold(
      appBar: AppBar(title: Text(name ?? '加载中...')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.only(top: 32.0, bottom: 8.0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        Row(
                          crossAxisAlignment: .center,
                          children: [
                            SizedBox(
                              width: 72,
                              height: 72,
                              child: Hero(
                                tag: avatarHeroTag ?? id,
                                child: Material(
                                  child: avatarUrl == null
                                      ? null
                                      : CachedNetworkImage(
                                          imageUrl: ApiClient.avatarProxyUrl(
                                            avatarUrl,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: .start,
                                crossAxisAlignment: .start,
                                children: [
                                  CopyableWidget(
                                    value: name ?? '',
                                    copyOnLongPress: true,
                                    withInk: true,
                                    child: Text(
                                      name ?? '',
                                      style: textTheme.titleLarge,
                                      maxLines: 1,
                                      overflow: .ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  CopyableWidget(
                                    value: id,
                                    copyOnLongPress: true,
                                    withInk: true,
                                    child: Text(
                                      id,
                                      style: textTheme.bodyMedium!.copyWith(
                                        color: Colors.grey,
                                      ),
                                      maxLines: 1,
                                      overflow: .ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isBanned ?? false)
                              Align(
                                alignment: .centerEnd,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 16,
                                    right: 16,
                                  ),
                                  child: Text(
                                    '已封禁',
                                    style: textTheme.labelLarge!.copyWith(
                                      color: colorScheme.error,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(bio ?? ''),
                        const SizedBox(height: 16),
                        ListView(
                          shrinkWrap: true,
                          children: [
                            Row(
                              children: [
                                Text('E-Mail:', style: infoLabelTextTheme),
                                const SizedBox(width: 4),
                                CopyableWidget(
                                  value: email ?? '',
                                  copyOnLongPress: true,
                                  withInk: true,
                                  child: Text(email ?? ''),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text('出生日期:', style: infoLabelTextTheme),
                                const SizedBox(width: 4),
                                CopyableWidget(
                                  value: formatBirthdate(age),
                                  copyOnLongPress: true,
                                  withInk: true,
                                  child: Text(formatBirthdate(age)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text('性别:', style: infoLabelTextTheme),
                                const SizedBox(width: 4),
                                Text(gender == null ? '' : genderLabel(gender)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text('注册时间:', style: infoLabelTextTheme),
                                const SizedBox(width: 4),
                                CopyableWidget(
                                  value: createdAt == null
                                      ? ''
                                      : formatDateTime(createdAt),
                                  copyOnLongPress: true,
                                  withInk: true,
                                  child: Text(
                                    createdAt == null
                                        ? ''
                                        : formatDateTime(createdAt),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                          ],
                        ),
                        if ((!snapshot.hasData && !snapshot.hasError) ||
                            isProcessing.value)
                          const LinearProgressIndicator(),
                        const Divider(),
                        Row(
                          children: [
                            FilledButton(
                              onPressed: () async {
                                if (isBanned != null) {
                                  String? reason;
                                  if (!isBanned) {
                                    reason = await showReasonDialog(
                                      context,
                                      title: '封禁用户',
                                    );
                                    if (reason == null) return;
                                  }
                                  isProcessing.value = true;
                                  try {
                                    final client = ref.read(apiClientProvider);
                                    if (isBanned) {
                                      await client.unbanUser(id);
                                    } else {
                                      await client.banUser(
                                        id,
                                        reason: reason!.isEmpty ? null : reason,
                                      );
                                    }
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text(isBanned ? '已解封' : '已封禁'),
                                      ),
                                    );
                                    reloadKey.value = UniqueKey();
                                  } on Exception catch (e) {
                                    showErrorSnackBar(
                                      scaffoldMessenger,
                                      e,
                                      prefix: '操作失败: ',
                                    );
                                  } finally {
                                    isProcessing.value = false;
                                  }
                                }
                              },
                              child: Text(isBanned ?? false ? '解禁' : '封禁'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: isDeletingUser.value
                                  ? null
                                  : deleteUser,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colorScheme.error,
                              ),
                              icon: isDeletingUser.value
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.person_off_outlined),
                              label: const Text('删除用户'),
                            ),
                          ],
                        ),
                        const Divider(),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 16),
                  sliver: SliverToBoxAdapter(
                    child: _UserStatsSection(userId: id),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 16),
                  sliver: SliverToBoxAdapter(
                    child: _BanHistorySection(userId: id),
                  ),
                ),
                _UserPostsSection(userId: id),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BanHistorySection extends HookConsumerWidget {
  final String userId;

  const _BanHistorySection({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refreshKey = useState(0);
    final future = useMemoized(() async {
      final client = ref.read(apiClientProvider);
      return client.getUserBanHistory(userId);
    }, [userId, refreshKey.value]);
    final snapshot = useFuture(future, preserveState: false);

    final textTheme = Theme.of(context).textTheme;
    final greyStyle = textTheme.labelMedium!.copyWith(color: Colors.grey);

    if (snapshot.connectionState == ConnectionState.waiting) {
      return const SizedBox.shrink();
    }
    final entries = snapshot.data ?? const <BanHistoryEntry>[];

    return Column(
      crossAxisAlignment: .start,
      children: [
        Text('封禁历史 (${entries.length})', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        if (snapshot.hasError)
          SectionErrorView(
            error: snapshot.error!,
            onRetry: () => refreshKey.value++,
            context: 'user-ban-history',
          )
        else if (entries.isEmpty)
          Text('暂无封禁/解封记录', style: greyStyle)
        else
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    '${entry.action == 'ban' ? '封禁' : '解封'}'
                    '${entry.reason != null && entry.reason!.isNotEmpty ? ' · ${entry.reason}' : ''}',
                    style: textTheme.bodyMedium,
                  ),
                  if (entry.adminName != null)
                    Text('操作人: ${entry.adminName}', style: greyStyle),
                  if (entry.createdAt != null)
                    Text(formatDateTime(entry.createdAt!), style: greyStyle),
                ],
              ),
            ),
      ],
    );
  }
}

class _UserStatsSection extends HookConsumerWidget {
  final String userId;

  const _UserStatsSection({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = useMemoized(() async {
      final client = ref.read(apiClientProvider);
      return client.getUserStats(userId);
    }, [userId]);
    final snapshot = useFuture(future, preserveState: false);

    if (!snapshot.hasData) {
      return const SizedBox.shrink();
    }
    final stats = snapshot.data!;
    return Row(
      children: [
        _StatsChip(label: '帖子', value: stats.postCount),
        const SizedBox(width: 12),
        _StatsChip(label: '评论', value: stats.commentCount),
      ],
    );
  }
}

class _StatsChip extends StatelessWidget {
  final String label;
  final int value;

  const _StatsChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Chip(label: Text('$label: $value', style: textTheme.labelLarge));
  }
}

class _UserPostsSection extends HookConsumerWidget {
  final String userId;

  const _UserPostsSection({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = useState<List<PostDetail>>(const []);
    final page = useState(1);
    final hasMore = useState(true);
    final initialLoading = useState(true);
    final loadingMore = useState(false);
    final error = useState<Object?>(null);

    Future<void> load(int targetPage) async {
      try {
        final client = ref.read(apiClientProvider);
        final list = await client.getUserPosts(
          userId,
          page: targetPage,
          size: 20,
        );
        if (list.isNotEmpty) {
          posts.value = [...posts.value, ...list];
        }
        if (list.length < 20 || list.isEmpty) {
          hasMore.value = false;
        }
        page.value = targetPage + 1;
      } catch (e) {
        error.value = e;
      } finally {
        initialLoading.value = false;
        loadingMore.value = false;
      }
    }

    useEffect(() {
      if (initialLoading.value) {
        load(1);
      }
      return null;
    }, const []);

    void maybeLoadMore() {
      if (hasMore.value && !initialLoading.value && !loadingMore.value) {
        loadingMore.value = true;
        load(page.value);
      }
    }

    final textTheme = Theme.of(context).textTheme;
    final greyStyle = textTheme.labelMedium!.copyWith(color: Colors.grey);

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Text(
            '帖子${posts.value.isEmpty && initialLoading.value ? '' : ' (${posts.value.length})'}',
            style: textTheme.titleMedium,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        if (initialLoading.value)
          const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (error.value != null && posts.value.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            sliver: SliverToBoxAdapter(
              child: SectionErrorView(
                error: error.value!,
                onRetry: () {
                  error.value = null;
                  initialLoading.value = true;
                  load(1);
                },
                context: 'user-posts',
              ),
            ),
          )
        else if (posts.value.isEmpty)
          const SliverPadding(
            padding: EdgeInsets.symmetric(vertical: 8),
            sliver: SliverToBoxAdapter(child: Text('暂无帖子')),
          )
        else ...[
          SliverList.builder(
            itemCount: posts.value.length,
            itemBuilder: (context, index) {
              final post = posts.value[index];
              return InkWell(
                onTap: () {
                  context.push(
                    '/management/post/${Uri.encodeComponent(post.id ?? '')}',
                  );
                },
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    post.title ?? '（无标题）',
                    maxLines: 1,
                    overflow: .ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: .start,
                    children: [
                      if (post.category != null)
                        Text(post.category!, style: greyStyle),
                      if (post.createdAt != null)
                        Text(formatDateTime(post.createdAt!), style: greyStyle),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              );
            },
          ),
          SliverToBoxAdapter(
            child: Builder(
              builder: (context) {
                if (hasMore.value) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => maybeLoadMore(),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: hasMore.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('没有更多了', style: greyStyle),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _DeleteUserDialog extends StatefulWidget {
  final String userName;
  final String userEmail;

  const _DeleteUserDialog({required this.userName, required this.userEmail});

  @override
  State<_DeleteUserDialog> createState() => _DeleteUserDialogState();
}

class _DeleteUserDialogState extends State<_DeleteUserDialog> {
  late final _nameController = TextEditingController(text: widget.userName);
  late final _emailController = TextEditingController(text: widget.userEmail);
  final _reasonController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    final userName = _nameController.text.trim();
    final userEmail = _emailController.text.trim();
    final reason = _reasonController.text.trim();

    if (userName.isEmpty || userEmail.isEmpty) {
      setState(() => _error = '用户名和邮箱不能为空');
      return;
    }
    Navigator.pop(context, (
      userName: userName,
      userEmail: userEmail,
      reason: reason.isEmpty ? null : reason,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      title: const Text('删除用户（最高危）'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            Text(
              '将删除该用户及其所有帖子、评论（移入回收站）。'
              '用户名 / 邮箱须与数据库完全一致。',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '用户名（须与数据库一致）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: '邮箱（须与数据库一致）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: '删除原因（可选）',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('删除'),
        ),
      ],
    );
  }
}
