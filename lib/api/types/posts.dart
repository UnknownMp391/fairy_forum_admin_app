import 'package:freezed_annotation/freezed_annotation.dart';

part 'posts.freezed.dart';
part 'posts.g.dart';

@freezed
abstract class PostDetail with _$PostDetail {
  const factory PostDetail({
    @JsonKey(name: 'id') String? id,
    @JsonKey(name: 'user_id') String? userId,
    @JsonKey(name: 'title') String? title,
    @JsonKey(name: 'content') String? content,
    @JsonKey(name: 'category') String? category,
    @JsonKey(name: 'likes') int? likes,
    @JsonKey(name: 'views') int? views,
    @JsonKey(name: 'status') int? status,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'user_name') String? userName,
    @JsonKey(name: 'user_avatar') String? userAvatar,
  }) = _PostDetail;

  factory PostDetail.fromJson(Map<String, dynamic> json) =>
      _$PostDetailFromJson(json);
}

@freezed
abstract class PostsQuery with _$PostsQuery {
  const factory PostsQuery({
    @JsonKey(name: 'page', includeIfNull: false) required int page,
    @JsonKey(name: 'size', includeIfNull: false) required int size,
    @JsonKey(name: 'category', includeIfNull: false) String? category,
    @JsonKey(name: 'q', includeIfNull: false) String? q,
  }) = _PostsQuery;

  factory PostsQuery.fromJson(Map<String, dynamic> json) =>
      _$PostsQueryFromJson(json);
}

@freezed
abstract class PostDeleteRequest with _$PostDeleteRequest {
  const factory PostDeleteRequest({
    @JsonKey(name: 'reason', includeIfNull: false) String? reason,
  }) = _PostDeleteRequest;

  factory PostDeleteRequest.fromJson(Map<String, dynamic> json) =>
      _$PostDeleteRequestFromJson(json);
}
