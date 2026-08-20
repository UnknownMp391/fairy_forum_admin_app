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
            InkWell(
              onTap: () {
                context.push('/management/post');
              },
              child: ListTile(
                leading: const Icon(Icons.article_outlined),
                trailing: const Icon(Icons.arrow_forward),
                title: const Text("帖子"),
              ),
            ),
            InkWell(
              onTap: () {
                context.push('/management/comments');
              },
              child: ListTile(
                leading: const Icon(Icons.comment),
                trailing: const Icon(Icons.arrow_forward),
                title: const Text("评论"),
              ),
            ),
            const Divider(height: 16),
            InkWell(
              onTap: () {
                context.push('/management/reports');
              },
              child: ListTile(
                leading: const Icon(Icons.report),
                trailing: const Icon(Icons.arrow_forward),
                title: const Text("举报"),
              ),
            ),
            InkWell(
              onTap: () {
                context.push('/management/bug-reports');
              },
              child: ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                trailing: const Icon(Icons.arrow_forward),
                title: const Text("论坛反馈"),
              ),
            ),
            const Divider(height: 16),
            InkWell(
              onTap: () {
                context.push('/management/trash');
              },
              child: ListTile(
                leading: const Icon(Icons.delete_outline),
                trailing: const Icon(Icons.arrow_forward),
                title: const Text("回收站"),
              ),
            ),
            const Divider(height: 16),
            InkWell(
              onTap: () {
                context.push('/management/admins');
              },
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                trailing: const Icon(Icons.arrow_forward),
                title: const Text("管理员"),
                subtitle: const Text('远程管理员'),
              ),
            ),
            InkWell(
              onTap: () {
                context.push('/management/avatar');
              },
              child: ListTile(
                leading: const Icon(Icons.face_retouching_natural),
                trailing: const Icon(Icons.arrow_forward),
                title: const Text("头像管理"),
              ),
            ),
            InkWell(
              onTap: () {
                context.push('/management/feedback');
              },
              child: ListTile(
                leading: const Icon(Icons.feedback_outlined),
                trailing: const Icon(Icons.arrow_forward),
                title: const Text("管理端反馈"),
              ),
            ),
            const Divider(height: 16),
            InkWell(
              onTap: () {
                context.push('/management/forum-account');
              },
              child: ListTile(
                leading: const Icon(Icons.link),
                trailing: const Icon(Icons.arrow_forward),
                title: const Text("论坛账号"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
