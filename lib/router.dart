import 'package:fairy_forum_admin_app/routes/management/admins.dart';
import 'package:fairy_forum_admin_app/routes/management/avatar.dart';
import 'package:fairy_forum_admin_app/routes/management/bug_reports.dart';
import 'package:fairy_forum_admin_app/routes/management/bug_reports_detail.dart';
import 'package:fairy_forum_admin_app/routes/management/comments.dart';
import 'package:fairy_forum_admin_app/routes/management/comment_replies.dart';
import 'package:fairy_forum_admin_app/routes/management/feedback.dart';
import 'package:fairy_forum_admin_app/routes/management/feedback_detail.dart';
import 'package:fairy_forum_admin_app/routes/management/forum_account.dart';
import 'package:fairy_forum_admin_app/routes/management/local_admins.dart';
import 'package:fairy_forum_admin_app/routes/management/post.dart';
import 'package:fairy_forum_admin_app/routes/management/post_detail.dart';
import 'package:fairy_forum_admin_app/routes/management/reports.dart';
import 'package:fairy_forum_admin_app/routes/management/trash.dart';
import 'package:fairy_forum_admin_app/routes/management/user.dart';
import 'package:fairy_forum_admin_app/routes/management/user_list.dart';
import 'package:fairy_forum_admin_app/routes/root.dart';
import 'package:fairy_forum_admin_app/routes/home/settings.dart';
import 'package:fairy_forum_admin_app/routes/settings/about.dart';
import 'package:fairy_forum_admin_app/routes/settings/byok.dart';
import 'package:fairy_forum_admin_app/routes/settings/theme.dart';
import 'package:fairy_forum_admin_app/components/error_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final authStateListenable = ValueNotifier<bool>(false);

final router = GoRouter(
  refreshListenable: authStateListenable,
  redirect: (context, state) {
    final location = state.matchedLocation;
    final needsAuth =
        location.startsWith('/management') ||
        location == '/settings/local-admins' ||
        location == '/settings/byok';
    if (!authStateListenable.value && needsAuth) {
      return '/';
    }
    return null;
  },
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('出错了')),
    body: LoadErrorView(
      error: state.error ?? '未知错误',
      onRetry: () => context.go('/'),
      context: 'router-error',
    ),
  ),
  routes: [
    GoRoute(path: '/', builder: (_, _) => HomePage()),
    GoRoute(
      path: '/settings',
      builder: (_, _) => const SettingsPage(),
      routes: [
        GoRoute(path: 'theme', builder: (_, _) => SettingsThemePage()),
        GoRoute(path: 'about', builder: (_, _) => const AboutPage()),
        GoRoute(path: 'byok', builder: (_, _) => const ByokSettingsPage()),
        GoRoute(
          path: 'local-admins',
          builder: (_, _) => const ManagementLocalAdminsPage(),
        ),
      ],
    ),
    GoRoute(
      path: '/management',
      redirect: (context, state) =>
          state.uri.path == '/management' ? '/management/userList' : null,
      routes: [
        GoRoute(path: 'userList', builder: (_, _) => ManagementUserListPage()),
        GoRoute(
          path: 'reports',
          builder: (_, _) => const ManagementReportsPage(),
        ),
        GoRoute(
          path: 'admins',
          builder: (_, _) => const ManagementAdminsPage(),
        ),
        GoRoute(
          path: 'avatar',
          builder: (_, _) => const ManagementAvatarPage(),
        ),
        GoRoute(
          path: 'bug-reports',
          builder: (_, _) => const ManagementBugReportsPage(),
          routes: [
            GoRoute(
              path: ':bugReportId',
              builder: (context, state) {
                final raw = state.pathParameters['bugReportId'];
                final id = int.tryParse(raw ?? '');
                if (id != null) {
                  return ManagementBugReportDetailPage(id: id);
                }
                return const Scaffold(body: Text('无效的论坛问题 ID'));
              },
            ),
          ],
        ),
        GoRoute(
          path: 'forum-account',
          builder: (_, _) => const ManagementForumAccountPage(),
        ),
        GoRoute(
          path: 'feedback',
          builder: (_, _) => const ManagementFeedbackPage(),
          routes: [
            GoRoute(
              path: ':feedbackId',
              builder: (context, state) {
                final id = state.pathParameters['feedbackId'];
                if (id != null) {
                  return ManagementFeedbackDetailPage(id: id);
                } else {
                  return const Scaffold(body: Text('未提供反馈 ID'));
                }
              },
            ),
          ],
        ),
        GoRoute(path: 'post', builder: (_, _) => const ManagementPostPage()),
        GoRoute(
          path: 'post/:postId',
          builder: (context, state) {
            final id = state.pathParameters['postId'];
            if (id != null) {
              return ManagementPostDetailPage(id: id);
            } else {
              return const Scaffold(body: Text('未提供帖子 ID'));
            }
          },
        ),
        GoRoute(
          path: 'comments',
          builder: (_, _) => const ManagementCommentsPage(),
        ),
        GoRoute(
          path: 'comment/:commentId/replies',
          builder: (context, state) {
            final commentId = state.pathParameters['commentId'];
            final postId = state.uri.queryParameters['postId'];
            if (commentId != null && postId != null) {
              return ManagementCommentRepliesPage(
                postId: postId,
                commentId: commentId,
              );
            }
            return const Scaffold(body: Text('缺少参数'));
          },
        ),
        GoRoute(
          path: 'trash',
          builder: (_, _) => const ManagementTrashPage(),
          routes: [
            GoRoute(path: 'posts', builder: (_, _) => const TrashPostsPage()),
            GoRoute(
              path: 'comments',
              builder: (_, _) => const TrashCommentsPage(),
            ),
            GoRoute(path: 'users', builder: (_, _) => const TrashUsersPage()),
          ],
        ),
        GoRoute(
          path: 'user',
          builder: (_, _) => const Placeholder(),
          routes: [
            GoRoute(
              path: ':userId',
              builder: (context, state) {
                final id = state.pathParameters['userId'];
                if (id != null) {
                  return ManagementUserDetailPage(id: id, extra: state.extra);
                } else {
                  return const Scaffold(body: Text('未提供 User ID'));
                }
              },
            ),
          ],
        ),
      ],
    ),
  ],
);
