import 'package:fairy_forum_admin_app/api/types/admins.dart';
import 'package:fairy_forum_admin_app/components/error_ui.dart';
import 'package:fairy_forum_admin_app/providers/api_client.dart';
import 'package:fairy_forum_admin_app/providers/identity.dart';
import 'package:fairy_forum_admin_app/utils/datetime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ManagementLocalAdminsPage extends HookConsumerWidget {
  const ManagementLocalAdminsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refreshKey = useState(UniqueKey());
    final isWorking = useState(false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final identity = ref.watch(identityStorageProvider).value;
    final isSuper = identity?.role == 'superadmin';
    final myId = identity?.adminId;

    final adminsFuture = useMemoized(() async {
      final client = ref.read(apiClientProvider);
      return client.listLocalAdmins();
    }, [refreshKey.value]);
    final snapshot = useFuture(adminsFuture, preserveState: false);

    final textTheme = Theme.of(context).textTheme;
    final greyStyle = textTheme.labelMedium!.copyWith(color: Colors.grey);

    Future<void> refresh() async {
      refreshKey.value = UniqueKey();
    }

    Future<void> createAdmin() async {
      final result =
          await showDialog<({String adminId, String password, String? role})>(
            context: context,
            builder: (ctx) => const _CreateLocalAdminDialog(),
          );
      if (result == null) return;
      isWorking.value = true;
      try {
        final client = ref.read(apiClientProvider);
        await client.createLocalAdmin(
          adminId: result.adminId,
          password: result.password,
          role: result.role,
        );
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('本地管理员已创建')),
        );
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
        await client.updateLocalAdmin(admin.adminId, role: role);
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('角色已更新')));
        await refresh();
      } on Exception catch (e) {
        showErrorSnackBar(scaffoldMessenger, e, prefix: '更新失败: ');
      } finally {
        isWorking.value = false;
      }
    }

    Future<void> resetPassword(AdminInfo admin) async {
      final password = await showDialog<String>(
        context: context,
        builder: (ctx) => const _PasswordInputDialog(),
      );
      if (password == null || password.isEmpty) return;
      isWorking.value = true;
      try {
        final client = ref.read(apiClientProvider);
        await client.updateLocalAdmin(admin.adminId, password: password);
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('密码已重置')));
      } on Exception catch (e) {
        showErrorSnackBar(scaffoldMessenger, e, prefix: '重置失败: ');
      } finally {
        isWorking.value = false;
      }
    }

    Future<void> configureByok(AdminInfo admin) async {
      final result = await showDialog<({String upsId, String upsToken})>(
        context: context,
        builder: (ctx) => _ByokDialog(currentUpsId: admin.upsId),
      );
      if (result == null) return;
      isWorking.value = true;
      try {
        final client = ref.read(apiClientProvider);
        await client.updateLocalAdmin(
          admin.adminId,
          upsId: result.upsId,
          upsToken: result.upsToken,
        );
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              result.upsId.isEmpty ? '已清除 BYOK' : '已保存 BYOK（${result.upsId}）',
            ),
          ),
        );
        await refresh();
      } on Exception catch (e) {
        showErrorSnackBar(scaffoldMessenger, e, prefix: 'BYOK 保存失败: ');
      } finally {
        isWorking.value = false;
      }
    }

    Future<void> deleteAdmin(AdminInfo admin) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('删除本地管理员'),
          content: Text(
            '确定删除本地登录账号「${admin.adminId}」吗？'
            '删除后该账号将无法登录本地系统。',
          ),
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
        await client.deleteLocalAdmin(admin.adminId);
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('本地管理员已删除')),
        );
        await refresh();
      } on Exception catch (e) {
        showErrorSnackBar(scaffoldMessenger, e, prefix: '删除失败: ');
      } finally {
        isWorking.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('本地管理员'),
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
              tooltip: '新建本地管理员',
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
                      ? const Text('暂无本地管理员')
                      : ListView.separated(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (ctx, i) {
                            final admin = snapshot.data![i];
                            final isSelf = admin.adminId == myId;
                            return ListTile(
                              title: Text(
                                '${admin.adminId}'
                                '${isSelf ? '（当前账号）' : ''}',
                              ),
                              subtitle: Column(
                                crossAxisAlignment: .start,
                                children: [
                                  Text(
                                    adminRoleLabel(admin.role),
                                    style: greyStyle,
                                  ),
                                  if (admin.upsId != null &&
                                      admin.upsId!.isNotEmpty)
                                    Text(
                                      'BYOK: ${admin.upsId}',
                                      style: greyStyle,
                                    ),
                                  if (admin.createdAt != null)
                                    Text(
                                      '创建于 ${formatDateTime(admin.createdAt!)}',
                                      style: greyStyle,
                                    ),
                                  if (admin.lastLoginTime != null)
                                    Text(
                                      '登录于 ${formatDateTime(admin.lastLoginTime!)}',
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
                                          case 'password':
                                            resetPassword(admin);
                                          case 'byok':
                                            configureByok(admin);
                                          case 'delete':
                                            if (!isSelf) deleteAdmin(admin);
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(
                                          value: 'role',
                                          child: Text('修改角色'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'password',
                                          child: Text('重置密码'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'byok',
                                          child: Text('BYOK 设置'),
                                        ),
                                        if (!isSelf)
                                          const PopupMenuItem(
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
                    : const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateLocalAdminDialog extends StatefulWidget {
  const _CreateLocalAdminDialog();

  @override
  State<_CreateLocalAdminDialog> createState() =>
      _CreateLocalAdminDialogState();
}

class _CreateLocalAdminDialogState extends State<_CreateLocalAdminDialog> {
  final _adminIdController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _role = 'admin';

  @override
  void dispose() {
    _adminIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新建本地管理员'),
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
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '密码',
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
            final password = _passwordController.text;
            if (adminId.isEmpty || password.isEmpty) return;
            Navigator.pop(context, (
              adminId: adminId,
              password: password,
              role: _role,
            ));
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

class _PasswordInputDialog extends StatefulWidget {
  const _PasswordInputDialog();

  @override
  State<_PasswordInputDialog> createState() => _PasswordInputDialogState();
}

class _PasswordInputDialogState extends State<_PasswordInputDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('重置密码'),
      content: TextField(
        controller: _controller,
        obscureText: true,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: '新密码',
          border: OutlineInputBorder(),
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

class _ByokDialog extends StatefulWidget {
  final String? currentUpsId;

  const _ByokDialog({this.currentUpsId});

  @override
  State<_ByokDialog> createState() => _ByokDialogState();
}

class _ByokDialogState extends State<_ByokDialog> {
  late final _upsIdController = TextEditingController(
    text: widget.currentUpsId ?? '',
  );
  final _upsTokenController = TextEditingController();

  @override
  void dispose() {
    _upsIdController.dispose();
    _upsTokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      title: const Text('BYOK 设置'),
      content: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          Text(
            widget.currentUpsId == null || widget.currentUpsId!.isEmpty
                ? '当前未配置 BYOK（将使用后端默认上游凭据）'
                : '当前 BYOK 上游 ID: ${widget.currentUpsId}',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _upsIdController,
            decoration: const InputDecoration(
              labelText: '远程管理员 ID（ups_id）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _upsTokenController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '上游密钥（ups_token，仅可设置不可回显）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '两个字段都清空并保存 = 清除 BYOK；只填 ID 也会清除（需 ID+密钥齐全才生效）。',
            style: textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, (upsId: '', upsToken: '')),
          child: const Text('清除'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, (
            upsId: _upsIdController.text.trim(),
            upsToken: _upsTokenController.text,
          )),
          child: const Text('保存'),
        ),
      ],
    );
  }
}
