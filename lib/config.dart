import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

const title = '妖精论坛管理控制台';

const wideWidth = 600;

class ApiEndpoints {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASEURL',
    defaultValue: 'https://admin.forum.crazying-dev.top',
  );
}

class SharedPreferencesKeys {
  static const themeMode = 'theme_mode';
  static const useDynamicColor = 'use_dynamic_color';

  static const adminId = 'admin_id';
  static const adminToken = 'admin_token';
}

const defaultSeedColor = Color.fromARGB(255, 188, 230, 241);
const defaultThemeMode = ThemeMode.system;
const useDynamicColorDefault = false;

final dioBaseOptions = BaseOptions(
  baseUrl: ApiEndpoints.apiBaseUrl,
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 10),
  sendTimeout: const Duration(seconds: 10),
  responseType: ResponseType.json,
  headers: {'Content-Type': 'application/json'},
);
