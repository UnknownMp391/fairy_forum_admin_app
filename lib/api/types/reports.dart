import 'package:freezed_annotation/freezed_annotation.dart';

part 'reports.freezed.dart';
part 'reports.g.dart';

@freezed
abstract class Report with _$Report {
  const factory Report({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'post_id') String? postId,
    @JsonKey(name: 'post_title') String? postTitle,
    @JsonKey(name: 'reporter_id') String? reporterId,
    @JsonKey(name: 'reporter_name') String? reporterName,
    @JsonKey(name: 'reason') String? reason,
    @JsonKey(name: 'detail') String? detail,
    @JsonKey(name: 'is_resolved') required bool isResolved,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Report;

  factory Report.fromJson(Map<String, dynamic> json) => _$ReportFromJson(json);
}

@freezed
abstract class ReportsQuery with _$ReportsQuery {
  const factory ReportsQuery({
    @JsonKey(name: 'page', includeIfNull: false) required int page,
    @JsonKey(name: 'size', includeIfNull: false) required int size,
    @JsonKey(name: 'is_resolved', includeIfNull: false) bool? isResolved,
  }) = _ReportsQuery;

  factory ReportsQuery.fromJson(Map<String, dynamic> json) =>
      _$ReportsQueryFromJson(json);
}

@freezed
abstract class ReportResolveRequest with _$ReportResolveRequest {
  const factory ReportResolveRequest({
    @JsonKey(name: 'is_resolved') required bool isResolved,
  }) = _ReportResolveRequest;

  factory ReportResolveRequest.fromJson(Map<String, dynamic> json) =>
      _$ReportResolveRequestFromJson(json);
}

@freezed
abstract class BatchResolveRequest with _$BatchResolveRequest {
  const factory BatchResolveRequest({
    @JsonKey(name: 'ids') required List<String> ids,
    @JsonKey(name: 'is_resolved') required bool isResolved,
  }) = _BatchResolveRequest;

  factory BatchResolveRequest.fromJson(Map<String, dynamic> json) =>
      _$BatchResolveRequestFromJson(json);
}
