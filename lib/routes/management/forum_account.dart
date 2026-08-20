import 'package:fairy_forum_admin_app/api/client.dart';
import 'package:fairy_forum_admin_app/components/error_ui.dart';
import 'package:fairy_forum_admin_app/providers/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ManagementForumAccountPage extends HookConsumerWidget {
  const ManagementForumAccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refreshKey = useState(UniqueKey());
    final isWorking = useState(false);
    final nameController = useTextEditingController();
    final passwordController = useTextEditingController();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final future = useMemoized(() async {
      final client = ref.read(apiClientProvider);
      return client.getForumAccountStatus();
    }, [refreshKey.value]);
    final snapshot = useFuture(future, preserveState: false);

    final textTheme = Theme.of(context).textTheme;

    final status = snapshot.data;
    final bound = status?.bound == true;

    Future<void> bind() async {
      final name = nameController.text.trim();
      final password = passwordController.text;
      if (name.isEmpty || password.isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('请输入论坛用户名和密码')),
        );
        return;
      }
      isWorking.value = true;
      try {
        final client = ref.read(apiClientProvider);
        await client.bindForumAccount(name: name, password: password);
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('绑定成功')));
        refreshKey.value = UniqueKey();
      } on Exception catch (e) {
        showErrorSnackBar(scaffoldMessenger, e, prefix: '绑定失败: ');
      } finally {
        isWorking.value = false;
      }
    }

    Future<void> unbind() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('解绑论坛账号'),
          content: const Text('确定解绑当前论坛账号吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('解绑'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      isWorking.value = true;
      try {
        final client = ref.read(apiClientProvider);
        await client.unbindForumAccount();
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('已解绑')));
        refreshKey.value = UniqueKey();
      } on Exception catch (e) {
        showErrorSnackBar(scaffoldMessenger, e, prefix: '解绑失败: ');
      } finally {
        isWorking.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('论坛账号'),
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
                          bound ? '已绑定论坛账号' : '未绑定论坛账号',
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (bound) ...[
                          if (status!.forumUserName != null)
                            Text('用户名: ${status.forumUserName}'),
                          if (status.forumUserId != null)
                            Text('论坛用户 ID: ${status.forumUserId}'),
                          if (status.forumUserAvatar != null &&
                              status.forumUserAvatar!.isNotEmpty)
                            Text('头像: ${status.forumUserAvatar}'),
                        ] else
                          Text('绑定后可在论坛以该账号身份执行评论 / 举报等操作。'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (!bound) ...[
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: '论坛用户名或邮箱',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '论坛密码',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: isWorking.value ? null : bind,
                    icon: const Icon(Icons.link),
                    label: const Text('绑定'),
                  ),
                ] else
                  OutlinedButton.icon(
                    onPressed: isWorking.value ? null : unbind,
                    icon: const Icon(Icons.link_off),
                    label: const Text('解绑'),
                  ),
              ],
            ),
            nonDataBuilder: (_) => snapshot.hasError
                ? _isNoByok(snapshot.error!)
                      ? _ByokGuideView(
                          onConfigured: () => refreshKey.value = UniqueKey(),
                        )
                      : LoadErrorView(
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

bool _isNoByok(Object error) =>
    error is ApiException && error.errorCode == 'no_byok';

class _ByokGuideView extends StatelessWidget {
  final VoidCallback onConfigured;

  const _ByokGuideView({required this.onConfigured});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.key_off_outlined, size: 40),
            const SizedBox(height: 12),
            Text(
              '论坛账号功能需要先配置 BYOK',
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '论坛账号查询/绑定/解绑仅 BYOK 管理员可用。'
              '请先在设置中配置你自己的上游凭据（ups_id + ups_token）。',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                await context.push('/settings/byok');
                onConfigured();
              },
              icon: const Icon(Icons.key),
              label: const Text('去配置 BYOK'),
            ),
          ],
        ),
      ),
    );
  }
}
