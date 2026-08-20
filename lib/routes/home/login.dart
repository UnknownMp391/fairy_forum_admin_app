import 'package:fairy_forum_admin_app/api/client.dart' as api;
import 'package:fairy_forum_admin_app/components/error_ui.dart';
import 'package:fairy_forum_admin_app/dto/auth/identity.dart';
import 'package:fairy_forum_admin_app/providers/api_client.dart';
import 'package:fairy_forum_admin_app/providers/identity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LoginPage extends HookConsumerWidget {
  const LoginPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final adminIdInputController = useTextEditingController();
    final passwordInputController = useTextEditingController();

    final isLogining = useState(false);

    Future<void> submit() async {
      if (isLogining.value) return;
      final adminId = adminIdInputController.text.trim();
      final password = passwordInputController.text;
      if (adminId.isEmpty || password.isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('请输入 Admin ID 和密码')),
        );
        return;
      }

      isLogining.value = true;
      try {
        final dio = ref.read(dioProvider);
        final result = await api.login(dio, adminId, password);
        await ref.read(identityStorageProvider.notifier).setIdentity(
              IdentityData(
                adminId: adminId,
                adminToken: result.token,
                role: result.role,
              ),
            );
      } on Exception catch (e) {
        showErrorSnackBar(scaffoldMessenger, e, prefix: '登录失败: ');
      } finally {
        isLogining.value = false;
      }
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: .center,
            children: [
              TextField(
                controller: adminIdInputController,
                decoration: const InputDecoration(
                  labelText: 'Admin ID',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordInputController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '密码',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.password),
                ),
                onSubmitted: (_) => submit(),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.icon(
                    onPressed: isLogining.value ? null : submit,
                    icon: isLogining.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : null,
                    label: const Text("登录"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
