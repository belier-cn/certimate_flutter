import "package:certimate/api/http.dart";
import "package:dio/dio.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "auth_api.freezed.dart";
part "auth_api.g.dart";

@Riverpod(keepAlive: true)
AuthApi authApi(Ref ref) {
  final dio = ref.read(dioProvider);
  return AuthApi(dio: dio);
}

class AuthApi {
  final Dio dio;

  AuthApi({required this.dio});

  Future<AuthResult> login(
    String host,
    String username,
    String password,
  ) async {
    final response = await dio.post(
      "$host/api/collections/_superusers/auth-with-password",
      data: {"identity": username, "password": password},
      options: Options(extra: {"skipAuth": 1}),
    );
    return AuthResult.fromJson(response.data);
  }

  Future<AuthResult> loginByServer(
    int serverId,
    String username,
    String password,
  ) async {
    final response = await dio.post(
      "/api/collections/_superusers/auth-with-password",
      data: {"identity": username, "password": password},
      options: Options(
        extra: {"skipAuth": 1, "retryRequest": 1, "serverId": serverId},
      ),
    );
    return AuthResult.fromJson(response.data);
  }

  Future<void> updatePassword(
    int serverId, {
    required String userId,
    required String password,
    required String passwordConfirm,
    String? authorization,
  }) async {
    await dio.patch(
      "/api/collections/_superusers/records/$userId",
      data: {"passwordConfirm": passwordConfirm, "password": password},
      options: Options(
        extra: {"serverId": serverId},
        headers: authorization == null
            ? null
            : {"Authorization": authorization},
      ),
    );
  }

  Future<void> updateEmail(
    int serverId, {
    required String userId,
    required String email,
  }) async {
    await dio.patch(
      "/api/collections/_superusers/records/$userId",
      data: {"email": email},
      options: Options(extra: {"serverId": serverId}),
    );
  }
}

@freezed
abstract class AuthResult with _$AuthResult {
  factory AuthResult({String? token, AuthRecordResult? record}) = _AuthResult;

  factory AuthResult.fromJson(Map<String, dynamic> json) =>
      _$AuthResultFromJson(json);
}

@freezed
abstract class AuthRecordResult with _$AuthRecordResult {
  factory AuthRecordResult({String? id}) = _AuthRecordResult;

  factory AuthRecordResult.fromJson(Map<String, dynamic> json) =>
      _$AuthRecordResultFromJson(json);
}
