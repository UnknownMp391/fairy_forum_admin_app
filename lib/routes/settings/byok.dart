import 'package:fairy_forum_admin_app/components/error_ui.dart';
import 'package:fairy_forum_admin_app/providers/api_client.dart';
import 'package:fairy_forum_admin_app/providers/identity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 上游密钥 ups_token 仅可设置、不可回显（后端不返回）。
class ByokSettingsPage extends HookConsumerWidget {
  const ByokSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refreshKey = useState(UniqueKey());
    final isSaving = useState(false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final textTheme = Theme.of(context).textTheme;

    final identity = ref.watch(identityStorageProvider).value;
    final myId = identity?.adminId;

    final future = useMemoized(() async {
      final client = ref.read(apiClientProvider);
      if (myId == null || myId.isEmpty) {
        throw Exception('未登录，无法读取 BYOK 配置');
      }
      return client.getLocalAdmin(myId);
    }, [myId, refreshKey.value]);
    final snapshot = useFuture(future, preserveState: false);

    final upsIdController = useTextEditingController(
      text: snapshot.data?.upsId ?? '',
    );
    final upsTokenController = useTextEditingController();

    Future<void> save({required bool clear}) async {
      if (myId == null || myId.isEmpty) return;
      isSaving.value = true;
      try {
        final client = ref.read(apiClientProvider);
        await client.updateLocalAdmin(
          myId,
          upsId: clear ? '' : upsIdController.text.trim(),
          upsToken: clear ? '' : upsTokenController.text,
        );
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(clear ? '已清除 BYOK（回退默认上游凭据）' : 'BYOK 已保存')),
        );
        upsTokenController.clear();
        refreshKey.value = UniqueKey();
      } on Exception catch (e) {
        showErrorSnackBar(scaffoldMessenger, e, prefix: '保存失败: ');
      } finally {
        isSaving.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('BYOK 设置'),
        actions: [
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: () => refreshKey.value = UniqueKey(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: AnimatedLoadSwitch(
            hasData: snapshot.hasData,
            dataBuilder: (_) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card.filled(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        Text(
                          '当前账号: ${snapshot.data!.adminId}',
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.data!.upsId == null ||
                                  snapshot.data!.upsId!.isEmpty
                              ? '未配置 BYOK —— 调用上游时使用后端默认凭据'
                              : '已配置 BYOK —— 上游 ID: ${snapshot.data!.upsId}',
                          style: textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '配置后，你的所有上游调用将使用自有凭据（BYOK），'
                          '不再使用默认凭据。',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: upsIdController,
                  decoration: const InputDecoration(
                    labelText: '远程管理员 ID（ups_id）',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: upsTokenController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '上游密钥（ups_token，仅可设置不可回显）',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '更换：填入新的 ID + 密钥后保存；'
                  '清除：清空两个输入框后点「清除」。',
                  style: textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: isSaving.value
                          ? null
                          : () => save(clear: true),
                      icon: const Icon(Icons.link_off),
                      label: const Text('清除'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: isSaving.value
                          ? null
                          : () => save(clear: false),
                      icon: isSaving.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: const Text('保存'),
                    ),
                  ],
                ),
              ],
            ),
            nonDataBuilder: (_) => snapshot.hasError
                ? LoadErrorView(
                    error: snapshot.error!,
                    onRetry: () => refreshKey.value = UniqueKey(),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }
}
