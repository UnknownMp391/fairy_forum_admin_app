import 'package:fairy_forum_admin_app/api/types/bug_reports.dart';
import 'package:fairy_forum_admin_app/components/error_ui.dart';
import 'package:fairy_forum_admin_app/components/paged_list.dart';
import 'package:fairy_forum_admin_app/providers/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ManagementBugReportsPage extends HookConsumerWidget {
  const ManagementBugReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusFilter = useState<int?>(null);
    final searchController = useTextEditingController();
    final query = useState<String?>(null);
    final refreshKey = useState(UniqueKey());
    final isWorking = useState(false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final q = query.value?.trim();
    final isSearching = q != null && q.isNotEmpty;

    Future<PagedResult<BugReport>> fetchPage(int page) async {
      final client = ref.read(apiClientProvider);
      final list = await client.listBugReports(
        status: statusFilter.value,
        search: isSearching ? q : null,
        page: page,
        size: 20,
      );
      return PagedResult(items: list, hasMore: list.length == 20);
    }

    final textTheme = Theme.of(context).textTheme;
    final greyStyle = textTheme.labelMedium!.copyWith(color: Colors.grey);

    Future<void> createBugReport() async {
      final result =
          await showDialog<
            ({String title, String detail, String steps, String contact})
          >(context: context, builder: (ctx) => const _CreateBugReportDialog());
      if (result == null) return;
      isWorking.value = true;
      try {
        final client = ref.read(apiClientProvider);
        await client.createBugReport(
          title: result.title,
          detail: result.detail,
          steps: result.steps,
          contact: result.contact,
        );
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('论坛问题已提交')),
        );
        refreshKey.value = UniqueKey();
      } on Exception catch (e) {
        showErrorSnackBar(scaffoldMessenger, e, prefix: '提交失败: ');
      } finally {
        isWorking.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('论坛问题'),
        actions: [
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: () => refreshKey.value = UniqueKey(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '新建论坛问题',
        onPressed: isWorking.value ? null : createBugReport,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    SegmentedButton<int?>(
                      segments: const [
                        ButtonSegment(value: null, label: Text('全部')),
                        ButtonSegment(value: 0, label: Text('待处理')),
                        ButtonSegment(value: 1, label: Text('已处理')),
                      ],
                      selected: {statusFilter.value},
                      onSelectionChanged: (s) {
                        statusFilter.value = s.first;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: '搜索：标题 / 内容 / 联系方式',
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
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: PagedListView<BugReport>(
              fetchPage: fetchPage,
              resetKey: Object.hash(statusFilter.value, q, refreshKey.value),
              emptyText: isSearching ? '未找到匹配的论坛问题' : '暂无论坛问题',
              itemBuilder: (context, item) => InkWell(
                onTap: () {
                  context.push('/management/bug-reports/${item.id}');
                },
                child: ListTile(
                  title: Text(
                    item.title ?? '无标题',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Text('ID: ${item.id}', style: greyStyle),
                      Text(item.reporterName ?? '', style: greyStyle),
                    ],
                  ),
                  trailing: Chip(
                    label: Text(
                      bugReportStatusLabel(item.status),
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

class _CreateBugReportDialog extends StatefulWidget {
  const _CreateBugReportDialog();

  @override
  State<_CreateBugReportDialog> createState() => _CreateBugReportDialogState();
}

class _CreateBugReportDialogState extends State<_CreateBugReportDialog> {
  final _titleController = TextEditingController();
  final _detailController = TextEditingController();
  final _stepsController = TextEditingController();
  final _contactController = TextEditingController();
  String? _error;

  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    _stepsController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    final detail = _detailController.text.trim();
    final steps = _stepsController.text.trim();
    final contact = _contactController.text.trim();
    if (title.isEmpty || detail.isEmpty || steps.isEmpty || contact.isEmpty) {
      setState(() => _error = '标题、详情、复现步骤、联系方式均必填');
      return;
    }
    if (!_emailRe.hasMatch(contact)) {
      setState(() => _error = '联系方式须为有效邮箱');
      return;
    }
    Navigator.pop(context, (
      title: title,
      detail: detail,
      steps: steps,
      contact: contact,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      title: const Text('新建论坛问题'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '标题',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detailController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '问题详情',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _stepsController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '复现步骤',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contactController,
              decoration: const InputDecoration(
                labelText: '联系方式（邮箱）',
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
        FilledButton(onPressed: _submit, child: const Text('提交')),
      ],
    );
  }
}
