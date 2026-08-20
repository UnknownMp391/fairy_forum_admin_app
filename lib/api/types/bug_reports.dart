import 'package:freezed_annotation/freezed_annotation.dart';

part 'bug_reports.freezed.dart';
part 'bug_reports.g.dart';

@freezed
abstract class BugReport with _$BugReport {
  const factory BugReport({
    @JsonKey(name: 'id') required int id,
    @JsonKey(name: 'title') String? title,
    @JsonKey(name: 'detail') String? detail,
    @JsonKey(name: 'steps') String? steps,
    @JsonKey(name: 'contact') String? contact,
    @JsonKey(name: 'reporterId') String? reporterId,
    @JsonKey(name: 'reporterName') String? reporterName,
    @JsonKey(name: 'userAgent') String? userAgent,
    @JsonKey(name: 'pageUrl') String? pageUrl,
    @JsonKey(name: 'status') int? status,
    @JsonKey(name: 'createdAt') DateTime? createdAt,
  }) = _BugReport;

  factory BugReport.fromJson(Map<String, dynamic> json) =>
      _$BugReportFromJson(json);
}

@freezed
abstract class BugReportChangelogEntry with _$BugReportChangelogEntry {
  const factory BugReportChangelogEntry({
    @JsonKey(name: 'feedbackId') int? feedbackId,
    @JsonKey(name: 'feedbackTitle') String? feedbackTitle,
    @JsonKey(name: 'fromStatus') int? fromStatus,
    @JsonKey(name: 'toStatus') int? toStatus,
    @JsonKey(name: 'handlerId') String? handlerId,
    @JsonKey(name: 'note', includeIfNull: false) String? note,
    @JsonKey(name: 'createdAt') DateTime? createdAt,
  }) = _BugReportChangelogEntry;

  factory BugReportChangelogEntry.fromJson(Map<String, dynamic> json) =>
      _$BugReportChangelogEntryFromJson(json);
}

String bugReportStatusLabel(int? status) {
  switch (status) {
    case 0:
      return '待处理';
    case 1:
      return '已处理';
    default:
      return status?.toString() ?? '未知';
  }
}

@freezed
abstract class BugReportsQuery with _$BugReportsQuery {
  const factory BugReportsQuery({
    @JsonKey(name: 'page', includeIfNull: false) required int page,
    @JsonKey(name: 'size', includeIfNull: false) required int size,
    @JsonKey(name: 'status', includeIfNull: false) int? status,
    @JsonKey(name: 'search', includeIfNull: false) String? search,
  }) = _BugReportsQuery;

  factory BugReportsQuery.fromJson(Map<String, dynamic> json) =>
      _$BugReportsQueryFromJson(json);
}

@freezed
abstract class BugReportChangelogQuery with _$BugReportChangelogQuery {
  const factory BugReportChangelogQuery({
    @JsonKey(name: 'feedback_id', includeIfNull: false) int? feedbackId,
    @JsonKey(name: 'page', includeIfNull: false) required int page,
    @JsonKey(name: 'size', includeIfNull: false) required int size,
  }) = _BugReportChangelogQuery;

  factory BugReportChangelogQuery.fromJson(Map<String, dynamic> json) =>
      _$BugReportChangelogQueryFromJson(json);
}

@freezed
abstract class BugReportCreateRequest with _$BugReportCreateRequest {
  const factory BugReportCreateRequest({
    @JsonKey(name: 'title') required String title,
    @JsonKey(name: 'detail') required String detail,
    @JsonKey(name: 'steps') required String steps,
    @JsonKey(name: 'contact') required String contact,
  }) = _BugReportCreateRequest;

  factory BugReportCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$BugReportCreateRequestFromJson(json);
}

@freezed
abstract class BugReportStatusUpdateRequest
    with _$BugReportStatusUpdateRequest {
  const factory BugReportStatusUpdateRequest({
    @JsonKey(name: 'status') required int status,
    @JsonKey(name: 'note', includeIfNull: false) String? note,
  }) = _BugReportStatusUpdateRequest;

  factory BugReportStatusUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$BugReportStatusUpdateRequestFromJson(json);
}

@freezed
abstract class BatchBugReportStatusRequest with _$BatchBugReportStatusRequest {
  const factory BatchBugReportStatusRequest({
    @JsonKey(name: 'ids') required List<String> ids,
    @JsonKey(name: 'status') required int status,
    @JsonKey(name: 'note', includeIfNull: false) String? note,
  }) = _BatchBugReportStatusRequest;

  factory BatchBugReportStatusRequest.fromJson(Map<String, dynamic> json) =>
      _$BatchBugReportStatusRequestFromJson(json);
}
