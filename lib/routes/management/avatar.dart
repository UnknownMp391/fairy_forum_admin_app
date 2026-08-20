import 'package:fairy_forum_admin_app/api/types/users.dart';
import 'package:fairy_forum_admin_app/components/error_ui.dart';
import 'package:fairy_forum_admin_app/components/selection.dart';
import 'package:fairy_forum_admin_app/providers/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ManagementAvatarPage extends HookConsumerWidget {
  const ManagementAvatarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = useSelectionState();
    final domainController = useTextEditingController();
    final poolController = useTextEditingController();
    final restoreController = useTextEditingController();
    final domain = useState<String?>(null);
    final refreshKey = useState(UniqueKey());
    final isWorking = useState(false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final greyStyle = textTheme.labelMedium!.copyWith(color: Colors.grey);

    final scanFuture = useMemoized(() async {
      final d = domain.value?.trim();
      if (d == null || d.isEmpty) {
        return const AvatarScanResult(total: 0, items: []);
      }
      final client = ref.read(apiClientProvider);
      return client.scanUserAvatars(d);
    }, [domain.value, refreshKey.value]);
    final scanSnapshot = useFuture(scanFuture, preserveState: false);

    final scannedUsers = scanSnapshot.data?.items ?? const <AvatarScanUser>[];

    Future<bool> askConfirm() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('高危操作确认'),
          content: const Text('此操作不可撤销，确定继续吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('确认执行'),
            ),
          ],
        ),
      );
      return ok ?? false;
    }

    Future<void> replaceAvatars() async {
      final d = domain.value?.trim();
      final pool = poolController.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (d == null || d.isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('请先输入域名并扫描')),
        );
        return;
      }
      if (pool.isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('请填写替换头像池（每行一个 URL）')),
        );
        return;
      }
      if (!await askConfirm()) return;
      isWorking.value = true;
      try {
        final client = ref.read(apiClientProvider);
        final replaced = await client.replaceUserAvatars(
          domain: d,
          avatars: pool,
        );
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('已替换 $replaced 个头像')),
        );
        refreshKey.value = UniqueKey();
      } on Exception catch (e) {
        showErrorSnackBar(scaffoldMessenger, e, prefix: '操作失败: ');
      } finally {
        isWorking.value = false;
      }
    }

    Future<void> restoreAvatars() async {
      final users = scannedUsers
          .where((u) => selection.selectedIds.contains(u.id))
          .toList();
      if (users.isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('请先勾选要恢复的用户')),
        );
        return;
      }
      final urls = restoreController.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (urls.length != users.length) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              '恢复头像数量（${urls.length}）必须与所选用户数（${users.length}）一致，每行一个',
            ),
          ),
        );
        return;
      }
      if (!await askConfirm()) return;
      isWorking.value = true;
      try {
        final client = ref.read(apiClientProvider);
        final items = [
          for (var i = 0; i < users.length; i++)
            AvatarRestoreItem(
              id: users[i].id,
              name: users[i].name ?? '',
              avatar: urls[i],
            ),
        ];
        final result = await client.restoreUserAvatars(items: items);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('已恢复 ${result.restored}，跳过 ${result.skipped}'),
          ),
        );
        refreshKey.value = UniqueKey();
      } on Exception catch (e) {
        showErrorSnackBar(scaffoldMessenger, e, prefix: '操作失败: ');
      } finally {
        isWorking.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('头像管理')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('按域名扫描', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: domainController,
                      decoration: const InputDecoration(
                        labelText: '域名',
                        hintText: '例如 old-cdn.com',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (v) {
                        domain.value = v;
                        selection.replace({});
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      domain.value = domainController.text;
                      selection.replace({});
                    },
                    child: const Text('扫描'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (scanSnapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (domain.value != null && scanSnapshot.hasError)
                SectionErrorView(
                  error: scanSnapshot.error!,
                  onRetry: () => refreshKey.value = UniqueKey(),
                  context: 'avatar-scan',
                ),
              if (domain.value != null &&
                  scanSnapshot.hasData &&
                  scannedUsers.isEmpty)
                const Text('未匹配到该域名的用户'),
              for (final user in scannedUsers)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(user.name ?? user.id),
                  subtitle: Text(
                    '${user.id}\n${user.avatar ?? ''}',
                    style: greyStyle,
                  ),
                  value: selection.selectedIds.contains(user.id),
                  onChanged: (_) => selection.toggle(user.id),
                ),
              if (scannedUsers.isNotEmpty)
                Text(
                  '共 ${scannedUsers.length} 个，已选 ${selection.selectedIds.length}',
                  style: greyStyle,
                ),
              const Divider(height: 32),
              Text(
                '替换头像（高危）',
                style: textTheme.titleMedium!.copyWith(
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text('从下方头像池中为匹配该域名的用户随机替换。', style: textTheme.bodySmall),
              const SizedBox(height: 8),
              TextField(
                controller: poolController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: '替换头像池（每行一个 URL）',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: isWorking.value ? null : replaceAvatars,
                icon: const Icon(Icons.swap_horiz),
                label: const Text('替换全部匹配用户'),
              ),
              const Divider(height: 32),
              Text('恢复头像（高危）', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                '勾选上方用户，并按勾选顺序填写恢复头像（每行一个）。'
                '用户名须与数据库一致，不匹配会跳过。',
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: restoreController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: '恢复头像（每行一个 URL，与所选用户一一对应）',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: isWorking.value ? null : restoreAvatars,
                icon: const Icon(Icons.settings_backup_restore),
                label: Text('恢复所选 ${selection.selectedIds.length} 个用户'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
