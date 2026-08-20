import 'package:fairy_forum_admin_app/dto/auth/identity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoginResult.fromJson', () {
    test('完整字段：token / role / expiresAt 均正确解析', () {
      final result = LoginResult.fromJson({
        'token': 't',
        'role': 'superadmin',
        'expiresAt': '2026-08-21T19:30:00+08:00',
      });
      expect(result.token, 't');
      expect(result.role, 'superadmin');
      expect(result.expiresAt, isNotNull);
      expect(result.expiresAt, DateTime.parse('2026-08-21T19:30:00+08:00'));
    });

    test('仅 token：role 为 null，expiresAt 为 null', () {
      final result = LoginResult.fromJson({'token': 't'});
      expect(result.token, 't');
      expect(result.role, isNull);
      expect(result.expiresAt, isNull);
    });
  });
}
