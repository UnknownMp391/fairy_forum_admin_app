import 'package:fairy_forum_admin_app/api/types/auth.dart';
import 'package:fairy_forum_admin_app/api/types/batch.dart';
import 'package:fairy_forum_admin_app/api/types/reports.dart';
import 'package:fairy_forum_admin_app/api/types/users.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('请求体模型 toJson', () {
    test('LoginRequest', () {
      expect(LoginRequest(adminId: 'UnknownMp', password: 'pwd').toJson(), {
        'adminId': 'UnknownMp',
        'password': 'pwd',
      });
    });

    test('ReportResolveRequest', () {
      expect(const ReportResolveRequest(isResolved: true).toJson(), {
        'is_resolved': true,
      });
    });

    test('UserDeleteRequest 省略空 reason', () {
      final json = UserDeleteRequest(
        reason: null,
        userName: 'name',
        userEmail: 'a@b.c',
      ).toJson();
      expect(json['user_name'], 'name');
      expect(json['user_email'], 'a@b.c');
      expect(json.containsKey('reason'), isFalse);
    });

    test('BatchResolveRequest', () {
      expect(BatchResolveRequest(ids: ['1', '2'], isResolved: true).toJson(), {
        'ids': ['1', '2'],
        'is_resolved': true,
      });
    });

    test('IdsReasonRequest 省略空 reason', () {
      final json = IdsReasonRequest(ids: ['1'], reason: null).toJson();
      expect(json, {
        'ids': ['1'],
      });
    });
  });

  group('查询模型 toJson（includeIfNull 省略空值）', () {
    test('ReportsQuery 未筛选时省略 is_resolved', () {
      expect(ReportsQuery(page: 1, size: 20, isResolved: null).toJson(), {
        'page': 1,
        'size': 20,
      });
    });

    test('ReportsQuery 带 is_resolved', () {
      expect(ReportsQuery(page: 1, size: 20, isResolved: true).toJson(), {
        'page': 1,
        'size': 20,
        'is_resolved': true,
      });
    });

    test('UsersQuery 省略空 key/value', () {
      expect(UsersQuery(page: 2, size: 10, key: null, value: null).toJson(), {
        'page': 2,
        'size': 10,
      });
      expect(UsersQuery(page: 2, size: 10, key: 'name', value: 'x').toJson(), {
        'page': 2,
        'size': 10,
        'key': 'name',
        'value': 'x',
      });
    });
  });

  group('响应模型 fromJson', () {
    test('AvatarScanResult', () {
      final result = AvatarScanResult.fromJson({
        'total': 2,
        'items': [
          {'id': '1', 'name': 'a', 'avatar': 'avatars/1.png'},
        ],
      });
      expect(result.total, 2);
      expect(result.items.single.id, '1');
    });

    test('AvatarRestoreResult', () {
      final result = AvatarRestoreResult.fromJson({
        'restored': 3,
        'skipped': 2,
        'total': 5,
      });
      expect(result.restored, 3);
      expect(result.skipped, 2);
      expect(result.total, 5);
    });

    test('BatchResult', () {
      final result = BatchResult.fromJson({
        'status': {'a': true, 'b': false},
      });
      expect(result.successCount, 1);
      expect(result.failedCount, 1);
      expect(result.failedIds, ['b']);
    });
  });
}
