import 'package:dio/dio.dart';
import 'package:fairy_forum_admin_app/api/client.dart';
import 'package:fairy_forum_admin_app/config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiException', () {
    test('toString 直接返回传入的消息', () {
      final e = ApiException(
        '测试消息',
        requestOptions: RequestOptions(path: '/x'),
      );
      expect(e.toString(), '测试消息');
    });
  });

  group('ApiClient.avatarProxyUrl', () {
    test('null 返回空串', () {
      expect(avatarProxyUrl(null), '');
    });

    test('空串返回空串', () {
      expect(avatarProxyUrl(''), '');
    });

    test('完整 URL（含 scheme）原样作为代理参数', () {
      const raw = 'https://cdn.example.com/a.png';
      final expected =
          '${ApiEndpoints.apiBaseUrl}/api/avatar-proxy?url=${Uri.encodeQueryComponent(raw)}';
      expect(avatarProxyUrl(raw), expected);
    });

    test('相对路径（IMG_BASE 编译期默认为空串）原样拼接代理前缀', () {
      final result = avatarProxyUrl('avatars/42.png');
      expect(result, contains('/api/avatar-proxy?url='));
      expect(result, endsWith(Uri.encodeQueryComponent('avatars/42.png')));
    });
  });
}
