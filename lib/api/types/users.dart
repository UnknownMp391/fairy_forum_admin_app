import 'package:freezed_annotation/freezed_annotation.dart';

part 'users.freezed.dart';
part 'users.g.dart';

bool? userListIsBannedFromJson(Object? data) => data is num ? data != 0 : null;
int? userListIsBannedToJson(bool? data) => data == null ? null : (data ? 1 : 0);

String genderLabel(String? gender) {
  switch (gender) {
    case '1':
      return '男';
    case '2':
      return '女';
    default:
      return '未知';
  }
}

@freezed
abstract class UserListItem with _$UserListItem {
  const factory UserListItem({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'created_at') DateTime? createdAt,

    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'email') String? email,
    @JsonKey(name: 'avatar') String? avatarUrl,
    @JsonKey(name: 'intro') String? bio,
    @JsonKey(name: 'age') int? age,
    @JsonKey(name: 'gender') String? gender,

    @JsonKey(
      name: 'is_banned',
      fromJson: userListIsBannedFromJson,
      toJson: userListIsBannedToJson,
    )
    bool? isBanned,
  }) = _UserListItem;

  factory UserListItem.fromJson(Map<String, dynamic> json) =>
      _$UserListItemFromJson(json);
}

@freezed
abstract class UserStats with _$UserStats {
  const factory UserStats({
    @JsonKey(name: 'post_count') required int postCount,
    @JsonKey(name: 'comment_count') required int commentCount,
  }) = _UserStats;

  factory UserStats.fromJson(Map<String, dynamic> json) =>
      _$UserStatsFromJson(json);
}

@freezed
abstract class BanHistoryEntry with _$BanHistoryEntry {
  const factory BanHistoryEntry({
    @JsonKey(name: 'id') String? id,
    @JsonKey(name: 'user_id') String? userId,
    @JsonKey(name: 'user_name') String? userName,
    @JsonKey(name: 'action') String? action,
    @JsonKey(name: 'reason') String? reason,
    @JsonKey(name: 'admin_id') String? adminId,
    @JsonKey(name: 'admin_name') String? adminName,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _BanHistoryEntry;

  factory BanHistoryEntry.fromJson(Map<String, dynamic> json) =>
      _$BanHistoryEntryFromJson(json);
}

@freezed
abstract class AvatarScanUser with _$AvatarScanUser {
  const factory AvatarScanUser({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'name') String? name,
    @JsonKey(name: 'avatar') String? avatar,
  }) = _AvatarScanUser;

  factory AvatarScanUser.fromJson(Map<String, dynamic> json) =>
      _$AvatarScanUserFromJson(json);
}

@freezed
abstract class UserDeleteItem with _$UserDeleteItem {
  const factory UserDeleteItem({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'user_name') required String userName,
    @JsonKey(name: 'user_email') required String userEmail,
  }) = _UserDeleteItem;

  factory UserDeleteItem.fromJson(Map<String, dynamic> json) =>
      _$UserDeleteItemFromJson(json);
}

@freezed
abstract class UsersQuery with _$UsersQuery {
  const factory UsersQuery({
    @JsonKey(name: 'page', includeIfNull: false) required int page,
    @JsonKey(name: 'size', includeIfNull: false) required int size,
    @JsonKey(name: 'key', includeIfNull: false) String? key,
    @JsonKey(name: 'value', includeIfNull: false) String? value,
  }) = _UsersQuery;

  factory UsersQuery.fromJson(Map<String, dynamic> json) =>
      _$UsersQueryFromJson(json);
}

@freezed
abstract class UsersSearchQuery with _$UsersSearchQuery {
  const factory UsersSearchQuery({@JsonKey(name: 'q') required String q}) =
      _UsersSearchQuery;

  factory UsersSearchQuery.fromJson(Map<String, dynamic> json) =>
      _$UsersSearchQueryFromJson(json);
}

@freezed
abstract class UserPostsQuery with _$UserPostsQuery {
  const factory UserPostsQuery({
    @JsonKey(name: 'page', includeIfNull: false) required int page,
    @JsonKey(name: 'size', includeIfNull: false) required int size,
  }) = _UserPostsQuery;

  factory UserPostsQuery.fromJson(Map<String, dynamic> json) =>
      _$UserPostsQueryFromJson(json);
}

@freezed
abstract class UserCommentsQuery with _$UserCommentsQuery {
  const factory UserCommentsQuery({
    @JsonKey(name: 'page', includeIfNull: false) int? page,
    @JsonKey(name: 'size', includeIfNull: false) required int size,
  }) = _UserCommentsQuery;

  factory UserCommentsQuery.fromJson(Map<String, dynamic> json) =>
      _$UserCommentsQueryFromJson(json);
}

@freezed
abstract class AvatarScanQuery with _$AvatarScanQuery {
  const factory AvatarScanQuery({
    @JsonKey(name: 'domain') required String domain,
  }) = _AvatarScanQuery;

  factory AvatarScanQuery.fromJson(Map<String, dynamic> json) =>
      _$AvatarScanQueryFromJson(json);
}

@freezed
abstract class UserUpdateRequest with _$UserUpdateRequest {
  const factory UserUpdateRequest({
    @JsonKey(name: 'key') required String key,
    @JsonKey(name: 'value') required String value,
    @JsonKey(name: 'reason', includeIfNull: false) String? reason,
  }) = _UserUpdateRequest;

  factory UserUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$UserUpdateRequestFromJson(json);
}

@freezed
abstract class UserDeleteRequest with _$UserDeleteRequest {
  const factory UserDeleteRequest({
    @JsonKey(name: 'reason', includeIfNull: false) String? reason,
    @JsonKey(name: 'user_name') required String userName,
    @JsonKey(name: 'user_email') required String userEmail,
  }) = _UserDeleteRequest;

  factory UserDeleteRequest.fromJson(Map<String, dynamic> json) =>
      _$UserDeleteRequestFromJson(json);
}

@freezed
abstract class UserBatchBanRequest with _$UserBatchBanRequest {
  const factory UserBatchBanRequest({
    @JsonKey(name: 'ids') required List<String> ids,
    @JsonKey(name: 'key') required String key,
    @JsonKey(name: 'value') required String value,
    @JsonKey(name: 'reason', includeIfNull: false) String? reason,
  }) = _UserBatchBanRequest;

  factory UserBatchBanRequest.fromJson(Map<String, dynamic> json) =>
      _$UserBatchBanRequestFromJson(json);
}

@freezed
abstract class UserBatchDeleteRequest with _$UserBatchDeleteRequest {
  const factory UserBatchDeleteRequest({
    @JsonKey(name: 'items') required List<UserDeleteItem> items,
    @JsonKey(name: 'reason', includeIfNull: false) String? reason,
  }) = _UserBatchDeleteRequest;

  factory UserBatchDeleteRequest.fromJson(Map<String, dynamic> json) =>
      _$UserBatchDeleteRequestFromJson(json);
}

@freezed
abstract class AvatarReplaceRequest with _$AvatarReplaceRequest {
  const factory AvatarReplaceRequest({
    @JsonKey(name: 'domain') required String domain,
    @JsonKey(name: 'avatars') required List<String> avatars,
  }) = _AvatarReplaceRequest;

  factory AvatarReplaceRequest.fromJson(Map<String, dynamic> json) =>
      _$AvatarReplaceRequestFromJson(json);
}

@freezed
abstract class AvatarRestoreItem with _$AvatarRestoreItem {
  const factory AvatarRestoreItem({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'avatar') required String avatar,
  }) = _AvatarRestoreItem;

  factory AvatarRestoreItem.fromJson(Map<String, dynamic> json) =>
      _$AvatarRestoreItemFromJson(json);
}

@freezed
abstract class AvatarRestoreRequest with _$AvatarRestoreRequest {
  const factory AvatarRestoreRequest({
    @JsonKey(name: 'items') required List<AvatarRestoreItem> items,
  }) = _AvatarRestoreRequest;

  factory AvatarRestoreRequest.fromJson(Map<String, dynamic> json) =>
      _$AvatarRestoreRequestFromJson(json);
}

@freezed
abstract class AvatarScanResult with _$AvatarScanResult {
  const factory AvatarScanResult({
    @JsonKey(name: 'total') required int total,
    @JsonKey(name: 'items') required List<AvatarScanUser> items,
  }) = _AvatarScanResult;

  factory AvatarScanResult.fromJson(Map<String, dynamic> json) =>
      _$AvatarScanResultFromJson(json);
}

@freezed
abstract class AvatarReplaceResult with _$AvatarReplaceResult {
  const factory AvatarReplaceResult({
    @JsonKey(name: 'replaced') required int replaced,
  }) = _AvatarReplaceResult;

  factory AvatarReplaceResult.fromJson(Map<String, dynamic> json) =>
      _$AvatarReplaceResultFromJson(json);
}

@freezed
abstract class AvatarRestoreResult with _$AvatarRestoreResult {
  const factory AvatarRestoreResult({
    @JsonKey(name: 'restored') required int restored,
    @JsonKey(name: 'skipped') required int skipped,
    @JsonKey(name: 'total') required int total,
  }) = _AvatarRestoreResult;

  factory AvatarRestoreResult.fromJson(Map<String, dynamic> json) =>
      _$AvatarRestoreResultFromJson(json);
}
