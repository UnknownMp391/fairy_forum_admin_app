import 'package:fairy_forum_admin_app/api/types/admins.dart';
import 'package:fairy_forum_admin_app/api/types/feedback.dart';
import 'package:fairy_forum_admin_app/api/types/users.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('adminRoleLabel', () {
    test('superadmin -> 超级管理员', () {
      expect(adminRoleLabel('superadmin'), '超级管理员');
    });

    test('admin -> 管理员', () {
      expect(adminRoleLabel('admin'), '管理员');
    });

    test('null -> 未知', () {
      expect(adminRoleLabel(null), '未知');
    });

    test('未知角色原样返回', () {
      expect(adminRoleLabel('x'), 'x');
    });
  });

  group('genderLabel', () {
    test('1 -> 男', () {
      expect(genderLabel('1'), '男');
    });

    test('2 -> 女', () {
      expect(genderLabel('2'), '女');
    });

    test('0 -> 未知', () {
      expect(genderLabel('0'), '未知');
    });

    test('null -> 未知', () {
      expect(genderLabel(null), '未知');
    });
  });

  group('feedbackStatusLabel', () {
    test('pending -> 待处理', () {
      expect(feedbackStatusLabel('pending'), '待处理');
    });

    test('done -> 已完成', () {
      expect(feedbackStatusLabel('done'), '已完成');
    });

    test('未知状态原样返回', () {
      expect(feedbackStatusLabel('unknown'), 'unknown');
    });

    test('null -> 未知', () {
      expect(feedbackStatusLabel(null), '未知');
    });
  });

  group('反馈类型/状态常量', () {
    test('feedbackTypes 共 5 项且包含 bug（上游 v1.7.0 收紧）', () {
      expect(feedbackTypes.length, 5);
      expect(feedbackTypes, contains('bug'));
    });

    test('feedbackStatuses 共 4 项且包含 pending（上游 v1.7.0 收紧）', () {
      expect(feedbackStatuses.length, 4);
      expect(feedbackStatuses, contains('pending'));
    });
  });
}
