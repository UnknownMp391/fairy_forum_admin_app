import 'package:fairy_forum_admin_app/api/types/comments.dart';
import 'package:fairy_forum_admin_app/components/error_ui.dart';
import 'package:fairy_forum_admin_app/providers/api_client.dart';
import 'package:fairy_forum_admin_app/utils/datetime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CommentList extends HookConsumerWidget {
  final String postId;

  final bool showHeader;

  const CommentList({super.key, required this.postId, this.showHeader = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refreshKey = useState(UniqueKey());
    final isDeleting = useState<String?>(null);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final commentsFuture = useMemoized(() async {
      final client = ref.read(apiClientProvider);
      return client.getPostComments(postId);
    }, [postId, refreshKey.value]);
    final snapshot = useFuture(commentsFuture, preserveState: false);

    final textTheme = Theme.of(context).textTheme;
    final comments = snapshot.data ?? const <Comment>[];

    return SliverPadding(
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      sliver: SliverMainAxisGroup(
        slivers: [
          if (showHeader) ...[
            SliverToBoxAdapter(
              child: Row(
                children: [
                  Text('评论', style: textTheme.titleMedium),
                  const SizedBox(width: 8),
                  Text(
                    snapshot.hasData ? '(${comments.length})' : '',
                    style: textTheme.labelMedium,
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
          ],
          snapshot.hasData
              ? comments.isEmpty
                    ? const SliverPadding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        sliver: SliverToBoxAdapter(child: Text('暂无评论')),
                      )
                    : SliverList.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return _CommentTile(
                            comment: comment,
                            isDeleting: isDeleting.value == comment.id,
                            onDelete: () async {
                              final id = comment.id;
                              if (id == null) return;
                              isDeleting.value = id;
                              try {
                                final client = ref.read(apiClientProvider);
                                await client.deleteComment(id);
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(content: Text('评论已删除')),
                                );
                                refreshKey.value = UniqueKey();
                              } on Exception catch (e) {
                                showErrorSnackBar(
                                  scaffoldMessenger,
                                  e,
                                  prefix: '删除失败: ',
                                );
                              } finally {
                                isDeleting.value = null;
                              }
                            },
                            onTap: comment.id == null
                                ? null
                                : () {
                                    context.push(
                                      '/management/comment/${Uri.encodeComponent(comment.id!)}/replies?postId=${Uri.encodeComponent(postId)}',
                                    );
                                  },
                          );
                        },
                      )
              : snapshot.hasError
              ? SliverToBoxAdapter(
                  child: LoadErrorView(
                    error: snapshot.error!,
                    onRetry: () => refreshKey.value = UniqueKey(),
                  ),
                )
              : const SliverPadding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  sliver: SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  final bool isDeleting;
  final Future<void> Function() onDelete;
  final VoidCallback? onTap;

  const _CommentTile({
    required this.comment,
    required this.isDeleting,
    required this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final greyStyle = textTheme.labelMedium!.copyWith(color: Colors.grey);

    final deleted = comment.status != null && comment.status != 1;
    final id = comment.id;
    final userName = comment.userName;
    final createdAt = comment.createdAt;

    return InkWell(
      onTap: onTap,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          comment.content ?? '（无内容）',
          maxLines: 3,
          overflow: .ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: .start,
          children: [
            if (userName != null) Text('作者: $userName', style: greyStyle),
            if (id != null) Text('ID: $id', style: greyStyle),
            if (createdAt != null)
              Text('时间: ${formatDateTime(createdAt)}', style: greyStyle),
            if (deleted)
              Text(
                '状态: 已删除',
                style: textTheme.labelSmall!.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
          ],
        ),
        trailing: id == null
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
