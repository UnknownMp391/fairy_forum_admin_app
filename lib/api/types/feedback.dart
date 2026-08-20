import 'package:freezed_annotation/freezed_annotation.dart';

part 'feedback.freezed.dart';
part 'feedback.g.dart';

@freezed
abstract class FeedbackStatusChange with _$FeedbackStatusChange {
  const factory FeedbackStatusChange({
    @JsonKey(name: 'fromStatus') String? fromStatus,
    @JsonKey(name: 'toStatus') String? toStatus,
    @JsonKey(name: 'handlerId') String? handlerId,
    @JsonKey(name: 'note', includeIfNull: false) String? note,
    @JsonKey(name: 'createdAt') DateTime? createdAt,
  }) = _FeedbackStatusChange;

  factory FeedbackStatusChange.fromJson(Map<String, dynamic> json) =>
      _$FeedbackStatusChangeFromJson(json);
}

@freezed
abstract class FeedbackItem with _$FeedbackItem {
  const factory FeedbackItem({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'type') String? type,
    @JsonKey(name: 'title') String? title,
    @JsonKey(name: 'content') String? content,
    @JsonKey(name: 'attachmentIds') List<String>? attachmentIds,
    @JsonKey(name: 'reporterId') String? reporterId,
    @JsonKey(name: 'status') String? status,
    @JsonKey(name: 'handlerId') String? handlerId,
    @JsonKey(name: 'statusHistory') List<FeedbackStatusChange>? statusHistory,
    @JsonKey(name: 'createdAt') DateTime? createdAt,
    @JsonKey(name: 'updatedAt') DateTime? updatedAt,
  }) = _FeedbackItem;

  factory FeedbackItem.fromJson(Map<String, dynamic> json) =>
      _$FeedbackItemFromJson(json);
}

const feedbackTypes = ['bug', 'suggestion', 'experience', 'security', 'other'];

const feedbackStatuses = ['pending', 'done', 'rejected', 'closed'];

const feedbackStatusLabels = {
  'pending': '待处理',
  'done': '已完成',
  'rejected': '已拒绝',
  'closed': '已关闭',
};

String feedbackStatusLabel(String? status) =>
    feedbackStatusLabels[status] ?? status ?? '未知';

@freezed
abstract class FeedbackQuery with _$FeedbackQuery {
  const factory FeedbackQuery({
    @JsonKey(name: 'page', includeIfNull: false) required int page,
    @JsonKey(name: 'size', includeIfNull: false) required int size,
    @JsonKey(name: 'status', includeIfNull: false) String? status,
  }) = _FeedbackQuery;

  factory FeedbackQuery.fromJson(Map<String, dynamic> json) =>
      _$FeedbackQueryFromJson(json);
}

@freezed
abstract class FeedbackChangelogQuery with _$FeedbackChangelogQuery {
  const factory FeedbackChangelogQuery({
    @JsonKey(name: 'handler_id', includeIfNull: false) String? handlerId,
    @JsonKey(name: 'to_status', includeIfNull: false) String? toStatus,
    @JsonKey(name: 'feedback_id', includeIfNull: false) String? feedbackId,
  }) = _FeedbackChangelogQuery;

  factory FeedbackChangelogQuery.fromJson(Map<String, dynamic> json) =>
      _$FeedbackChangelogQueryFromJson(json);
}

@freezed
abstract class FeedbackCreateRequest with _$FeedbackCreateRequest {
  const factory FeedbackCreateRequest({
    @JsonKey(name: 'type') required String type,
    @JsonKey(name: 'title') required String title,
    @JsonKey(name: 'content') required String content,
  }) = _FeedbackCreateRequest;

  factory FeedbackCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$FeedbackCreateRequestFromJson(json);
}

@freezed
abstract class FeedbackStatusUpdateRequest with _$FeedbackStatusUpdateRequest {
  const factory FeedbackStatusUpdateRequest({
    @JsonKey(name: 'status') required String status,
    @JsonKey(name: 'note', includeIfNull: false) String? note,
  }) = _FeedbackStatusUpdateRequest;

  factory FeedbackStatusUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$FeedbackStatusUpdateRequestFromJson(json);
}

@freezed
abstract class BatchFeedbackStatusRequest with _$BatchFeedbackStatusRequest {
  const factory BatchFeedbackStatusRequest({
    @JsonKey(name: 'ids') required List<String> ids,
    @JsonKey(name: 'status') required String status,
    @JsonKey(name: 'note', includeIfNull: false) String? note,
  }) = _BatchFeedbackStatusRequest;

  factory BatchFeedbackStatusRequest.fromJson(Map<String, dynamic> json) =>
      _$BatchFeedbackStatusRequestFromJson(json);
}

@freezed
abstract class FeedbackAttachmentResult with _$FeedbackAttachmentResult {
  const factory FeedbackAttachmentResult({
    @JsonKey(name: 'attachmentId') String? attachmentId,
    @JsonKey(name: 'filename') String? filename,
  }) = _FeedbackAttachmentResult;

  factory FeedbackAttachmentResult.fromJson(Map<String, dynamic> json) =>
      _$FeedbackAttachmentResultFromJson(json);
}
