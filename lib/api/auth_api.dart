import "package:certimate/api/http.dart";
import "package:certimate/database/servers_dao.dart";
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
    String password, {
    bool retryRequest = false,
  }) async {
    final response = await dio.post(
      "$host/api/collections/_superusers/auth-with-password",
      data: {"identity": username, "password": password},
      options: retryRequest ? Options(extra: {"retryRequest": 1}) : null,
    );
    return AuthResult.fromJson(response.data);
  }

  Future<void> updatePassword(
    ServerModel server, {
    required String userId,
    required String password,
    required String passwordConfirm,
  }) async {
    await dio.patch(
      "${server.host}/api/collections/_superusers/records/$userId",
      data: {"passwordConfirm": passwordConfirm, "password": password},
      options: server.getOptions(),
    );
  }

  Future<void> updateEmail(
    ServerModel server, {
    required String userId,
    required String email,
  }) async {
    await dio.patch(
      "${server.host}/api/collections/_superusers/records/$userId",
      data: {"email": email},
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
