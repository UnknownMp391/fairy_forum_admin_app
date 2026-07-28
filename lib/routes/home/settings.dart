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
