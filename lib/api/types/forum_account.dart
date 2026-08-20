import 'package:freezed_annotation/freezed_annotation.dart';

part 'forum_account.freezed.dart';
part 'forum_account.g.dart';

@freezed
abstract class ForumAccountStatus with _$ForumAccountStatus {
  const factory ForumAccountStatus({
    @JsonKey(name: 'bound') bool? bound,
    @JsonKey(name: 'forum_user_id') String? forumUserId,
    @JsonKey(name: 'forum_user_name') String? forumUserName,
    @JsonKey(name: 'forum_user_avatar') String? forumUserAvatar,
  }) = _ForumAccountStatus;

  factory ForumAccountStatus.fromJson(Map<String, dynamic> json) =>
      _$ForumAccountStatusFromJson(json);
}

@freezed
abstract class ForumAccountBindRequest with _$ForumAccountBindRequest {
  const factory ForumAccountBindRequest({
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'password') required String password,
  }) = _ForumAccountBindRequest;

  factory ForumAccountBindRequest.fromJson(Map<String, dynamic> json) =>
      _$ForumAccountBindRequestFromJson(json);
}
