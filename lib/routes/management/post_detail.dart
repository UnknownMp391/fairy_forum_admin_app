import 'package:fairy_forum_admin_app/api/types/posts.dart';
import 'package:fairy_forum_admin_app/components/comment_list.dart';
import 'package:fairy_forum_admin_app/components/copyable.dart';
import 'package:fairy_forum_admin_app/components/error_ui.dart';
import 'package:fairy_forum_admin_app/dto/routes/user.dart';
import 'package:fairy_forum_admin_app/providers/api_client.dart';
import 'package:fairy_forum_admin_app/utils/datetime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ManagementPostDetailPage extends HookConsumerWidget {
  final String id;

  const ManagementPostDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reloadKey = useState(UniqueKey());
    final isDeleting = useState(false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final detailFuture = useMemoized(() async {
      final client = ref.read(apiClientProvider);
      return client.getPostDetail(id);
    }, [reloadKey.value]);
    final snapshot = useFuture(detailFuture, preserveState: false);

    final post = snapshot.data;
    final postTitle = post?.title;
    final postContent = post?.content;
    final postUserId = post?.userId;
    final postUserName = post?.userName;
    final postUserAvatar = post?.userAvatar;

    Future<void> deletePost() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('删除帖子'),
          content: Text('确定要删除帖子 $id 吗？此操作不可撤销。'),
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

      isDeleting.value = true;
      try {
        final client = ref.read(apiClientProvider);
        await client.deletePost(id);
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('帖子已删除')));
        if (context.mounted) {
          context.pop();
        }
      } on Exception catch (e) {
        showErrorSnackBar(scaffoldMessenger, e, prefix: '删除失败: ');
      } finally {
        isDeleting.value = false;
      }
    }

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final infoLabelTextTheme = textTheme.labelLarge!.copyWith(
      color: Colors.grey,
    );

    return Scaffold(
      appBar: AppBar(title: Text(postTitle ?? '帖子')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: AnimatedLoadSwitch(
            hasData: snapshot.hasData,
            dataBuilder: (_) => post == null
                ? const Center(child: Text('未找到帖子'))
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.only(top: 16),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: .start,
                              children: [
                                if (postTitle != null) ...[
                                  Text(
                                    postTitle,
                                    style: textTheme.headlineSmall,
                                    maxLines: 3,
                                    overflow: .ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                const Divider(),
                                _infoRow(
                                  label: 'ID:',
                                  labelStyle: infoLabelTextTheme,
                                  value: Text(id, style: textTheme.bodyMedium),
                                  copyValue: id,
                                ),
                                if (postUserId != null || postUserName != null)
                                  _infoRow(
                                    label: '作者:',
                                    labelStyle: infoLabelTextTheme,
                                    value: InkWell(
                                      onTap: postUserId == null
                                          ? null
                                          : () {
                                              context.push(
                                                '/management/user/${Uri.encodeComponent(postUserId)}',
                                                extra:
                                                    ManagementUserDetailPageExtra(
                                                      name: postUserName,
                                                      avatarUrl: postUserAvatar,
                                                    ),
                                              );
                                            },
                                      child: Text(
                                        postUserName != null &&
                                                postUserId != null
                                            ? postUserName
                                            : postUserName ?? postUserId ?? '',
                                        style: textTheme.bodyMedium!.copyWith(
                                          color: postUserId != null
                                              ? colorScheme.primary
                                              : null,
                                          decoration: postUserId != null
                                              ? TextDecoration.underline
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                for (final (label, value) in _postInfoRows(
                                  post,
                                ))
                                  if (value.isNotEmpty)
                                    _infoRow(
                                      label: '$label:',
                                      labelStyle: infoLabelTextTheme,
                                      value: Text(
                                        value,
                                        style: textTheme.bodyMedium,
                                      ),
                                      copyValue:
                                          (label == '数据' || label == '状态')
                                          ? null
                                          : value,
                                    ),
                                const Divider(),
                                if (postContent != null) ...[
                                  Text(postContent, style: textTheme.bodyLarge),
                                ],
                                const Divider(),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          sliver: SliverToBoxAdapter(
                            child: FilledButton.icon(
                              onPressed: isDeleting.value ? null : deletePost,
                              icon: isDeleting.value
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.delete_outline),
                              label: const Text('删除帖子'),
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: Divider()),
                        CommentList(postId: id),
                      ],
                    ),
                  ),
            nonDataBuilder: (_) => snapshot.hasError
                ? LoadErrorView(
                    error: snapshot.error!,
                    onRetry: () => reloadKey.value = UniqueKey(),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }

  List<(String, String)> _postInfoRows(PostDetail post) {
    final category = post.category;
    final likes = post.likes;
    final views = post.views;
    final createdAt = post.createdAt;
    final updatedAt = post.updatedAt;

    final statusLabel = post.status == null
        ? null
        : post.status == 1
        ? '正常'
        : '已删除';

    final rows = <(String, String)>[
      if (category != null) ('分类', category),
      if (statusLabel != null) ('状态', statusLabel),
      if (likes != null || views != null)
        (
          '数据',
          [
            if (likes != null) '点赞: $likes',
            if (views != null) '浏览: $views',
          ].join('  '),
        ),
      if (createdAt != null) ('创建时间', formatDateTime(createdAt)),
      if (updatedAt != null) ('更新时间', formatDateTime(updatedAt)),
    ];
    return rows;
  }

  Widget _infoRow({
    required String label,
    required TextStyle labelStyle,
    required Widget value,
    String? copyValue,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(width: 8),
          Expanded(
            child: copyValue == null
                ? value
                : CopyableWidget(
                    value: copyValue,
                    copyOnLongPress: true,
                    withInk: true,
                    child: value,
                  ),
          ),
        ],
      ),
    );
  }
}
