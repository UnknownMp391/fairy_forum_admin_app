import 'package:dio/dio.dart';
import 'package:fairy_forum_admin_app/providers/identity.dart';
import 'package:fairy_forum_admin_app/api/client.dart';
import 'package:fairy_forum_admin_app/config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'api_client.g.dart';

@riverpod
Dio dio(Ref ref) {
  final dio = Dio(dioBaseOptions);

  dio.interceptors.add(
    LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: false,
      responseHeader: true,
      responseBody: false,
      error: true,
    ),
  );

  return dio;
}

final apiClientProvider = Provider(
  (ref) => ApiClient(
    ref.watch(dioProvider),
    ref.watch(identityStorageProvider).whenOrNull(data: (data) => data),
  ),
);
