import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ManagementPage extends HookConsumerWidget {
  const ManagementPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 600),
        child: ListView(
          children: [
            InkWell(
              onTap: () {
                context.push('/management/userList');
              },
              child: ListTile(
                leading: const Icon(Icons.person),
                trailing: const Icon(Icons.arrow_forward),
                title: const Text("用户"),
              ),
            ),
            const Divider(height: 16),
            InkWell(
              onTap: () {},
              child: ListTile(
                leading: const Icon(Icons.dashboard),
                trailing: const Icon(Icons.arrow_forward),
                title: const Text("帖子"),
              ),
            ),
            const Divider(height: 16),
            InkWell(
              onTap: () {},
              child: ListTile(
                leading: const Icon(Icons.comment),
                trailing: const Icon(Icons.arrow_forward),
                title: const Text("评论"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
