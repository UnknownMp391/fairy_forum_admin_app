import 'package:fairy_forum_admin_app/api/types/admins.dart';
import 'package:fairy_forum_admin_app/config.dart';
import 'package:fairy_forum_admin_app/providers/identity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(identityStorageProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('关于')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.forum),
                title: Text(title),
                subtitle: const Text('妖精论坛管理后台'),
              ),
              if (identity != null) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('当前账号'),
                  subtitle: Text(
                    '${identity.adminId} · ${adminRoleLabel(identity.role)}',
                  ),
                ),
              ],
              const Divider(),
              ListTile(
                leading: const Icon(Icons.api),
                title: const Text('API 地址'),
                subtitle: Text(ApiEndpoints.apiBaseUrl),
              ),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('版本'),
                subtitle: Text('v1.0.0'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
