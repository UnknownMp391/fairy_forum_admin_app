import 'package:fairy_forum_admin_app/api/types/comments.dart';
import 'package:fairy_forum_admin_app/components/copyable.dart';
import 'package:fairy_forum_admin_app/components/error_ui.dart';
import 'package:fairy_forum_admin_app/providers/api_client.dart';
import 'package:fairy_forum_admin_app/utils/datetime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ManagementCommentRepliesPage extends HookConsumerWidget {
  final String postId;
  final String commentId;

  const ManagementCommentRepliesPage({
    super.key,
    required this.postId,
    required this.commentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reloadKey = useState(UniqueKey());
    final future = useMemoized(() async {
      final client = ref.read(apiClientProvider);
      final results = await Future.wait<Object>([
        client.getPostComment(postId, commentId),
        client.getPostComments(postId),
      ]);
      return (
        target: results[0] as Comment,
        comments: results[1] as List<Comment>,
      );
    }, [postId, commentId, reloadKey.value]);
    final snapshot = useFuture(future, preserveState: false);

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final greyStyle = textTheme.labelMedium!.copyWith(color: Colors.grey);
    final infoLabelTextTheme = textTheme.labelLarge!.copyWith(
      color: Colors.grey,
    );

    final target = snapshot.data?.target;
    final comments = snapshot.data?.comments ?? const <Comment>[];
    final replies = comments.where((c) => c.parentId == commentId).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          target?.content ?? '评论',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: AnimatedLoadSwitch(
            hasData: snapshot.hasData,
            dataBuilder: (_) => target == null
                ? const Center(child: Text('评论不存在或已被删除'))
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
                                _infoRow(
                                  label: 'ID:',
                                  labelStyle: infoLabelTextTheme,
                                  value: Text(
                                    commentId,
                                    style: textTheme.bodyMedium,
                                  ),
                                  copyValue: commentId,
                                ),
                                if (target.userName != null ||
                                    target.userId != null)
                                  _infoRow(
                                    label: '作者:',
                                    labelStyle: infoLabelTextTheme,
                                    value: InkWell(
                                      onTap: target.userId == null
                                          ? null
                                          : () {
                                              context.push(
                                                '/management/user/${Uri.encodeComponent(target.userId!)}',
                                              );
                                            },
                                      child: Text(
                                        target.userName != null &&
                                                target.userId != null
                                            ? '${target.userName} (ID: ${target.userId})'
                                            : target.userName ??
                                                  target.userId ??
                                                  '',
                                        style: textTheme.bodyMedium!.copyWith(
                                          color: target.userId != null
                                              ? colorScheme.primary
                                              : null,
                                          decoration: target.userId != null
                                              ? TextDecoration.underline
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (target.postTitle != null ||
                                    target.postId != null)
                                  _infoRow(
                                    label: '所属帖子:',
                                    labelStyle: infoLabelTextTheme,
                                    value: Text(
                                      target.postTitle != null &&
                                              target.postId != null
                                          ? '${target.postTitle} (ID: ${target.postId})'
                                          : target.postTitle ??
                                                target.postId ??
                                                '',
                                      style: textTheme.bodyMedium,
                                    ),
                                    copyValue:
                                        target.postTitle ?? target.postId ?? '',
                                  ),
                                if (target.likes != null)
                                  _infoRow(
                                    label: '数据:',
                                    labelStyle: infoLabelTextTheme,
                                    value: Text(
                                      '点赞: ${target.likes}',
                                      style: textTheme.bodyMedium,
                                    ),
                                  ),
                                if (target.status != null)
                                  _infoRow(
                                    label: '状态:',
                                    labelStyle: infoLabelTextTheme,
                                    value: Text(
                                      target.status == 1 ? '正常' : '已删除',
                                      style: textTheme.bodyMedium!.copyWith(
                                        color: target.status == 1
                                            ? null
                                            : colorScheme.error,
                                      ),
                                    ),
                                  ),
                                if (target.createdAt != null)
                                  _infoRow(
                                    label: '创建时间:',
                                    labelStyle: infoLabelTextTheme,
                                    value: Text(
                                      formatDateTime(target.createdAt!),
                                      style: textTheme.bodyMedium,
                                    ),
                                    copyValue: formatDateTime(
                                      target.createdAt!,
                                    ),
                                  ),
                                const Divider(),
                                if (target.content != null) ...[
                                  Text(
                                    target.content!,
                                    style: textTheme.bodyLarge,
                                  ),
                                  const Divider(),
                                ],
                                OutlinedButton.icon(
                                  onPressed: () {
                                    context.push(
                                      '/management/post/${Uri.encodeComponent(postId)}',
                                    );
                                  },
                                  icon: const Icon(Icons.article_outlined),
                                  label: const Text('查看所属帖子'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: Divider()),
                        SliverToBoxAdapter(
                          child: Text(
                            '子评论 (${replies.length})',
                            style: textTheme.titleMedium,
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 8)),
                        if (replies.isEmpty)
                          const SliverToBoxAdapter(child: Text('暂无子评论'))
                        else
                          SliverList.builder(
                            itemCount: replies.length,
                            itemBuilder: (context, index) {
                              final reply = replies[index];
                              return InkWell(
                                onTap: reply.id == null
                                    ? null
                                    : () {
                                        context.push(
                                          '/management/comment/${Uri.encodeComponent(reply.id!)}/replies?postId=${Uri.encodeComponent(postId)}',
                                        );
                                      },
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    reply.content ?? '（无内容）',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: .start,
                                    children: [
                                      if (reply.userName != null)
                                        Text(
                                          '作者: ${reply.userName}',
                                          style: greyStyle,
                                        ),
                                      if (reply.createdAt != null)
                                        Text(
                                          formatDateTime(reply.createdAt!),
                                          style: greyStyle,
                                        ),
                                    ],
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                  ),
                                ),
                              );
                            },
                          ),
                        const SliverToBoxAdapter(child: SizedBox(height: 16)),
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
