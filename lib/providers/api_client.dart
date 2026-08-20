import 'package:dio/dio.dart';
import 'package:fairy_forum_admin_app/providers/identity.dart';
import 'package:fairy_forum_admin_app/api/client.dart';
import 'package:fairy_forum_admin_app/config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'api_client.g.dart';

@riverpod
Dio dio(Ref ref) {
  ref.keepAlive();

  final dio = Dio(dioBaseOptions);

  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (e, handler) {
        final responseData = e.response?.data;
        final data = responseData is Map<String, dynamic> ? responseData : null;
        final message = data != null && data['message'] is String
            ? data['message'] as String
            : null;
        final errorCode = data != null && data['error'] is String
            ? data['error'] as String
            : null;

        final effectiveMessage = (message == null || message.isEmpty)
            ? (e.message ?? '网络错误，请稍后重试')
            : message;

        final isLoginPath = e.requestOptions.path == '/auth/login';
        if (ref.mounted &&
            e.response?.statusCode == 401 &&
            errorCode == 'unauthorized') {
          ref.read(identityStorageProvider.notifier).clearIdentity();
        }

        var finalMessage = effectiveMessage;
        if (e.response?.statusCode == 401 &&
            errorCode == 'invalid_credentials' &&
            !isLoginPath) {
          finalMessage = '$effectiveMessage\n（你的上游凭据可能已失效/错误，请到 设置→BYOK 设置 检查）';
        }

        handler.reject(
          ApiException(
            finalMessage,
            requestOptions: e.requestOptions,
            response: e.response,
            type: e.type,
            errorCode: errorCode,
          ),
          false,
        );
      },
    ),
  );

  dio.interceptors.add(
    LogInterceptor(
      request: true,
      requestHeader: false,
      requestBody: false,
      responseHeader: false,
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
