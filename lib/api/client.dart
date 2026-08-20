import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fairy_forum_admin_app/api/types/admins.dart';
import 'package:fairy_forum_admin_app/api/types/auth.dart';
import 'package:fairy_forum_admin_app/api/types/batch.dart';
import 'package:fairy_forum_admin_app/api/types/bug_reports.dart';
import 'package:fairy_forum_admin_app/api/types/comments.dart';
import 'package:fairy_forum_admin_app/api/types/feedback.dart';
import 'package:fairy_forum_admin_app/api/types/forum_account.dart';
import 'package:fairy_forum_admin_app/api/types/posts.dart';
import 'package:fairy_forum_admin_app/api/types/reports.dart';
import 'package:fairy_forum_admin_app/api/types/status.dart';
import 'package:fairy_forum_admin_app/api/types/trash.dart';
import 'package:fairy_forum_admin_app/api/types/users.dart';
import 'package:fairy_forum_admin_app/config.dart';
import 'package:fairy_forum_admin_app/dto/auth/identity.dart';

class NoValidIdentityException implements Exception {
  NoValidIdentityException();

  @override
  String toString() => '没有可用的认证令牌';
}

class ApiException extends DioException {
  final String? errorCode;

  ApiException(
    String message, {
    required super.requestOptions,
    super.response,
    super.type,
    this.errorCode,
  }) : super(message: message);

  @override
  String toString() => message ?? '请求失败';
}

Map<String, dynamic> _decodeJsonMap(
  dynamic raw,
  RequestOptions requestOptions,
) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is String && raw.isNotEmpty) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      // fallthrough
    }
  }
  throw ApiException('登录响应格式错误', requestOptions: requestOptions);
}

Future<LoginResult> login(Dio dio, String adminId, String password) async {
  final response = await dio.post<dynamic>(
    '/auth/login',
    data: LoginRequest(adminId: adminId, password: password).toJson(),
  );
  final data = _decodeJsonMap(response.data, response.requestOptions);
  return LoginResult.fromJson(data);
}

Future<bool> checkIdentityValid(IdentityData data, Dio dio) async {
  try {
    final response = await dio.get<dynamic>(
      '/auth/me',
      options: Options(headers: {'Authorization': 'Bearer ${data.adminToken}'}),
    );
    final body = response.data;
    Map<String, dynamic>? map;
    if (body is Map<String, dynamic>) {
      map = body;
    } else if (body is String) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) map = decoded;
      } on FormatException {
        // ignore
      }
    }
    final adminId = map?['adminId'];
    return adminId is String && adminId.isNotEmpty;
  } on Exception {
    return false;
  }
}

class ApiClient {
  static String avatarProxyUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return '';
    final hasScheme = Uri.tryParse(rawUrl)?.hasScheme ?? false;
    final resolved = hasScheme
        ? rawUrl
        : imgBase.isEmpty
        ? rawUrl
        : '${imgBase.replaceAll(RegExp(r'/+$'), '')}/${rawUrl.replaceAll(RegExp(r'^/+'), '')}';
    return '${ApiEndpoints.apiBaseUrl}/api/avatar-proxy?url=${Uri.encodeQueryComponent(resolved)}';
  }

  final Dio _dio;
  final IdentityData? _identityData;
  ApiClient(this._dio, this._identityData);

  String? get _token => _identityData?.adminToken;

  Options _authOptions() {
    final token = _token;
    if (token == null) {
      throw NoValidIdentityException();
    }
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<dynamic> _get(String path, {Map<String, dynamic>? query}) async {
    final response = await _dio.get<dynamic>(
      path,
      queryParameters: query,
      options: _authOptions(),
    );
    return response.data;
  }

  Future<dynamic> _put(String path, {Object? body}) async {
    final response = await _dio.put<dynamic>(
      path,
      data: body ?? const <String, dynamic>{},
      options: _authOptions(),
    );
    return response.data;
  }

  Future<dynamic> _post(String path, {Object? body}) async {
    final response = await _dio.post<dynamic>(
      path,
      data: body ?? const <String, dynamic>{},
      options: _authOptions(),
    );
    return response.data;
  }

  Future<dynamic> _patch(String path, {Object? body}) async {
    final response = await _dio.patch<dynamic>(
      path,
      data: body ?? const <String, dynamic>{},
      options: _authOptions(),
    );
    return response.data;
  }

  Future<dynamic> _delete(String path, {Object? body}) async {
    final response = await _dio.delete<dynamic>(
      path,
      data: body ?? const <String, dynamic>{},
      options: _authOptions(),
    );
    return response.data;
  }

  Map<String, dynamic> _requireMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
      } on FormatException {
        // fallthrough
      }
    }
    throw Exception('响应格式错误：期望 JSON 对象');
  }

  List<T> _decodeList<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return (raw as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList();
  }

  List<T> _decodeListOrEmptyOnNull<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return raw == null ? [] : _decodeList(raw, fromJson);
  }

  dynamic _pageItems(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw['items'] ?? raw;
    }
    return raw;
  }

  BatchResult _decodeBatch(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return BatchResult.fromJson(raw);
    }
    return const BatchResult(status: {});
  }

  Future<List<Report>> listReports({
    bool? isResolved,
    int page = 1,
    int size = 20,
  }) async {
    final raw = await _get(
      '/api/reports',
      query: ReportsQuery(
        page: page,
        size: size,
        isResolved: isResolved,
      ).toJson(),
    );
    return _decodeListOrEmptyOnNull(_pageItems(raw), Report.fromJson);
  }

  Future<void> resolveReport(String reportId) async {
    await _patch(
      '/api/reports/$reportId',
      body: const ReportResolveRequest(isResolved: true).toJson(),
    );
  }

  Future<void> deletePostByReport(String reportId) async {
    await _delete('/api/reports/$reportId/post');
  }

  Future<BatchResult> batchResolveReports(List<String> reportIds) async {
    final raw = await _patch(
      '/api/reports',
      body: BatchResolveRequest(ids: reportIds, isResolved: true).toJson(),
    );
    return _decodeBatch(raw);
  }

  Future<List<UserListItem>> listUsers({
    int page = 1,
    int size = 20,
    String? key,
    String? value,
  }) async {
    final raw = await _get(
      '/api/users',
      query: UsersQuery(
        page: page,
        size: size,
        key: key,
        value: value,
      ).toJson(),
    );
    return _decodeListOrEmptyOnNull(_pageItems(raw), UserListItem.fromJson);
  }

  Future<List<UserListItem>> searchUsers(String q) async {
    final raw = await _get(
      '/api/users/search',
      query: UsersSearchQuery(q: q).toJson(),
    );
    return _decodeListOrEmptyOnNull(raw, UserListItem.fromJson);
  }

  Future<UserListItem> getUser(String userId) async {
    final raw = await _get('/api/users/$userId');
    return UserListItem.fromJson(_requireMap(raw));
  }

  Future<void> updateUser(
    String userId,
    String key,
    String value, {
    String? reason,
  }) async {
    await _patch(
      '/api/users/$userId',
      body: UserUpdateRequest(key: key, value: value, reason: reason).toJson(),
    );
  }

  Future<void> banUser(String userId, {String? reason}) async {
    await updateUser(userId, 'is_banned', '1', reason: reason);
  }

  Future<void> unbanUser(String userId, {String? reason}) async {
    await updateUser(userId, 'is_banned', '0', reason: reason);
  }

  Future<void> deleteUser(
    String userId, {
    String? reason,
    required String userName,
    required String userEmail,
  }) async {
    await _delete(
      '/api/users/$userId',
      body: UserDeleteRequest(
        reason: reason,
        userName: userName,
        userEmail: userEmail,
      ).toJson(),
    );
  }

  Future<BatchResult> batchSetUserBan(
    List<String> userIds, {
    required bool banned,
    String? reason,
  }) async {
    final raw = await _patch(
      '/api/users',
      body: UserBatchBanRequest(
        ids: userIds,
        key: 'is_banned',
        value: banned ? '1' : '0',
        reason: reason,
      ).toJson(),
    );
    return _decodeBatch(raw);
  }

  Future<BatchResult> batchBanUsers(List<String> userIds, {String? reason}) =>
      batchSetUserBan(userIds, banned: true, reason: reason);

  Future<BatchResult> batchUnbanUsers(List<String> userIds, {String? reason}) =>
      batchSetUserBan(userIds, banned: false, reason: reason);

  Future<BatchResult> batchDeleteUsers(
    List<UserDeleteItem> items, {
    String? reason,
  }) async {
    final raw = await _delete(
      '/api/users',
      body: UserBatchDeleteRequest(items: items, reason: reason).toJson(),
    );
    return _decodeBatch(raw);
  }

  Future<AvatarScanResult> scanUserAvatars(String domain) async {
    final raw = await _get(
      '/api/users/avatar-scan',
      query: AvatarScanQuery(domain: domain).toJson(),
    );
    return AvatarScanResult.fromJson(_requireMap(raw));
  }

  Future<int> replaceUserAvatars({
    required String domain,
    required List<String> avatars,
  }) async {
    final raw = await _put(
      '/api/users/avatars',
      body: AvatarReplaceRequest(domain: domain, avatars: avatars).toJson(),
    );
    return AvatarReplaceResult.fromJson(_requireMap(raw)).replaced;
  }

  Future<AvatarRestoreResult> restoreUserAvatars({
    required List<AvatarRestoreItem> items,
  }) async {
    final raw = await _post(
      '/api/users/avatars/restore',
      body: AvatarRestoreRequest(items: items).toJson(),
    );
    return AvatarRestoreResult.fromJson(_requireMap(raw));
  }

  Future<UserStats> getUserStats(String userId) async {
    final raw = await _get('/api/users/$userId/stats');
    return UserStats.fromJson(_requireMap(raw));
  }

  Future<List<BanHistoryEntry>> getUserBanHistory(String userId) async {
    final raw = await _get('/api/users/$userId/ban-history');
    return _decodeListOrEmptyOnNull(raw, BanHistoryEntry.fromJson);
  }

  Future<List<PostDetail>> getUserPosts(
    String userId, {
    int page = 1,
    int size = 20,
  }) async {
    final raw = await _get(
      '/api/users/$userId/posts',
      query: UserPostsQuery(page: page, size: size).toJson(),
    );
    return _decodeListOrEmptyOnNull(_pageItems(raw), PostDetail.fromJson);
  }

  Future<List<Comment>> getUserComments(String userId, {int size = 100}) async {
    final raw = await _get(
      '/api/users/$userId/comments',
      query: UserCommentsQuery(size: size).toJson(),
    );
    return _decodeListOrEmptyOnNull(_pageItems(raw), Comment.fromJson);
  }

  Future<List<PostDetail>> listPosts({
    int page = 1,
    int size = 20,
    String? category,
    String? q,
  }) async {
    final raw = await _get(
      '/api/posts',
      query: PostsQuery(
        page: page,
        size: size,
        category: category,
        q: q,
      ).toJson(),
    );
    return _decodeListOrEmptyOnNull(_pageItems(raw), PostDetail.fromJson);
  }

  Future<PostDetail?> getPostDetail(String postId) async {
    final raw = await _get('/api/posts/$postId');
    if (raw == null) return null;
    return PostDetail.fromJson(_requireMap(raw));
  }

  Future<void> deletePost(String postId, {String? reason}) async {
    await _delete(
      '/api/posts/$postId',
      body: PostDeleteRequest(reason: reason).toJson(),
    );
  }

  Future<BatchResult> batchDeletePosts(
    List<String> postIds, {
    String? reason,
  }) async {
    final raw = await _delete(
      '/api/posts',
      body: IdsReasonRequest(ids: postIds, reason: reason).toJson(),
    );
    return _decodeBatch(raw);
  }

  Future<List<Comment>> getPostComments(String postId) async {
    final raw = await _get('/api/posts/$postId/comments');
    return _decodeListOrEmptyOnNull(raw, Comment.fromJson);
  }

  Future<Comment> getPostComment(String postId, String commentId) async {
    final raw = await _get('/api/comments/post/$postId/$commentId');
    return Comment.fromJson(_requireMap(raw));
  }

  Future<void> deleteComment(String commentId, {String? reason}) async {
    await _delete(
      '/api/comments/$commentId',
      body: CommentDeleteRequest(reason: reason).toJson(),
    );
  }

  Future<BatchResult> batchDeleteComments(
    List<String> commentIds, {
    String? reason,
  }) async {
    final raw = await _delete(
      '/api/comments',
      body: IdsReasonRequest(ids: commentIds, reason: reason).toJson(),
    );
    return _decodeBatch(raw);
  }

  Future<List<Comment>> listComments({
    int page = 1,
    int size = 20,
    String? q,
    String? postId,
  }) async {
    final raw = await _get(
      '/api/comments',
      query: CommentsQuery(
        page: page,
        size: size,
        q: q,
        postId: postId,
      ).toJson(),
    );
    return _decodeListOrEmptyOnNull(_pageItems(raw), Comment.fromJson);
  }

  Future<ForumStatus> getStats() async {
    final raw = await _get('/api/stats');
    return ForumStatus.fromJson(_requireMap(raw));
  }

  Future<List<AdminInfo>> listRemoteAdmins() async {
    final raw = await _get('/upstream/admins');
    return _decodeListOrEmptyOnNull(raw, AdminInfo.fromJson);
  }

  Future<void> createRemoteAdmin({
    required String adminId,
    required String key,
    String? role,
  }) async {
    await _post(
      '/upstream/admins',
      body: AdminCreateRequest(adminId: adminId, key: key, role: role).toJson(),
    );
  }

  Future<void> deleteRemoteAdmin(String adminId) async {
    await _delete('/upstream/admins/$adminId');
  }

  Future<void> updateRemoteAdminRole(String adminId, String role) async {
    await _patch(
      '/upstream/admins/$adminId',
      body: AdminRoleRequest(role: role).toJson(),
    );
  }

  Future<void> resetRemoteAdminKey(String adminId, String key) async {
    await _patch(
      '/upstream/admins/$adminId',
      body: AdminKeyRequest(key: key).toJson(),
    );
  }

  Future<BatchResult> batchDeleteRemoteAdmins(List<String> adminIds) async {
    final raw = await _delete(
      '/upstream/admins',
      body: IdsRequest(ids: adminIds).toJson(),
    );
    return _decodeBatch(raw);
  }

  Future<BatchResult> batchUpdateRemoteAdminRole(
    List<String> adminIds,
    String role,
  ) async {
    final raw = await _patch(
      '/upstream/admins',
      body: AdminBatchRoleRequest(ids: adminIds, role: role).toJson(),
    );
    return _decodeBatch(raw);
  }

  Future<List<AdminInfo>> listLocalAdmins() async {
    final raw = await _get('/api/admins');
    return _decodeListOrEmptyOnNull(raw, AdminInfo.fromJson);
  }

  Future<AdminInfo> getLocalAdmin(String adminId) async {
    final raw = await _get('/api/admins/$adminId');
    return AdminInfo.fromJson(_requireMap(raw));
  }

  Future<void> createLocalAdmin({
    required String adminId,
    required String password,
    String? role,
  }) async {
    await _post(
      '/api/admins',
      body: LocalAdminCreateRequest(
        adminId: adminId,
        password: password,
        role: role,
      ).toJson(),
    );
  }

  Future<void> updateLocalAdmin(
    String adminId, {
    String? role,
    String? password,
    String? upsId,
    String? upsToken,
  }) async {
    await _patch(
      '/api/admins/$adminId',
      body: LocalAdminUpdateRequest(
        role: role,
        password: password,
        upsId: upsId,
        upsToken: upsToken,
      ).toJson(),
    );
  }

  Future<void> deleteLocalAdmin(String adminId) async {
    await _delete('/api/admins/$adminId');
  }

  Future<BatchResult> batchDeleteLocalAdmins(List<String> adminIds) async {
    final raw = await _delete(
      '/api/admins',
      body: IdsRequest(ids: adminIds).toJson(),
    );
    return _decodeBatch(raw);
  }

  Future<BatchResult> batchUpdateLocalAdminRole(
    List<String> adminIds,
    String role,
  ) async {
    final raw = await _patch(
      '/api/admins',
      body: AdminBatchRoleRequest(ids: adminIds, role: role).toJson(),
    );
    return _decodeBatch(raw);
  }

  Future<void> createFeedback({
    required String type,
    required String title,
    required String content,
  }) async {
    await _post(
      '/api/feedback',
      body: FeedbackCreateRequest(
        type: type,
        title: title,
        content: content,
      ).toJson(),
    );
  }

  Future<List<FeedbackItem>> listFeedback({
    String? status,
    int page = 1,
    int size = 20,
  }) async {
    final raw = await _get(
      '/api/feedback',
      query: FeedbackQuery(page: page, size: size, status: status).toJson(),
    );
    return _decodeListOrEmptyOnNull(_pageItems(raw), FeedbackItem.fromJson);
  }

  Future<FeedbackItem?> getFeedbackDetail(String id) async {
    final raw = await _get('/api/feedback/$id');
    if (raw == null) return null;
    return FeedbackItem.fromJson(_requireMap(raw));
  }

  Future<void> updateFeedbackStatus(
    String id,
    String status, {
    String? note,
  }) async {
    await _patch(
      '/api/feedback/$id',
      body: FeedbackStatusUpdateRequest(status: status, note: note).toJson(),
    );
  }

  Future<List<FeedbackStatusChange>> listFeedbackChangelog({
    String? handlerId,
    String? toStatus,
    String? feedbackId,
  }) async {
    final raw = await _get(
      '/api/feedback/changelog',
      query: FeedbackChangelogQuery(
        handlerId: handlerId,
        toStatus: toStatus,
        feedbackId: feedbackId,
      ).toJson(),
    );
    return _decodeListOrEmptyOnNull(raw, FeedbackStatusChange.fromJson);
  }

  Future<BatchResult> batchUpdateFeedbackStatus(
    List<String> ids,
    String status, {
    String? note,
  }) async {
    final raw = await _patch(
      '/api/feedback',
      body: BatchFeedbackStatusRequest(
        ids: ids,
        status: status,
        note: note,
      ).toJson(),
    );
    return _decodeBatch(raw);
  }

  Future<FeedbackAttachmentResult> uploadFeedbackAttachment(
    String id,
    MultipartFile file,
  ) async {
    final formData = FormData.fromMap({'file': file});
    final response = await _dio.post<dynamic>(
      '/api/feedback/$id/attachments',
      data: formData,
      options: _authOptions(),
    );
    return FeedbackAttachmentResult.fromJson(_requireMap(response.data));
  }

  Future<void> downloadFeedbackAttachment(
    String id,
    String attachmentId,
    String savePath,
  ) async {
    await _dio.download(
      '/api/feedback/$id/attachments/$attachmentId',
      savePath,
      options: _authOptions(),
    );
  }

  Future<List<BugReport>> listBugReports({
    int? status,
    String? search,
    int page = 1,
    int size = 20,
  }) async {
    final raw = await _get(
      '/api/bug-reports',
      query: BugReportsQuery(
        page: page,
        size: size,
        status: status,
        search: search,
      ).toJson(),
    );
    return _decodeListOrEmptyOnNull(_pageItems(raw), BugReport.fromJson);
  }

  Future<BugReport?> getBugReportDetail(int id) async {
    final raw = await _get('/api/bug-reports/$id');
    if (raw == null) return null;
    return BugReport.fromJson(_requireMap(raw));
  }

  Future<void> createBugReport({
    required String title,
    required String detail,
    required String steps,
    required String contact,
  }) async {
    await _post(
      '/api/bug-reports',
      body: BugReportCreateRequest(
        title: title,
        detail: detail,
        steps: steps,
        contact: contact,
      ).toJson(),
    );
  }

  Future<void> updateBugReportStatus(int id, int status, {String? note}) async {
    await _patch(
      '/api/bug-reports/$id',
      body: BugReportStatusUpdateRequest(status: status, note: note).toJson(),
    );
  }

  Future<BatchResult> batchUpdateBugReportStatus(
    List<String> ids,
    int status, {
    String? note,
  }) async {
    final raw = await _patch(
      '/api/bug-reports',
      body: BatchBugReportStatusRequest(
        ids: ids,
        status: status,
        note: note,
      ).toJson(),
    );
    return _decodeBatch(raw);
  }

  Future<void> deleteBugReport(int id) async {
    await _delete('/api/bug-reports/$id');
  }

  Future<BatchResult> batchDeleteBugReports(List<String> ids) async {
    final raw = await _delete(
      '/api/bug-reports',
      body: IdsRequest(ids: ids).toJson(),
    );
    return _decodeBatch(raw);
  }

  Future<List<BugReportChangelogEntry>> listBugReportChangelog({
    int? feedbackId,
    int page = 1,
    int size = 20,
  }) async {
    final raw = await _get(
      '/api/bug-reports/changelog',
      query: BugReportChangelogQuery(
        feedbackId: feedbackId,
        page: page,
        size: size,
      ).toJson(),
    );
    return _decodeListOrEmptyOnNull(
      _pageItems(raw),
      BugReportChangelogEntry.fromJson,
    );
  }

  Future<ForumAccountStatus> getForumAccountStatus() async {
    final raw = await _get('/api/forum-account');
    return ForumAccountStatus.fromJson(_requireMap(raw));
  }

  Future<void> bindForumAccount({
    required String name,
    required String password,
  }) async {
    await _put(
      '/api/forum-account',
      body: ForumAccountBindRequest(name: name, password: password).toJson(),
    );
  }

  Future<void> unbindForumAccount() async {
    await _delete('/api/forum-account');
  }

  Future<List<TrashPost>> listTrashPosts({
    int page = 1,
    int size = 20,
    String? q,
    String? deletedBy,
    String? from,
    String? to,
    String? category,
  }) async {
    final raw = await _get(
      '/api/trash/posts',
      query: TrashPostsQuery(
        page: page,
        size: size,
        q: q,
        deletedBy: deletedBy,
        from: from,
        to: to,
        category: category,
      ).toJson(),
    );
    return _decodeListOrEmptyOnNull(_pageItems(raw), TrashPost.fromJson);
  }

  Future<List<TrashComment>> listTrashComments({
    int page = 1,
    int size = 20,
    String? q,
    String? deletedBy,
    String? from,
    String? to,
    String? postId,
  }) async {
    final raw = await _get(
      '/api/trash/comments',
      query: TrashCommentsQuery(
        page: page,
        size: size,
        q: q,
        deletedBy: deletedBy,
        from: from,
        to: to,
        postId: postId,
      ).toJson(),
    );
    return _decodeListOrEmptyOnNull(_pageItems(raw), TrashComment.fromJson);
  }

  Future<List<TrashUser>> listTrashUsers({
    int page = 1,
    int size = 20,
    String? q,
    String? deletedBy,
    String? from,
    String? to,
  }) async {
    final raw = await _get(
      '/api/trash/users',
      query: TrashUsersQuery(
        page: page,
        size: size,
        q: q,
        deletedBy: deletedBy,
        from: from,
        to: to,
      ).toJson(),
    );
    return _decodeListOrEmptyOnNull(_pageItems(raw), TrashUser.fromJson);
  }

  Future<void> restoreTrashPost(String id) async {
    await _post('/api/trash/posts/$id/restore');
  }

  Future<void> restoreTrashComment(String id) async {
    await _post('/api/trash/comments/$id/restore');
  }

  Future<void> restoreTrashUser(String id) async {
    await _post('/api/trash/users/$id/restore');
  }

  Future<BatchResult> batchRestoreTrash(List<String> ids, String kind) async {
    final raw = await _post(
      '/api/trash/$kind/restore',
      body: TrashRestoreRequest(ids: ids, kind: kind).toJson(),
    );
    return _decodeBatch(raw);
  }
}
