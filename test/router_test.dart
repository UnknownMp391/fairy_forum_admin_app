import 'package:fairy_forum_admin_app/providers/identity.dart';
import 'package:fairy_forum_admin_app/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('管理路由 redirect 只作用于精确路径，不劫持子路由', (tester) async {
    authStateListenable.value = true;
    addTearDown(() => authStateListenable.value = false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [isValidIdentityProvider.overrideWithValue(true)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    router.go('/management');
    await tester.pump();
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/management/userList',
    );

    router.go('/management/trash/posts');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/management/trash/posts',
    );
  });
}
