import 'package:fairy_forum_admin_app/config.dart';
import 'package:fairy_forum_admin_app/providers/identity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isValidIdentity = ref.watch(isValidIdentityProvider);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 600),
        child: ListView(
          children: [
            InkWell(
              onTap: () {
                context.push('/settings/theme');
              },
              child: ListTile(
                leading: const Icon(Icons.palette),
                title: const Text('外观'),
              ),
            ),
            if (isValidIdentity) ...[
              const Divider(height: 16),
              InkWell(
                onTap: () {
                  context.push('/settings/local-admins');
                },
                child: ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('本地管理员'),
                  subtitle: const Text('本地系统登录账号'),
                ),
              ),
              const Divider(height: 16),
              InkWell(
                onTap: () {
                  context.push('/settings/byok');
                },
                child: ListTile(
                  leading: const Icon(Icons.key),
                  title: const Text('BYOK 设置'),
                  subtitle: const Text('配置当前账号的上游凭据'),
                ),
              ),
              InkWell(
                onTap: () async {
                  await ref
                      .read(identityStorageProvider.notifier)
                      .clearIdentity();
                },
                child: ListTile(
                  leading: const Icon(Icons.exit_to_app),
                  title: const Text('退出登录'),
                ),
              ),
            ],
            const Divider(height: 16),
            InkWell(
              onTap: () {
                context.push('/settings/about');
              },
              child: ListTile(
                leading: const Icon(Icons.info),
                title: const Text('关于'),
                subtitle: Text(title),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
