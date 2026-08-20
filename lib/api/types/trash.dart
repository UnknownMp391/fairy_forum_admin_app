import 'package:fairy_forum_admin_app/api/types/comments.dart';
import 'package:fairy_forum_admin_app/api/types/posts.dart';
import 'package:fairy_forum_admin_app/api/types/users.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'trash.freezed.dart';
part 'trash.g.dart';

@freezed
abstract class TrashPost with _$TrashPost {
  const factory TrashPost({
    @JsonKey(name: '_id') required String id,
    @JsonKey(name: 'original_post') PostDetail? originalPost,
    @JsonKey(name: 'delete_reason') String? deleteReason,
    @JsonKey(name: 'deleted_by_admin_id') String? deletedByAdminId,
    @JsonKey(name: 'deleted_by_admin_name') String? deletedByAdminName,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
    @JsonKey(name: 'source_report_id') String? sourceReportId,
    @JsonKey(name: 'restored_by_admin_id') String? restoredByAdminId,
    @JsonKey(name: 'restored_by_admin_name') String? restoredByAdminName,
    @JsonKey(name: 'restored_at') DateTime? restoredAt,
  }) = _TrashPost;

  factory TrashPost.fromJson(Map<String, dynamic> json) =>
      _$TrashPostFromJson(json);
}

@freezed
abstract class TrashComment with _$TrashComment {
  const factory TrashComment({
    @JsonKey(name: '_id') required String id,
    @JsonKey(name: 'original_comment') Comment? originalComment,
    @JsonKey(name: 'delete_reason') String? deleteReason,
    @JsonKey(name: 'deleted_by_admin_id') String? deletedByAdminId,
    @JsonKey(name: 'deleted_by_admin_name') String? deletedByAdminName,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
    @JsonKey(name: 'source_report_id') String? sourceReportId,
    @JsonKey(name: 'restored_by_admin_id') String? restoredByAdminId,
    @JsonKey(name: 'restored_by_admin_name') String? restoredByAdminName,
    @JsonKey(name: 'restored_at') DateTime? restoredAt,
  }) = _TrashComment;

  factory TrashComment.fromJson(Map<String, dynamic> json) =>
      _$TrashCommentFromJson(json);
}

@freezed
abstract class TrashUser with _$TrashUser {
  const factory TrashUser({
    @JsonKey(name: '_id') required String id,
    @JsonKey(name: 'original_user') UserListItem? originalUser,
    @JsonKey(name: 'delete_reason') String? deleteReason,
    @JsonKey(name: 'deleted_by_admin_id') String? deletedByAdminId,
    @JsonKey(name: 'deleted_by_admin_name') String? deletedByAdminName,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
    @JsonKey(name: 'restored_by_admin_id') String? restoredByAdminId,
    @JsonKey(name: 'restored_by_admin_name') String? restoredByAdminName,
    @JsonKey(name: 'restored_at') DateTime? restoredAt,
  }) = _TrashUser;

  factory TrashUser.fromJson(Map<String, dynamic> json) =>
      _$TrashUserFromJson(json);
}

@freezed
abstract class TrashPostsQuery with _$TrashPostsQuery {
  const factory TrashPostsQuery({
    @JsonKey(name: 'page', includeIfNull: false) required int page,
    @JsonKey(name: 'size', includeIfNull: false) required int size,
    @JsonKey(name: 'q', includeIfNull: false) String? q,
    @JsonKey(name: 'deleted_by', includeIfNull: false) String? deletedBy,
    @JsonKey(name: 'from', includeIfNull: false) String? from,
    @JsonKey(name: 'to', includeIfNull: false) String? to,
    @JsonKey(name: 'category', includeIfNull: false) String? category,
  }) = _TrashPostsQuery;

  factory TrashPostsQuery.fromJson(Map<String, dynamic> json) =>
      _$TrashPostsQueryFromJson(json);
}

@freezed
abstract class TrashCommentsQuery with _$TrashCommentsQuery {
  const factory TrashCommentsQuery({
    @JsonKey(name: 'page', includeIfNull: false) required int page,
    @JsonKey(name: 'size', includeIfNull: false) required int size,
    @JsonKey(name: 'q', includeIfNull: false) String? q,
    @JsonKey(name: 'deleted_by', includeIfNull: false) String? deletedBy,
    @JsonKey(name: 'from', includeIfNull: false) String? from,
    @JsonKey(name: 'to', includeIfNull: false) String? to,
    @JsonKey(name: 'post_id', includeIfNull: false) String? postId,
  }) = _TrashCommentsQuery;

  factory TrashCommentsQuery.fromJson(Map<String, dynamic> json) =>
      _$TrashCommentsQueryFromJson(json);
}

@freezed
abstract class TrashUsersQuery with _$TrashUsersQuery {
  const factory TrashUsersQuery({
    @JsonKey(name: 'page', includeIfNull: false) required int page,
    @JsonKey(name: 'size', includeIfNull: false) required int size,
    @JsonKey(name: 'q', includeIfNull: false) String? q,
    @JsonKey(name: 'deleted_by', includeIfNull: false) String? deletedBy,
    @JsonKey(name: 'from', includeIfNull: false) String? from,
    @JsonKey(name: 'to', includeIfNull: false) String? to,
  }) = _TrashUsersQuery;

  factory TrashUsersQuery.fromJson(Map<String, dynamic> json) =>
      _$TrashUsersQueryFromJson(json);
}

@freezed
abstract class TrashRestoreRequest with _$TrashRestoreRequest {
  const factory TrashRestoreRequest({
    @JsonKey(name: 'ids') required List<String> ids,
    @JsonKey(name: 'kind') required String kind,
  }) = _TrashRestoreRequest;

  factory TrashRestoreRequest.fromJson(Map<String, dynamic> json) =>
      _$TrashRestoreRequestFromJson(json);
}
