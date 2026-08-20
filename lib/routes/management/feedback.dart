import 'package:fairy_forum_admin_app/api/types/feedback.dart';
import 'package:fairy_forum_admin_app/components/error_ui.dart';
import 'package:fairy_forum_admin_app/components/paged_list.dart';
import 'package:fairy_forum_admin_app/providers/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ManagementFeedbackPage extends HookConsumerWidget {
  const ManagementFeedbackPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusFilter = useState<String?>(null);
    final refreshKey = useState(UniqueKey());
    final isWorking = useState(false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    Future<PagedResult<FeedbackItem>> fetchPage(int page) async {
      final client = ref.read(apiClientProvider);
      final list = await client.listFeedback(
        status: statusFilter.value,
        page: page,
        size: 20,
      );
      return PagedResult(items: list, hasMore: list.length == 20);
    }

    final textTheme = Theme.of(context).textTheme;
    final greyStyle = textTheme.labelMedium!.copyWith(color: Colors.grey);

    Future<void> createFeedback() async {
      final result =
          await showDialog<({String type, String title, String content})>(
            context: context,
            builder: (ctx) => const _CreateFeedbackDialog(),
          );
      if (result == null) return;
      isWorking.value = true;
      try {
        final client = ref.read(apiClientProvider);
        await client.createFeedback(
          type: result.type,
          title: result.title,
          content: result.content,
        );
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('反馈已提交')));
        refreshKey.value = UniqueKey();
      } on Exception catch (e) {
        showErrorSnackBar(scaffoldMessenger, e, prefix: '提交失败: ');
      } finally {
        isWorking.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('反馈'),
        actions: [
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: () => refreshKey.value = UniqueKey(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '新建反馈',
        onPressed: isWorking.value ? null : createFeedback,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: DropdownMenu<String?>(
              width: 220,
              label: const Text('状态筛选'),
              initialSelection: statusFilter.value,
              dropdownMenuEntries: [
                const DropdownMenuEntry(value: null, label: '全部'),
                for (final status in feedbackStatuses)
                  DropdownMenuEntry(
                    value: status,
                    label: feedbackStatusLabel(status),
                  ),
              ],
              onSelected: (value) => statusFilter.value = value,
            ),
          ),
          Expanded(
            child: PagedListView<FeedbackItem>(
              fetchPage: fetchPage,
              resetKey: Object.hash(statusFilter.value, refreshKey.value),
              emptyText: '暂无反馈',
              itemBuilder: (context, item) => InkWell(
                onTap: () {
                  context.push(
                    '/management/feedback/${Uri.encodeComponent(item.id)}',
                  );
                },
                child: ListTile(
                  title: Text(
                    item.title ?? '（无标题）',
                    maxLines: 1,
                    overflow: .ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: .start,
                    children: [
                      if (item.type != null)
                        Text('#${item.type}', style: greyStyle),
                      if (item.reporterId != null)
                        Text('${item.reporterId}', style: greyStyle),
                    ],
                  ),
                  trailing: Chip(
                    label: Text(
                      feedbackStatusLabel(item.status),
                      style: textTheme.labelSmall,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateFeedbackDialog extends StatefulWidget {
  const _CreateFeedbackDialog();

  @override
  State<_CreateFeedbackDialog> createState() => _CreateFeedbackDialogState();
}

class _CreateFeedbackDialogState extends State<_CreateFeedbackDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _type = feedbackTypes.isNotEmpty ? feedbackTypes.first : 'bug';
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      setState(() => _error = '标题和内容不能为空');
      return;
    }
    Navigator.pop(context, (
      type: _type ?? 'bug',
      title: title,
      content: content,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      title: const Text('新建反馈'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: .min,
          children: [
            DropdownMenu<String>(
              initialSelection: _type,
              expandedInsets: EdgeInsets.zero,
              label: const Text('类型'),
              dropdownMenuEntries: [
                for (final type in feedbackTypes)
                  DropdownMenuEntry(value: type, label: type),
              ],
              onSelected: (value) {
                if (value != null) _type = value;
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '标题',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '内容',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
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
        FilledButton(onPressed: _submit, child: const Text('提交')),
      ],
    );
  }
}
