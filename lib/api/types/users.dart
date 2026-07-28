import 'package:fairy_forum_admin_app/utils/converter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'users.freezed.dart';
part 'users.g.dart';

bool userListIsBannedFromJson(int data) => nonZeroIntBoolFromJson(data);
int userListIsBannedToJson(bool data) => nonZeroIntBoolToJson(data);

@freezed
abstract class UserListItem with _$UserListItem {
  const factory UserListItem({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'created_at') required DateTime createdAt,

    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'email') required String email,
    @JsonKey(name: 'avatar') required String avatarUrl,
    @JsonKey(name: 'intro') required String bio,
    @JsonKey(name: 'age') required int age,
    @JsonKey(name: 'gender') required int gender,

    @JsonKey(
      name: 'is_banned',
      fromJson: userListIsBannedFromJson,
      toJson: userListIsBannedToJson,
    )
    required bool isBanned,
  }) = _UserListItem;

  factory UserListItem.fromJson(Map<String, dynamic> json) =>
      _$UserListItemFromJson(json);
}
