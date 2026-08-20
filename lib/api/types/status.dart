import 'package:freezed_annotation/freezed_annotation.dart';

part 'status.freezed.dart';
part 'status.g.dart';

@freezed
abstract class ForumStatus with _$ForumStatus {
  const factory ForumStatus({
    @JsonKey(name: 'banned_users') required int userBannedCount,
    @JsonKey(name: 'comments') required int commentCount,
    @JsonKey(name: 'pending_reports') required int pendingReportCount,
    @JsonKey(name: 'posts') required int postCount,
    @JsonKey(name: 'users') required int userCount,
    @JsonKey(name: 'deleted_posts') required int deletedPostCount,
    @JsonKey(name: 'deleted_comments') required int deletedCommentCount,
  }) = _ForumStatus;

  factory ForumStatus.fromJson(Map<String, dynamic> json) =>
      _$ForumStatusFromJson(json);
}
