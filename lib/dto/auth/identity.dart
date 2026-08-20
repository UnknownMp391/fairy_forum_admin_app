import 'package:freezed_annotation/freezed_annotation.dart';

part 'identity.freezed.dart';
part 'identity.g.dart';

@freezed
abstract class IdentityData with _$IdentityData {
  const factory IdentityData({
    required String adminId,
    required String adminToken,
    String? adminKey,
    String? role,
  }) = _IdentityData;
}

@freezed
abstract class LoginResult with _$LoginResult {
  const factory LoginResult({
    @JsonKey(name: 'token') required String token,
    @JsonKey(name: 'role') String? role,
    @JsonKey(name: 'expiresAt') DateTime? expiresAt,
  }) = _LoginResult;

  factory LoginResult.fromJson(Map<String, dynamic> json) =>
      _$LoginResultFromJson(json);
}
