import 'package:freezed_annotation/freezed_annotation.dart';

part 'batch.freezed.dart';
part 'batch.g.dart';

@freezed
abstract class BatchResult with _$BatchResult {
  const factory BatchResult({
    @JsonKey(name: 'status') required Map<String, bool> status,
  }) = _BatchResult;

  const BatchResult._();

  factory BatchResult.fromJson(Map<String, dynamic> json) =>
      _$BatchResultFromJson(json);

  int get successCount => status.values.where((ok) => ok).length;

  int get failedCount => status.values.where((ok) => !ok).length;

  List<String> get failedIds =>
      status.entries.where((entry) => !entry.value).map((e) => e.key).toList();
}

@freezed
abstract class IdsRequest with _$IdsRequest {
  const factory IdsRequest({@JsonKey(name: 'ids') required List<String> ids}) =
      _IdsRequest;

  factory IdsRequest.fromJson(Map<String, dynamic> json) =>
      _$IdsRequestFromJson(json);
}

@freezed
abstract class IdsReasonRequest with _$IdsReasonRequest {
  const factory IdsReasonRequest({
    @JsonKey(name: 'ids') required List<String> ids,
    @JsonKey(name: 'reason', includeIfNull: false) String? reason,
  }) = _IdsReasonRequest;

  factory IdsReasonRequest.fromJson(Map<String, dynamic> json) =>
      _$IdsReasonRequestFromJson(json);
}
