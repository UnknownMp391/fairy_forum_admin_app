import 'package:fairy_forum_admin_app/api/types/bug_reports.dart';
import 'package:fairy_forum_admin_app/components/copyable.dart';
import 'package:fairy_forum_admin_app/components/error_ui.dart';
import 'package:fairy_forum_admin_app/providers/api_client.dart';
import 'package:fairy_forum_admin_app/utils/datetime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ManagementBugReportDetailPage extends HookConsumerWidget {
  final int id;

  const ManagementBugReportDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reloadKey = useState(UniqueKey());
    final isWorking = useState(false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final future = useMemoized(() async {
      final client = ref.read(apiClientProvider);
      return client.getBugReportDetail(id);
    }, [reloadKey.value]);
    final snapshot = useFuture(future, preserveState: false);

    final item = snapshot.data;

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final labelStyle = textTheme.labelLarge!.copyWith(color: Colors.grey);

    Widget infoRow(String label, String value, {bool copyable = true}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: .start,
          children: [
            Text('$label:', style: labelStyle),
            const SizedBox(width: 8),
            Expanded(
              child: copyable
                  ? CopyableWidget(
                      value: value,
                      copyOnLongPress: true,
                      withInk: true,
                      child: Text(value, style: textTheme.bodyMedium),
                    )
                  : Text(value, style: textTheme.bodyMedium),
            ),
          ],
        ),
      );
    }

    Future<void> changeStatus() async {
      if (item == null) return;
      final target = item.status == 1 ? 0 : 1;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(target == 1 ? '标记为已处理' : '恢复待处理'),
          content: Text(
            target == 1
                ? '确定将「${item.title ?? '#$id'}」标记为已处理吗？（会写入状态日志并发送邮件通知）'
                : '确定将「${item.title ?? '#$id'}」恢复为待处理吗？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('确定'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      isWorking.value = true;
      try {
        final client = ref.read(apiClientProvider);
        await client.updateBugReportStatus(id, target);
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(target == 1 ? '已标记为已处理' : '已恢复为待处理')),
        );
        reloadKey.value = UniqueKey();
      } on Exception catch (e) {
        showErrorSnackBar(scaffoldMessenger, e, prefix: '更新失败: ');
      } finally {
        isWorking.value = false;
      }
    }

    Future<void> deleteBugReport() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('删除论坛问题'),
          content: Text('确定删除「${item?.title ?? '#$id'}」吗？'),
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
      isWorking.value = true;
      try {
        final client = ref.read(apiClientProvider);
        await client.deleteBugReport(id);
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('已删除')));
        if (context.mounted) {
          context.pop();
        }
      } on Exception catch (e) {
        showErrorSnackBar(scaffoldMessenger, e, prefix: '删除失败: ');
      } finally {
        isWorking.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          item?.title ?? '论坛问题 #$id',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: () => reloadKey.value = UniqueKey(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: AnimatedLoadSwitch(
            hasData: snapshot.hasData,
            dataBuilder: (_) => item == null
                ? const Center(child: Text('未找到论坛问题'))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (item.detail != null && item.detail!.isNotEmpty) ...[
                        Text(item.detail!, style: textTheme.bodyLarge),
                        const Divider(),
                      ],
                      infoRow('ID', '$id'),
                      infoRow(
                        '状态',
                        bugReportStatusLabel(item.status),
                        copyable: false,
                      ),
                      if (item.reporterName != null || item.reporterId != null)
                        infoRow(
                          '报告人',
                          item.reporterName != null && item.reporterId != null
                              ? '${item.reporterName} (${item.reporterId})'
                              : item.reporterName ?? item.reporterId ?? '',
                        ),
                      if (item.contact != null && item.contact!.isNotEmpty)
                        infoRow('联系方式', item.contact!),
                      if (item.pageUrl != null && item.pageUrl!.isNotEmpty)
                        infoRow('页面', item.pageUrl!),
                      if (item.userAgent != null && item.userAgent!.isNotEmpty)
                        infoRow('用户代理', item.userAgent!),
                      if (item.createdAt != null)
                        infoRow('创建时间', formatDateTime(item.createdAt!)),
                      const Divider(),
                      Text('复现步骤', style: textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        (item.steps == null || item.steps!.isEmpty)
                            ? '（未填写）'
                            : item.steps!,
                        style: textTheme.bodyMedium,
                      ),
                      const Divider(),
                      Row(
                        children: [
                          FilledButton.icon(
                            onPressed: isWorking.value ? null : changeStatus,
                            icon: const Icon(Icons.update),
                            label: Text(item.status == 1 ? '恢复待处理' : '标记已处理'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: isWorking.value ? null : deleteBugReport,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.error,
                            ),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('删除'),
                          ),
                        ],
                      ),
                      const Divider(),
                      Text('状态历史', style: textTheme.titleMedium),
                      const SizedBox(height: 8),
                      _BugReportChangelogSection(feedbackId: id),
                    ],
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
}

class _BugReportChangelogSection extends HookConsumerWidget {
  final int feedbackId;

  const _BugReportChangelogSection({required this.feedbackId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refreshKey = useState(0);
    final future = useMemoized(() async {
      final client = ref.read(apiClientProvider);
      return client.listBugReportChangelog(
        feedbackId: feedbackId,
        page: 1,
        size: 20,
      );
    }, [feedbackId, refreshKey.value]);
    final snapshot = useFuture(future, preserveState: false);

    final textTheme = Theme.of(context).textTheme;
    final greyStyle = textTheme.labelMedium!.copyWith(color: Colors.grey);

    if (snapshot.connectionState == ConnectionState.waiting) {
      return const SizedBox.shrink();
    }
    if (snapshot.hasError) {
      return SectionErrorView(
        error: snapshot.error!,
        onRetry: () => refreshKey.value++,
        context: 'bug-report-changelog',
      );
    }
    final entries = snapshot.data ?? const <BugReportChangelogEntry>[];
    if (entries.isEmpty) {
      return Text('暂无历史记录', style: greyStyle);
    }
    return Column(
      crossAxisAlignment: .start,
      children: [
        for (final change in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  '${bugReportStatusLabel(change.fromStatus)} → '
                  '${bugReportStatusLabel(change.toStatus)}'
                  '${change.handlerId != null ? ' (${change.handlerId})' : ''}',
                  style: textTheme.bodyMedium,
                ),
                if (change.note != null && change.note!.isNotEmpty)
                  Text(change.note!, style: greyStyle),
                if (change.createdAt != null)
                  Text(formatDateTime(change.createdAt!), style: greyStyle),
              ],
            ),
          ),
      ],
    );
  }
}
