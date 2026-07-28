import 'package:flutter/material.dart';
import 'package:fairy_forum_admin_app/config.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../providers/theme.dart';

class SettingsThemePage extends HookConsumerWidget {
  const SettingsThemePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('外观')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: ListView(
            children: [
              const SizedBox(height: 16.0),
              ListTile(
                title: const Text('配色方案'),
                trailing: DropdownMenu<ThemeMode>(
                  initialSelection: ref.watch(
                    themeModeNotifierProvider.select(
                      (asyncValue) => asyncValue.value ?? ThemeMode.system,
                    ),
                  ),
                  onSelected: (value) {
                    if (value != null) {
                      ref.read(themeModeNotifierProvider.notifier).set(value);
                    }
                  },
                  dropdownMenuEntries: const [
                    DropdownMenuEntry(value: ThemeMode.system, label: '跟随系统'),
                    DropdownMenuEntry(value: ThemeMode.light, label: '亮色'),
                    DropdownMenuEntry(value: ThemeMode.dark, label: '暗色'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text('动态配色'),
                value: ref.watch(
                  useDynamicColorNotifierProvider.select(
                    (asyncValue) => asyncValue.value ?? useDynamicColorDefault,
                  ),
                ),
                onChanged: (value) {
                  ref.read(useDynamicColorNotifierProvider.notifier).set(value);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
