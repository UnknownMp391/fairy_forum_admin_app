import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:fairy_forum_admin_app/api/client.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void reportError(Object error, {String? context, StackTrace? stackTrace}) {
  if (!Sentry.isEnabled) return;
  if (error is ApiException) {
    if (error.errorCode == 'no_byok' ||
        error.errorCode == 'invalid_credentials') {
      return;
    }
  }

  final fingerprint = _fingerprint(error);
  if (!_shouldReport(fingerprint)) return;

  Sentry.captureException(
    error,
    stackTrace: stackTrace,
    withScope: (scope) {
      if (context != null) scope.setTag('ui_context', context);
      scope.setTag('fingerprint', fingerprint);
    },
  );
}

String _fingerprint(Object error) {
  if (error is ApiException) {
    return 'ApiException|${error.errorCode}|${error.message}';
  }
  if (error is DioException) {
    return 'DioException|${error.type}|${error.message}';
  }
  return '${error.runtimeType}|$error';
}

const dedupWindow = Duration(minutes: 5);
const _maxFingerprints = 500;

final _recentReports = HashMap<String, int>();

bool _shouldReport(String fingerprint) {
  final now = DateTime.now().millisecondsSinceEpoch;
  final last = _recentReports[fingerprint];
  if (last != null && now - last < dedupWindow.inMilliseconds) {
    return false;
  }
  if (_recentReports.length >= _maxFingerprints) {
    _recentReports.clear();
  }
  _recentReports[fingerprint] = now;
  return true;
}
