import 'package:fairy_forum_admin_app/config.dart';
import 'package:fairy_forum_admin_app/polyfills/dynamic_color.dart';
import 'package:fairy_forum_admin_app/providers/identity.dart';
import 'package:fairy_forum_admin_app/providers/theme.dart';
import 'package:flutter/material.dart';
import 'package:fairy_forum_admin_app/router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isValidingIdentity = ref.watch(isValidingIdentityProvider);
    return DynamicColorBuilder(
      builder: (light, dark) {
        final useDynamicColor =
            ref.watch(useDynamicColorNotifierProvider).value ??
            useDynamicColorDefault;
        final lightColorScheme = (useDynamicColor && light != null)
            ? light
            : ColorScheme.fromSeed(
                seedColor: defaultSeedColor,
                brightness: Brightness.light,
              );
        final darkColorScheme = (useDynamicColor && dark != null)
            ? dark
            : ColorScheme.fromSeed(
                seedColor: defaultSeedColor,
                brightness: Brightness.dark,
              );
        return MaterialApp.router(
          title: title,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightColorScheme,
            appBarTheme: AppBarTheme(
              backgroundColor: lightColorScheme.inversePrimary,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkColorScheme,
            appBarTheme: AppBarTheme(
              backgroundColor: darkColorScheme.inversePrimary,
            ),
          ),
          themeMode:
              ref.watch(themeModeNotifierProvider).value ?? defaultThemeMode,
          routerConfig: router,
          builder: (context, child) => isValidingIdentity
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : child ?? const SizedBox(),
        );
      },
    );
  }
}
