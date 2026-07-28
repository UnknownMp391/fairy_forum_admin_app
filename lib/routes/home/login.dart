import 'package:fairy_forum_admin_app/dto/auth/identity.dart';
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
    final adminTokenInputController = useTextEditingController();

    final isLogining = useState(false);

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
                decoration: InputDecoration(
                  labelText: 'Admin ID',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: adminTokenInputController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Admin Token',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.password),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.icon(
                    onPressed: () async {
                      if (isLogining.value) return;
                      isLogining.value = true;
                      try {
                        ref
                            .read(identityStorageProvider.notifier)
                            .setIdentity(
                              IdentityData(
                                adminId: adminIdInputController.text,
                                adminToken: adminTokenInputController.text,
                              ),
                            );
                      } on Exception catch (e) {
                        isLogining.value = false;

                        scaffoldMessenger.showSnackBar(
                          SnackBar(content: Text('登录失败: $e')),
                        );
                      }
                    },
                    icon: isLogining.value
                        ? SizedBox(
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
