import "package:certimate/api/error_interceptor.dart";
import "package:certimate/logger/logger.dart";
import "package:dio/dio.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:talker_dio_logger/talker_dio_logger_interceptor.dart";
import "package:talker_dio_logger/talker_dio_logger_settings.dart";

part "http.freezed.dart";
part "http.g.dart";

@Riverpod(keepAlive: true)
Dio dio(Ref ref) => Dio()
  ..interceptors.addAll([
    TalkerDioLogger(
      talker: Logger.getLogger(),
      settings: const TalkerDioLoggerSettings(
        printRequestHeaders: true,
        printResponseHeaders: true,
        printResponseTime: true,
      ),
    ),
    ErrorInterceptor(ref),
  ]);

@Freezed(genericArgumentFactories: true)
abstract class ApiResult<T> with _$ApiResult<T> {
  const factory ApiResult({
    @Default(0) int code,
    required T data,
    @Default("") String msg,
  }) = _ApiResult;

  factory ApiResult.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$ApiResultFromJson(json, fromJsonT);
}

@Freezed(genericArgumentFactories: true)
abstract class ApiPageResult<T> with _$ApiPageResult<T> {
  const factory ApiPageResult({
    @Default(0) int page,
    @Default(0) int perPage,
    @Default(0) int totalItems,
    @Default(0) int totalPages,
    @Default([]) List<T> items,
  }) = _ApiPageResult;

  factory ApiPageResult.fromJson(
    Map<String, Object?> json,
    T Function(Object?) fromJsonT,
  ) => _$ApiPageResultFromJson(json, fromJsonT);
}

const dateTimeConverter = DateTimeConverter();

class DateTimeConverter implements JsonConverter<DateTime?, dynamic> {
  const DateTimeConverter();

  @override
  @dateTimeConverter
  DateTime? fromJson(dynamic json) =>
      json is String ? DateTime.tryParse(json) : null;

  @override
  dynamic toJson(@dateTimeConverter DateTime? object) =>
      object?.toIso8601String();
}
