import 'package:fairy_forum_admin_app/api/types/admins.dart';
import 'package:fairy_forum_admin_app/components/error_ui.dart';
import 'package:fairy_forum_admin_app/providers/api_client.dart';
import 'package:fairy_forum_admin_app/providers/identity.dart';
import 'package:fairy_forum_admin_app/utils/datetime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ManagementAdminsPage extends HookConsumerWidget {
  const ManagementAdminsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refreshKey = useState(UniqueKey());
    final isWorking = useState(false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final identity = ref.watch(identityStorageProvider).value;
    final isSuper = identity?.role == 'superadmin';

    final adminsFuture = useMemoized(() async {
      final client = ref.read(apiClientProvider);
      return client.listRemoteAdmins();
    }, [refreshKey.value]);
    final snapshot = useFuture(adminsFuture, preserveState: false);

    final textTheme = Theme.of(context).textTheme;
    final greyStyle = textTheme.labelMedium!.copyWith(color: Colors.grey);

    Future<void> refresh() async {
      refreshKey.value = UniqueKey();
    }

    Future<void> createAdmin() async {
      final result =
          await showDialog<({String adminId, String key, String? role})>(
            context: context,
            builder: (ctx) => const _CreateAdminDialog(),
          );
      if (result == null) return;
      isWorking.value = true;
      try {
        final client = ref.read(apiClientProvider);
        await client.createRemoteAdmin(
          adminId: result.adminId,
          key: result.key,
          role: result.role,
        );
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('管理员已创建')));
        await refresh();
      } on Exception catch (e) {
        showErrorSnackBar(scaffoldMessenger, e, prefix: '创建失败: ');
      } finally {
        isWorking.value = false;
      }
    }

    Future<void> changeRole(AdminInfo admin) async {
      final role = await showDialog<String>(
        context: context,
        builder: (ctx) => _RoleSelectDialog(current: admin.role),
      );
      if (role == null || role == admin.role) return;
      isWorking.value = true;
      try {
        final client = ref.read(apiClientProvider);
        await client.updateRemoteAdminRole(admin.adminId, role);
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('角色已更新')));
        await refresh();
      } on Exception catch (e) {
        showErrorSnackBar(scaffoldMessenger, e, prefix: '更新失败: ');
      } finally {
        isWorking.value = false;
      }
    }

    Future<void> resetKey(AdminInfo admin) async {
      final key = await showDialog<String>(
        context: context,
        builder: (ctx) =>
            const _KeyInputDialog(title: '重置密钥', hintText: '输入新密钥'),
      );
      if (key == null || key.isEmpty) return;
      isWorking.value = true;
      try {
        final client = ref.read(apiClientProvider);
        await client.resetRemoteAdminKey(admin.adminId, key);
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('密钥已重置')));
      } on Exception catch (e) {
        showErrorSnackBar(scaffoldMessenger, e, prefix: '重置失败: ');
      } finally {
        isWorking.value = false;
      }
    }

    Future<void> deleteAdmin(AdminInfo admin) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('删除管理员'),
          content: Text('确定删除管理员「${admin.adminId}」吗？将同时吊销其全部 Token。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('删除'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      isWorking.value = true;
      try {
        final client = ref.read(apiClientProvider);
        await client.deleteRemoteAdmin(admin.adminId);
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('管理员已删除')));
        await refresh();
      } on Exception catch (e) {
        showErrorSnackBar(scaffoldMessenger, e, prefix: '删除失败: ');
      } finally {
        isWorking.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('管理员'),
        actions: [
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: isWorking.value ? null : refresh,
          ),
        ],
      ),
      floatingActionButton: isSuper
          ? FloatingActionButton(
              tooltip: '新建管理员',
              onPressed: isWorking.value ? null : createAdmin,
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: AnimatedLoadSwitch(
                hasData: snapshot.hasData,
                dataBuilder: (_) => ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: snapshot.data!.isEmpty
                      ? const Text('暂无管理员')
                      : ListView.separated(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (ctx, i) {
                            final admin = snapshot.data![i];
                            return ListTile(
                              title: Text(admin.adminId),
                              subtitle: Column(
                                crossAxisAlignment: .start,
                                children: [
                                  Text(
                                    '角色: ${adminRoleLabel(admin.role)}',
                                    style: greyStyle,
                                  ),
                                  if (admin.createdAt != null)
                                    Text(
                                      '创建: ${formatDateTime(admin.createdAt!)}',
                                      style: greyStyle,
                                    ),
                                  if (admin.lastLoginTime != null)
                                    Text(
                                      '最后登录: ${formatDateTime(admin.lastLoginTime!)}',
                                      style: greyStyle,
                                    ),
                                ],
                              ),
                              trailing: isSuper
                                  ? PopupMenuButton<String>(
                                      onSelected: (action) {
                                        switch (action) {
                                          case 'role':
                                            changeRole(admin);
                                          case 'key':
                                            resetKey(admin);
                                          case 'delete':
                                            deleteAdmin(admin);
                                        }
                                      },
                                      itemBuilder: (ctx) => const [
                                        PopupMenuItem(
                                          value: 'role',
                                          child: Text('修改角色'),
                                        ),
                                        PopupMenuItem(
                                          value: 'key',
                                          child: Text('重置密钥'),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text('删除'),
                                        ),
                                      ],
                                    )
                                  : null,
                            );
                          },
                          separatorBuilder: (_, _) => const Divider(),
                        ),
                ),
                nonDataBuilder: (_) => snapshot.hasError
                    ? LoadErrorView(
                        error: snapshot.error!,
                        onRetry: () => refreshKey.value = UniqueKey(),
                      )
                    : const CircularProgressIndicator(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateAdminDialog extends StatefulWidget {
  const _CreateAdminDialog();

  @override
  State<_CreateAdminDialog> createState() => _CreateAdminDialogState();
}

class _CreateAdminDialogState extends State<_CreateAdminDialog> {
  final _adminIdController = TextEditingController();
  final _keyController = TextEditingController();
  String? _role = 'admin';

  @override
  void dispose() {
    _adminIdController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新建管理员'),
      content: Column(
        mainAxisSize: .min,
        children: [
          TextField(
            controller: _adminIdController,
            decoration: const InputDecoration(
              labelText: 'Admin ID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _keyController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '密钥',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownMenu<String>(
            initialSelection: _role,
            expandedInsets: EdgeInsets.zero,
            label: const Text('角色'),
            dropdownMenuEntries: const [
              DropdownMenuEntry(value: 'admin', label: '管理员'),
              DropdownMenuEntry(value: 'superadmin', label: '超级管理员'),
            ],
            onSelected: (value) {
              if (value != null) _role = value;
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final adminId = _adminIdController.text.trim();
            final key = _keyController.text;
            if (adminId.isEmpty || key.isEmpty) return;
            Navigator.pop(context, (adminId: adminId, key: key, role: _role));
          },
          child: const Text('创建'),
        ),
      ],
    );
  }
}

class _RoleSelectDialog extends StatefulWidget {
  final String? current;

  const _RoleSelectDialog({this.current});

  @override
  State<_RoleSelectDialog> createState() => _RoleSelectDialogState();
}

class _RoleSelectDialogState extends State<_RoleSelectDialog> {
  late String? _role = widget.current;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('修改角色'),
      content: DropdownMenu<String>(
        initialSelection: _role,
        expandedInsets: EdgeInsets.zero,
        dropdownMenuEntries: const [
          DropdownMenuEntry(value: 'admin', label: '管理员'),
          DropdownMenuEntry(value: 'superadmin', label: '超级管理员'),
        ],
        onSelected: (value) {
          if (value != null) _role = value;
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _role),
          child: const Text('确定'),
        ),
      ],
    );
  }
}

class _KeyInputDialog extends StatefulWidget {
  final String title;
  final String hintText;

  const _KeyInputDialog({required this.title, required this.hintText});

  @override
  State<_KeyInputDialog> createState() => _KeyInputDialogState();
}

class _KeyInputDialogState extends State<_KeyInputDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        obscureText: true,
        autofocus: true,
        decoration: InputDecoration(
          hintText: widget.hintText,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
