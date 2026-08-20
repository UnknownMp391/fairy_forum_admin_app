import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';

@freezed
abstract class ManagementUserDetailPageExtra
    with _$ManagementUserDetailPageExtra {
  const factory ManagementUserDetailPageExtra({
    String? name,
    String? avatarUrl,
    int? age,
    String? bio,
    DateTime? createdAt,
    String? email,
    String? gender,
    bool? isBanned,
    Object? heroTag,
  }) = _ManagementUserDetailPageExtra;
}
