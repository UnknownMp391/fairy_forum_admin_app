import 'package:dio/dio.dart';
import 'package:fairy_forum_admin_app/api/types/feedback.dart';
import 'package:fairy_forum_admin_app/components/copyable.dart';
import 'package:fairy_forum_admin_app/components/error_ui.dart';
import 'package:fairy_forum_admin_app/providers/api_client.dart';
import 'package:fairy_forum_admin_app/utils/datetime.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ManagementFeedbackDetailPage extends HookConsumerWidget {
  final String id;

  const ManagementFeedbackDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reloadKey = useState(UniqueKey());
    final isWorking = useState(false);
    final isUploading = useState(false);
    final isDownloading = useState(false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final future = useMemoized(() async {
      final client = ref.read(apiClientProvider);
      return client.getFeedbackDetail(id);
    }, [reloadKey.value]);
    final snapshot = useFuture(future, preserveState: false);

    final item = snapshot.data;

    final textTheme = Theme.of(context).textTheme;
    final greyStyle = textTheme.labelMedium!.copyWith(color: Colors.grey);
    final labelStyle = textTheme.labelLarge!.copyWith(color: Colors.grey);

    Future<void> changeStatus() async {
      if (item == null) return;
      final result = await showDialog<(String, String?)>(
        context: context,
        builder: (ctx) => _StatusChangeDialog(current: item.status),
      );
      if (result == null) return;
      isWorking.value = true;
      try {
        final client = ref.read(apiClientProvider);
        await client.updateFeedbackStatus(id, result.$1, note: result.$2);
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('状态已更新')));
        reloadKey.value = UniqueKey();
      } on Exception catch (e) {
        showErrorSnackBar(scaffoldMessenger, e, prefix: '更新失败: ');
      } finally {
        isWorking.value = false;
      }
    }

    Future<void> downloadAttachment(String attachmentId) async {
      final location = await getSaveLocation(
        suggestedName: attachmentId,
        acceptedTypeGroups: const [
          XTypeGroup(label: '附件', extensions: ['*']),
        ],
      );
      if (location == null) return;
      isDownloading.value = true;
      try {
        final client = ref.read(apiClientProvider);
        await client.downloadFeedbackAttachment(
          id,
          attachmentId,
          location.path,
        );
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('附件已保存到 ${location.path}')),
        );
      } on Exception catch (e) {
        showErrorSnackBar(scaffoldMessenger, e, prefix: '下载失败: ');
      } finally {
        isDownloading.value = false;
      }
    }

    Future<void> uploadAttachment() async {
      final file = await openFile();
      if (file == null) return;
      if ((await file.length()) > 10 * 1024 * 1024) {
        showErrorSnackBar(scaffoldMessenger, '文件不能超过 10MB', prefix: '');
        return;
      }
      isUploading.value = true;
      try {
        final bytes = await file.readAsBytes();
        final client = ref.read(apiClientProvider);
        await client.uploadFeedbackAttachment(
          id,
          MultipartFile.fromBytes(bytes, filename: file.name),
        );
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('附件已上传')));
        reloadKey.value = UniqueKey();
      } on Exception catch (e) {
        showErrorSnackBar(scaffoldMessenger, e, prefix: '上传失败: ');
      } finally {
        isUploading.value = false;
      }
    }

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

    return Scaffold(
      appBar: AppBar(
        title: Text(item?.title ?? '反馈 $id'),
        actions: [
          IconButton(
            tooltip: '上传附件',
            icon: const Icon(Icons.attach_file),
            onPressed: isWorking.value || isUploading.value
                ? null
                : uploadAttachment,
          ),
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
                ? const Center(child: Text('未找到反馈'))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (item.content != null) ...[
                        Text(item.content!, style: textTheme.bodyLarge),
                        const Divider(),
                      ],
                      infoRow('ID', id),
                      infoRow('类型', item.type ?? '', copyable: false),
                      infoRow(
                        '状态',
                        feedbackStatusLabel(item.status),
                        copyable: false,
                      ),
                      infoRow('报告人', item.reporterId ?? ''),
                      infoRow('处理人', item.handlerId ?? ''),
                      if (item.createdAt != null)
                        infoRow('创建时间', formatDateTime(item.createdAt!)),
                      if (item.updatedAt != null)
                        infoRow('更新时间', formatDateTime(item.updatedAt!)),
                      if (item.attachmentIds != null &&
                          item.attachmentIds!.isNotEmpty) ...[
                        const Divider(),
                        Text(
                          '附件（${item.attachmentIds!.length}）',
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        for (final attachmentId in item.attachmentIds!)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(
                              attachmentId,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: greyStyle,
                            ),
                            trailing: IconButton(
                              tooltip: '下载附件',
                              icon: const Icon(Icons.download),
                              onPressed: isDownloading.value
                                  ? null
                                  : () => downloadAttachment(attachmentId),
                            ),
                          ),
                      ],
                      const Divider(),
                      FilledButton.icon(
                        onPressed: isWorking.value ? null : changeStatus,
                        icon: const Icon(Icons.update),
                        label: const Text('变更状态'),
                      ),
                      const Divider(),
                      Text('状态历史', style: textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (item.statusHistory == null ||
                          item.statusHistory!.isEmpty)
                        const Text('暂无历史记录')
                      else
                        for (final change in item.statusHistory!)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              crossAxisAlignment: .start,
                              children: [
                                Text(
                                  '${feedbackStatusLabel(change.fromStatus)} → '
                                  '${feedbackStatusLabel(change.toStatus)}'
                                  '${change.handlerId != null ? ' (${change.handlerId})' : ''}',
                                  style: textTheme.bodyMedium,
                                ),
                                if (change.note != null &&
                                    change.note!.isNotEmpty)
                                  Text(change.note!, style: greyStyle),
                                if (change.createdAt != null)
                                  Text(
                                    formatDateTime(change.createdAt!),
                                    style: greyStyle,
                                  ),
                              ],
                            ),
                          ),
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

class _StatusChangeDialog extends StatefulWidget {
  final String? current;

  const _StatusChangeDialog({this.current});

  @override
  State<_StatusChangeDialog> createState() => _StatusChangeDialogState();
}

class _StatusChangeDialogState extends State<_StatusChangeDialog> {
  final _noteController = TextEditingController();
  late String _status =
      widget.current ??
      (feedbackStatuses.isNotEmpty ? feedbackStatuses.first : 'pending');

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('变更状态'),
      content: Column(
        mainAxisSize: .min,
        children: [
          DropdownMenu<String>(
            initialSelection: _status,
            expandedInsets: EdgeInsets.zero,
            label: const Text('新状态'),
            dropdownMenuEntries: [
              for (final status in feedbackStatuses)
                DropdownMenuEntry(
                  value: status,
                  label: feedbackStatusLabel(status),
                ),
            ],
            onSelected: (value) {
              if (value != null) _status = value;
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: '备注（可选）',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, (
            _status,
            _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          )),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
