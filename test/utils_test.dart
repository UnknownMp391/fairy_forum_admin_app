import 'package:fairy_forum_admin_app/utils/converter.dart';
import 'package:fairy_forum_admin_app/utils/datetime.dart';
import 'package:fairy_forum_admin_app/utils/uri.dart';
import 'package:fairy_forum_admin_app/utils/sentry_reporter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatDateTime', () {
    test('本地时间按 yyyy-MM-dd HH:mm:ss 格式化', () {
      final dt = DateTime(2026, 8, 14, 19, 30, 45);
      expect(formatDateTime(dt), '2026-08-14 19:30:45');
    });
  });

  group('formatBirthdate', () {
    test('8 位数字按 yyyy-MM-dd 格式化', () {
      expect(formatBirthdate(20260814), '2026-08-14');
    });

    test('null 表示未设置，返回空串', () {
      expect(formatBirthdate(null), '');
    });

    test('0 表示未设置，返回空串', () {
      expect(formatBirthdate(0), '');
    });

    test('非 8 位数字原样返回', () {
      expect(formatBirthdate(12345), '12345');
    });

    test('只校验月份 1-12、日期 1-31，不校验真实日历', () {
      expect(formatBirthdate(20260230), '2026-02-30');
    });
  });

  group('nonZeroIntBool 转换', () {
    test('非零整数 -> true', () {
      expect(nonZeroIntBoolFromJson(1), isTrue);
    });

    test('0 -> false', () {
      expect(nonZeroIntBoolFromJson(0), isFalse);
    });

    test('true -> 1', () {
      expect(nonZeroIntBoolToJson(true), 1);
    });

    test('false -> 0', () {
      expect(nonZeroIntBoolToJson(false), 0);
    });
  });

  group('mapToQueryParameterString', () {
    test('空 map 返回空串', () {
      expect(mapToQueryParameterString(<String, dynamic>{}), '');
    });

    test('值中的空格按 Uri.encodeQueryComponent 编码', () {
      final result = mapToQueryParameterString({'a': 'b', 'c': 'd e'});
      expect(result, 'a=b&c=d+e');
      expect(result, 'a=b&c=${Uri.encodeQueryComponent('d e')}');
    });
  });

  group('reportError', () {
    test('Sentry 未初始化时调用不抛异常', () {
      expect(() => reportError(StateError('x')), returnsNormally);
      expect(
        () => reportError(Exception('y'), context: 'test'),
        returnsNormally,
      );
    });
  });
}
