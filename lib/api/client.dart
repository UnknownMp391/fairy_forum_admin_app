import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:fairy_forum_admin_app/api/types/status.dart';
import 'package:fairy_forum_admin_app/api/types/users.dart';
import 'package:fairy_forum_admin_app/dto/auth/identity.dart';

class NoValidIdentityException implements Exception {
  NoValidIdentityException();

  @override
  String toString() => '没有可用的认证密钥';
}

Future<bool> checkIdentityValid(IdentityData data, Dio dio) async {
  final client = ApiClient(dio, data);

  try {
    final _ = await client.getStats();
    return true;
  } on Exception {
    return false;
  }
}

class ApiClient {
  final Dio _dio;
  final IdentityData? _identityData;
  ApiClient(this._dio, this._identityData);

  String _sha256(String text) {
    final bytes = utf8.encode(text);
    return sha256.convert(bytes).toString();
  }

  String _timePassword() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}'
        '-${now.day.toString().padLeft(2, '0')}'
        '-${now.hour.toString().padLeft(2, '0')}';
  }

  String _generateTimeToken(String sendTime) {
    final raw = '${_identityData!.adminId}$sendTime';
    return _sha256(raw).substring(0, 16);
  }

  String _generateSig(String sendTime) {
    final raw = '${_identityData!.adminId}${_identityData.adminToken}$sendTime';
    return _sha256(raw);
  }

  Future<dynamic> _request(
    String action, [
    Map<String, dynamic> args = const {},
  ]) async {
    if (_identityData == null) {
      throw NoValidIdentityException();
    }

    final id = _identityData;
    final sendTime = (DateTime.now().millisecondsSinceEpoch / 1000).toString();

    final payload = {
      'password': _timePassword(),
      'AdminID': id.adminId,
      'adminId': id.adminId,
      'AdminToken': id.adminToken,
      'TimeToken': _generateTimeToken(sendTime),
      'SendTime': sendTime,
      'sendTime': sendTime,
      'RunMessage': jsonEncode({'action': action, 'args': args}),
      'runMessage': jsonEncode({'action': action, 'args': args}),
      'signature': _generateSig(sendTime),
    };

    final response = await _dio.post(
      '/',
      data: payload,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    final data = response.data as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception('请求失败: ${data['message']}');
    }
    return data['data'];
  }

  Future<List<dynamic>> listReports({int? status}) async {
    final args = <String, dynamic>{};
    if (status != null) args['status'] = status;
    return (await _request('list_reports', args)) as List<dynamic>;
  }

  Future<dynamic> resolveReport(int reportId) async {
    return _request('resolve_report', {'report_id': reportId});
  }

  Future<List<UserListItem>> listUsers() async {
    return ((await _request('list_users')) as List<dynamic>)
        .map((el) => UserListItem.fromJson(el))
        .toList();
  }

  Future<List<dynamic>> findUser(String key, String value) async {
    return (await _request('find_user', {'key': key, 'value': value}))
        as List<dynamic>;
  }

  Future<List<dynamic>> findUserSmart(String identifier) async {
    return (await _request('find_user_smart', {'identifier': identifier}))
        as List<dynamic>;
  }

  Future<dynamic> updateUser(String userId, String key, String value) async {
    return _request('update_user', {
      'user_id': userId,
      'key': key,
      'value': value,
    });
  }

  Future<dynamic> banUser(String userId) async {
    return _request('ban_user', {'user_id': userId});
  }

  Future<dynamic> unbanUser(String userId) async {
    return _request('unban_user', {'user_id': userId});
  }

  Future<Map<String, dynamic>?> getPostDetail(String postId) async {
    final result = await _request('get_post_detail', {'post_id': postId});
    return result as Map<String, dynamic>?;
  }

  Future<dynamic> deletePost(String postId) async {
    return _request('delete_post', {'post_id': postId});
  }

  Future<List<dynamic>> getPostComments(String postId) async {
    return (await _request('get_post_comments', {'post_id': postId}))
        as List<dynamic>;
  }

  Future<dynamic> deleteComment(String commentId) async {
    return _request('delete_comment', {'comment_id': commentId});
  }

  Future<ForumStatus> getStats() async {
    return ForumStatus.fromJson(await _request('get_stats'));
  }
}
