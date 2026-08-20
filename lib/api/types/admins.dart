import 'package:freezed_annotation/freezed_annotation.dart';

part 'admins.freezed.dart';
part 'admins.g.dart';

@freezed
abstract class AdminInfo with _$AdminInfo {
  const factory AdminInfo({
    @JsonKey(name: 'admin_id') required String adminId,
    @JsonKey(name: 'role', includeIfNull: false) String? role,
    @JsonKey(name: 'ups_id', includeIfNull: false) String? upsId,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'last_login_time') DateTime? lastLoginTime,
  }) = _AdminInfo;

  factory AdminInfo.fromJson(Map<String, dynamic> json) =>
      _$AdminInfoFromJson(json);
}

String adminRoleLabel(String? role) {
  if (role == 'superadmin') return '超级管理员';
  if (role == 'admin') return '管理员';
  return role ?? '未知';
}

@freezed
abstract class AdminCreateRequest with _$AdminCreateRequest {
  const factory AdminCreateRequest({
    @JsonKey(name: 'admin_id') required String adminId,
    @JsonKey(name: 'key') required String key,
    @JsonKey(name: 'role', includeIfNull: false) String? role,
  }) = _AdminCreateRequest;

  factory AdminCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$AdminCreateRequestFromJson(json);
}

@freezed
abstract class AdminRoleRequest with _$AdminRoleRequest {
  const factory AdminRoleRequest({
    @JsonKey(name: 'role') required String role,
  }) = _AdminRoleRequest;

  factory AdminRoleRequest.fromJson(Map<String, dynamic> json) =>
      _$AdminRoleRequestFromJson(json);
}

@freezed
abstract class AdminKeyRequest with _$AdminKeyRequest {
  const factory AdminKeyRequest({@JsonKey(name: 'key') required String key}) =
      _AdminKeyRequest;

  factory AdminKeyRequest.fromJson(Map<String, dynamic> json) =>
      _$AdminKeyRequestFromJson(json);
}

@freezed
abstract class AdminBatchRoleRequest with _$AdminBatchRoleRequest {
  const factory AdminBatchRoleRequest({
    @JsonKey(name: 'ids') required List<String> ids,
    @JsonKey(name: 'role') required String role,
  }) = _AdminBatchRoleRequest;

  factory AdminBatchRoleRequest.fromJson(Map<String, dynamic> json) =>
      _$AdminBatchRoleRequestFromJson(json);
}

@freezed
abstract class LocalAdminCreateRequest with _$LocalAdminCreateRequest {
  const factory LocalAdminCreateRequest({
    @JsonKey(name: 'admin_id') required String adminId,
    @JsonKey(name: 'password') required String password,
    @JsonKey(name: 'role', includeIfNull: false) String? role,
  }) = _LocalAdminCreateRequest;

  factory LocalAdminCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$LocalAdminCreateRequestFromJson(json);
}

@freezed
abstract class LocalAdminUpdateRequest with _$LocalAdminUpdateRequest {
  const factory LocalAdminUpdateRequest({
    @JsonKey(name: 'role', includeIfNull: false) String? role,
    @JsonKey(name: 'password', includeIfNull: false) String? password,
    @JsonKey(name: 'ups_id', includeIfNull: false) String? upsId,
    @JsonKey(name: 'ups_token', includeIfNull: false) String? upsToken,
  }) = _LocalAdminUpdateRequest;

  factory LocalAdminUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$LocalAdminUpdateRequestFromJson(json);
}
