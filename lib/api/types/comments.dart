import 'package:freezed_annotation/freezed_annotation.dart';

part 'comments.freezed.dart';
part 'comments.g.dart';

@freezed
abstract class Comment with _$Comment {
  const factory Comment({
    @JsonKey(name: 'id') String? id,
    @JsonKey(name: 'post_id') String? postId,
    @JsonKey(name: 'user_id') String? userId,
    @JsonKey(name: 'content') String? content,
    @JsonKey(name: 'parent_id') String? parentId,
    @JsonKey(name: 'likes') int? likes,
    @JsonKey(name: 'status') int? status,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'user_name') String? userName,
    @JsonKey(name: 'user_avatar') String? userAvatar,
    @JsonKey(name: 'post_title') String? postTitle,
    @JsonKey(name: 'post_category') String? postCategory,
  }) = _Comment;

  factory Comment.fromJson(Map<String, dynamic> json) =>
      _$CommentFromJson(json);
}

@freezed
abstract class CommentsQuery with _$CommentsQuery {
  const factory CommentsQuery({
    @JsonKey(name: 'page', includeIfNull: false) required int page,
    @JsonKey(name: 'size', includeIfNull: false) required int size,
    @JsonKey(name: 'q', includeIfNull: false) String? q,
    @JsonKey(name: 'post_id', includeIfNull: false) String? postId,
  }) = _CommentsQuery;

  factory CommentsQuery.fromJson(Map<String, dynamic> json) =>
      _$CommentsQueryFromJson(json);
}

@freezed
abstract class CommentDeleteRequest with _$CommentDeleteRequest {
  const factory CommentDeleteRequest({
    @JsonKey(name: 'reason', includeIfNull: false) String? reason,
  }) = _CommentDeleteRequest;

  factory CommentDeleteRequest.fromJson(Map<String, dynamic> json) =>
      _$CommentDeleteRequestFromJson(json);
}
