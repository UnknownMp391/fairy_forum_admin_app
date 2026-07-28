import 'package:fairy_forum_admin_app/routes/management/user.dart';
import 'package:fairy_forum_admin_app/routes/management/user_list.dart';
import 'package:fairy_forum_admin_app/routes/root.dart';
import 'package:fairy_forum_admin_app/routes/home/settings.dart';
import 'package:fairy_forum_admin_app/routes/settings/theme.dart';
import 'package:fairy_forum_admin_app/routes/test.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => HomePage()),
    GoRoute(path: '/test', builder: (_, _) => TestPage()),
    GoRoute(
      path: '/settings',
      builder: (_, _) => const SettingsPage(),
      routes: [GoRoute(path: 'theme', builder: (_, _) => SettingsThemePage())],
    ),
    GoRoute(
      path: '/management',
      builder: (_, _) => const Placeholder(),
      routes: [
        GoRoute(path: 'userList', builder: (_, _) => ManagementUserListPage()),
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
