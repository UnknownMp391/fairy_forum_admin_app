import 'package:freezed_annotation/freezed_annotation.dart';

part 'identity.freezed.dart';

@freezed
abstract class IdentityData with _$IdentityData {
  const factory IdentityData({
    required String adminId,
    required String adminToken,
  }) = _IdentityData;
}
