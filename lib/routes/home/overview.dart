import 'package:fairy_forum_admin_app/components/error_ui.dart';
import 'package:fairy_forum_admin_app/providers/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class OverviewPage extends HookConsumerWidget {
  const OverviewPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refreshKey = useState(UniqueKey());
    final future = useMemoized(() async {
      final client = ref.read(apiClientProvider);
      final res = await client.getStats();
      return res;
    }, [refreshKey.value]);
    final snapshot = useFuture(future, preserveState: false);

    return Center(
      child: AnimatedLoadSwitch(
        hasData: snapshot.hasData,
        dataBuilder: (_) => ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 800),

          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                GridView.extent(
                  shrinkWrap: true,
                  maxCrossAxisExtent: 240.0,
                  mainAxisSpacing: 8.0,
                  crossAxisSpacing: 8.0,
                  childAspectRatio: 1.5,
                  children: [
                    StatusCard(
                      name: '待处理举报数',
                      value: snapshot.data!.pendingReportCount,
                    ),
                    StatusCard(
                      name: '封禁用户数',
                      value: snapshot.data!.userBannedCount,
                    ),
                    StatusCard(name: '用户数', value: snapshot.data!.userCount),
                    StatusCard(name: '帖子数', value: snapshot.data!.postCount),
                    StatusCard(name: '评论数', value: snapshot.data!.commentCount),
                    StatusCard(
                      name: '回收站帖子数',
                      value: snapshot.data!.deletedPostCount,
                    ),
                    StatusCard(
                      name: '回收站评论数',
                      value: snapshot.data!.deletedCommentCount,
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Align(
                      alignment: .bottomCenter,
                      child: FutureBuilder(
                        future: () async {
                          final client = ref.read(apiClientProvider);

                          return await client.dailySentence();
                        }(),
                        builder: (context, asyncSnapshot) =>
                            asyncSnapshot.data == null
                            ? SizedBox()
                            : Text(
                                asyncSnapshot.data!,
                                style: Theme.of(context).textTheme.labelLarge!
                                    .copyWith(color: Colors.grey),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        nonDataBuilder: (_) => snapshot.hasError
            ? LoadErrorView(
                error: snapshot.error!,
                onRetry: () => refreshKey.value = UniqueKey(),
                context: 'overview',
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}

class StatusCard extends StatelessWidget {
  final String name;
  final int value;

  const StatusCard({super.key, required this.name, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card.filled(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Text(name, style: textTheme.labelMedium, softWrap: false),
            Expanded(
              child: Align(
                alignment: .bottomStart,
                child: Text('$value', style: textTheme.headlineSmall),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
