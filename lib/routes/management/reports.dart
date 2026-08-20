import 'package:fairy_forum_admin_app/api/types/reports.dart';
import 'package:fairy_forum_admin_app/components/error_ui.dart';
import 'package:fairy_forum_admin_app/components/paged_list.dart';
import 'package:fairy_forum_admin_app/components/selection.dart';
import 'package:fairy_forum_admin_app/providers/api_client.dart';
import 'package:fairy_forum_admin_app/utils/datetime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ManagementReportsPage extends HookConsumerWidget {
  const ManagementReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = useSelectionState();
    final statusFilter = useState<bool?>(null);
    final refreshKey = useState(UniqueKey());
    final isResolving = useState<String?>(null);
    final isBatchWorking = useState(false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final loadedReports = useState<List<Report>>(const []);

    Future<PagedResult<Report>> fetchPage(int page) async {
      final client = ref.read(apiClientProvider);
      final list = await client.listReports(
        isResolved: statusFilter.value,
        page: page,
        size: 20,
      );
      return PagedResult(items: list, hasMore: list.length == 20);
    }

    Future<void> batchResolve() async {
      final ids = selection.selectedIds.toList();
      if (ids.isEmpty) return;
      isBatchWorking.value = true;
      try {
        final client = ref.read(apiClientProvider);
        final result = await client.batchResolveReports(ids);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              result.failedCount == 0
                  ? '已处理 ${result.successCount} 条举报'
                  : '已处理 ${result.successCount} 条，失败 ${result.failedCount} 条',
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
        title: const Text('举报'),
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
            padding: const EdgeInsets.all(8),
            child: SegmentedButton<bool?>(
              segments: const [
                ButtonSegment(value: null, label: Text('全部')),
                ButtonSegment(value: false, label: Text('待处理')),
                ButtonSegment(value: true, label: Text('已处理')),
              ],
              selected: {statusFilter.value},
              onSelectionChanged: (selection) {
                statusFilter.value = selection.first;
              },
            ),
          ),
          Expanded(
            child: PagedListView<Report>(
              fetchPage: fetchPage,
              resetKey: Object.hash(statusFilter.value, refreshKey.value),
              emptyText: '暂无举报',
              onItemsChanged: (list) => loadedReports.value = list,
              itemBuilder: (context, report) => _ReportTile(
                report: report,
                isResolving: isResolving.value == report.id,
                selecting: selection.selecting,
                selected: selection.selectedIds.contains(report.id),
                onToggle: () => selection.toggle(report.id),
                onResolve: () async {
                  isResolving.value = report.id;
                  try {
                    final client = ref.read(apiClientProvider);
                    await client.resolveReport(report.id);
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('举报已处理')),
                    );
                    refreshKey.value = UniqueKey();
                  } on Exception catch (e) {
                    showErrorSnackBar(scaffoldMessenger, e, prefix: '处理失败: ');
                  } finally {
                    isResolving.value = null;
                  }
                },
                onDeletePost: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('举报联动删帖'),
                      content: Text(
                        '将删除帖子'
                        '「${report.postTitle ?? report.postId ?? ''}」'
                        '及其全部评论（移入回收站），并将该举报标记为已处理。确认？',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('取消'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('删除帖子'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                  isResolving.value = report.id;
                  try {
                    final client = ref.read(apiClientProvider);
                    await client.deletePostByReport(report.id);
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('已联动删除帖子并处理举报')),
                    );
                    refreshKey.value = UniqueKey();
                  } on Exception catch (e) {
                    showErrorSnackBar(scaffoldMessenger, e, prefix: '操作失败: ');
                  } finally {
                    isResolving.value = null;
                  }
                },
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
                        final all = loadedReports.value
                            .map((r) => r.id)
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
                          : () => batchResolve(),
                      child: const Text('批量处理'),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class _ReportTile extends StatelessWidget {
  final Report report;
  final bool isResolving;
  final bool selecting;
  final bool selected;
  final VoidCallback? onToggle;
  final Future<void> Function() onResolve;
  final Future<void> Function() onDeletePost;

  const _ReportTile({
    required this.report,
    required this.isResolving,
    required this.selecting,
    required this.selected,
    required this.onToggle,
    required this.onResolve,
    required this.onDeletePost,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final greyStyle = textTheme.labelMedium!.copyWith(color: Colors.grey);

    final resolved = report.isResolved;
    final postTitle = report.postTitle;
    final postId = report.postId;

    return ListTile(
      title: Text(
        report.reason ?? '举报 #${report.id}',
        maxLines: 2,
        overflow: .ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: .start,
        children: [
          /*if (report.detail != null && report.detail!.isNotEmpty)
            Text(
              report.detail!,
              maxLines: 2,
              overflow: .ellipsis,
              style: greyStyle,
            ),*/
          Text('ID:${report.id}', style: greyStyle),
          if (report.reporterName != null)
            Text('${report.reporterName}', style: greyStyle),
          if (postId != null || postTitle != null)
            postId == null
                ? Text('from ${postTitle ?? '[帖子已删除]'}', style: greyStyle)
                : InkWell(
                    onTap: () {
                      context.push(
                        '/management/post/${Uri.encodeComponent(postId)}',
                      );
                    },
                    child: Text(
                      postTitle ?? '[帖子已删除]',
                      style: greyStyle.copyWith(
                        color: colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
          if (report.createdAt != null)
            Text(formatDateTime(report.createdAt!), style: greyStyle),
        ],
      ),
      trailing: selecting
          ? Checkbox(value: selected, onChanged: (_) => onToggle?.call())
          : resolved
          ? Text(
              '已处理',
              style: textTheme.labelLarge!.copyWith(color: colorScheme.primary),
            )
          : Row(
              mainAxisSize: .min,
              children: [
                IconButton(
                  tooltip: '举报联动删帖',
                  onPressed: isResolving ? null : onDeletePost,
                  icon: const Icon(Icons.delete_outline),
                ),
                IconButton(
                  tooltip: '标记为已处理',
                  onPressed: isResolving ? null : onResolve,
                  icon: isResolving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.check_circle_outline),
                ),
              ],
            ),
    );
  }
}
