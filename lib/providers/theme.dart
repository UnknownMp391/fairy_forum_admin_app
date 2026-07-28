import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

class ThemeModeNotifier extends AsyncNotifier<ThemeMode> {
  final storageKey = SharedPreferencesKeys.themeMode;

  @override
  FutureOr<ThemeMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(storageKey);
    if (index != null) {
      return ThemeMode.values[index];
    } else {
      return defaultThemeMode;
    }
  }

  Future set(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(storageKey, mode.index);
    state = AsyncValue.data(mode);
  }
}

final themeModeNotifierProvider =
    AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class UseDynamicColorNotifier extends AsyncNotifier<bool> {
  final storageKey = SharedPreferencesKeys.useDynamicColor;

  @override
  FutureOr<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getBool(storageKey) ?? useDynamicColorDefault;
    return data;
  }

  Future set(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(storageKey, value);
    state = AsyncValue.data(value);
  }
}

final useDynamicColorNotifierProvider =
    AsyncNotifierProvider<UseDynamicColorNotifier, bool>(
      UseDynamicColorNotifier.new,
    );
