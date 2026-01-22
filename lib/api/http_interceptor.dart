import "dart:async";
import "dart:io";

import "package:adaptive_dialog/adaptive_dialog.dart";
import "package:certimate/api/auth_api.dart";
import "package:certimate/api/http.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/pages/server/provider.dart";
import "package:certimate/provider/security.dart";
import "package:dio/dio.dart";
import "package:flutter_smart_dialog/flutter_smart_dialog.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:safemap/safemap.dart";

part "http_interceptor.g.dart";

@Riverpod(keepAlive: true)
class RefreshTokenCompleter extends _$RefreshTokenCompleter {
  @override
  Completer<String>? build(int serverId) => null;

  void updateCompleter(Completer<String>? completer) {
    state = completer;
  }
}

@Riverpod(keepAlive: true)
class InputAccountCompleter extends _$InputAccountCompleter {
  @override
  Completer<List<String>>? build(int serverId) => null;

  void updateCompleter(Completer<List<String>>? completer) {
    state = completer;
  }
}

class ApiError {
  final int code;

  ApiError({required this.code});

  @override
  String toString() {
    return "api error code $code";
  }
}

class HttpInterceptor extends Interceptor {
  final Ref ref;

  const HttpInterceptor(this.ref);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final serverId = options.extra["serverId"];
    if (serverId is int) {
      final needsBaseUrl = options.baseUrl.isEmpty;
      final authorization = options.headers["Authorization"];
      final needsAuth =
          options.headers["skipAuth"] == null &&
          (authorization == null || authorization == "");
      if (needsBaseUrl || needsAuth) {
        final server = await ref.read(serverProvider(serverId).future);
        if (server == null) {
          handler.next(options);
          return;
        }
        if (needsBaseUrl) {
          options.baseUrl = server.host;
        }
        if (needsAuth) {
          options.headers["Authorization"] = server.token;
        }
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = SafeMap(response.data);
    final code = data["code"].toInt;
    // 判断状态码
    if (code != null && code != 0) {
      final message = data["msg"].string;
      final error = ApiError(code: code);
      final apiError = DioException(
        error: error,
        requestOptions: response.requestOptions,
        message: message == null || message.isEmpty
            ? error.toString()
            : message,
        response: response,
      );
      // 返回错误，继续往下执行拦截器
      return handler.reject(apiError, true);
    }
    // 请求成功
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        err.requestOptions.extra["retryRequest"] == null) {
      final serverId = err.requestOptions.extra["serverId"];
      if (serverId is int) {
        final server = await ref.read(serverProvider(serverId).future);
        if (server != null) {
          final passwordId = server.passwordId;
          String password = "";
          if (passwordId.isNotEmpty) {
            password = (await secureStorage.read(key: passwordId)) ?? "";
          }
          final newTokenInfo = await _getNewToken(
            serverId,
            server.username,
            password,
            inputAccount: password.isEmpty || server.username.isEmpty,
          );
          if (newTokenInfo != null) {
            if (passwordId.isNotEmpty &&
                newTokenInfo.password.isNotEmpty &&
                newTokenInfo.password != password) {
              // 保存最新密码
              secureStorage.write(
                key: passwordId,
                value: newTokenInfo.password,
              );
            }
            await ref
                .read(serverProvider(serverId).notifier)
                .updateServer(
                  server.copyWith(
                    token: newTokenInfo.token,
                    username: newTokenInfo.username,
                  ),
                  syncDatabase: true,
                );
            try {
              final retryResponse = await _retryRequest(
                err.requestOptions,
                newTokenInfo.token,
              );
              handler.resolve(retryResponse);
            } catch (retryError, stackTrace) {
              if (retryError is DioException) {
                handler.reject(retryError);
              } else {
                handler.reject(
                  DioException(
                    requestOptions: err.requestOptions,
                    error: retryError,
                    stackTrace: stackTrace,
                    message: retryError.toString(),
                  ),
                );
              }
            }
            return;
          }
        }
      }
    }
    String? errMsg = err.message;
    if (err.error is ApiError) {
      // api error
      handler.reject(err);
    } else {
      // http error
      final apiErrMsg = SafeMap(err.response?.data)["message"].string;
      if (apiErrMsg.isNotEmptyOrNull) {
        errMsg = apiErrMsg;
      }
      if (errMsg.isEmptyOrNull) {
        errMsg = _getErrorMsg(err.error);
      }
      handler.reject(
        errMsg != err.message ? err.copyWith(message: errMsg) : err,
      );
    }
    if (err.requestOptions.method.toLowerCase() != "get") {
      // 非 get 请求直接显示错误信息
      SmartDialog.showNotify(
        msg: errMsg ?? "operation failed!",
        notifyType: NotifyType.error,
      );
    }
  }

  String _getErrorMsg(Object? err) {
    if (err == null) {
      return "err is null";
    }
    if (err is TlsException) {
      return err.message;
    }
    if (err is HttpException) {
      return err.message;
    }
    if (err is SocketException) {
      return err.message;
    }
    return "$err";
  }

  Future<_NewTokenInfo?> _getNewToken(
    int serverId,
    String username,
    String password, {
    inputAccount = false,
  }) async {
    if (inputAccount) {
      final accountInfo = await _inputAccount(serverId, username);
      if (accountInfo.isEmpty) {
        return null;
      }
      username = accountInfo[0];
      password = accountInfo[1];
    }
    try {
      final newToken = await _refreshToken(serverId, username, password);
      return _NewTokenInfo(
        token: newToken,
        username: username,
        password: password,
      );
    } catch (err) {
      if (!inputAccount &&
          err is DioException &&
          err.response?.statusCode == 400) {
        return _getNewToken(serverId, username, "", inputAccount: true);
      }
    }
    return null;
  }

  Future<String> _refreshToken(
    int serverId,
    String username,
    String password,
  ) async {
    final currentCompleter = ref.read(refreshTokenCompleterProvider(serverId));
    if (currentCompleter != null) {
      return currentCompleter.future;
    }
    final completer = Completer<String>();
    final completerNotifier = ref.read(
      refreshTokenCompleterProvider(serverId).notifier,
    );
    completerNotifier.updateCompleter(completer);
    try {
      final loginRes = await ref
          .read(authApiProvider)
          .loginByServer(serverId, username, password);
      final newToken = loginRes.token ?? "";
      completer.complete(newToken);
      completerNotifier.updateCompleter(null);
      return newToken;
    } catch (err) {
      completer.completeError(err);
      completerNotifier.updateCompleter(null);
      rethrow;
    }
  }

  Future<List<String>> _inputAccount(int serverId, String username) async {
    final currentCompleter = ref.read(inputAccountCompleterProvider(serverId));
    if (currentCompleter != null) {
      return currentCompleter.future;
    }
    final completer = Completer<List<String>>();
    final completerNotifier = ref.read(
      inputAccountCompleterProvider(serverId).notifier,
    );
    completerNotifier.updateCompleter(completer);
    try {
      final tag = "refreshTokenInputAccount:$serverId";
      final accountInfo =
          (await SmartDialog.show<List<String>?>(
            tag: tag,
            clickMaskDismiss: false,
            builder: (context) {
              final s = context.s;
              return buildTextInputDialog(
                context: context,
                title: s.loginInvalid.capitalCase,
                message: s.pleaseEnterAccountInfo,
                textFields: [
                  DialogTextField(initialText: username, hintText: s.username),
                  DialogTextField(obscureText: true, hintText: s.password),
                ],
                onCancel: () => SmartDialog.dismiss(tag: tag),
                onSubmit: (values) {
                  if (values[0].isNotEmpty != true) {
                    SmartDialog.showToast(s.pleaseEnter(s.username));
                    return;
                  }
                  if (values[1].isNotEmpty != true) {
                    SmartDialog.showToast(s.pleaseEnter(s.password));
                    return;
                  }
                  SmartDialog.dismiss(tag: tag, result: values);
                },
              );
            },
          )) ??
          [];
      completer.complete(accountInfo);
      completerNotifier.updateCompleter(null);
      return accountInfo;
    } catch (err) {
      completer.completeError(err);
      completerNotifier.updateCompleter(null);
      rethrow;
    }
  }

  Future<Response> _retryRequest(
    RequestOptions requestOptions,
    String newToken,
  ) async {
    return ref
        .read(dioProvider)
        .request(
          requestOptions.path,
          data: requestOptions.data,
          queryParameters: requestOptions.queryParameters,
          cancelToken: requestOptions.cancelToken,
          onSendProgress: requestOptions.onSendProgress,
          onReceiveProgress: requestOptions.onReceiveProgress,
          options: Options(
            method: requestOptions.method,
            sendTimeout: requestOptions.sendTimeout,
            receiveTimeout: requestOptions.receiveTimeout,
            extra: requestOptions.extra..addAll({"retryRequest": 1}),
            headers: requestOptions.headers
              ..addAll({"Authorization": newToken}),
            responseType: requestOptions.responseType,
            preserveHeaderCase: requestOptions.preserveHeaderCase,
            contentType: requestOptions.contentType,
            validateStatus: requestOptions.validateStatus,
            receiveDataWhenStatusError:
                requestOptions.receiveDataWhenStatusError,
            followRedirects: requestOptions.followRedirects,
            maxRedirects: requestOptions.maxRedirects,
            persistentConnection: requestOptions.persistentConnection,
            requestEncoder: requestOptions.requestEncoder,
            responseDecoder: requestOptions.responseDecoder,
            listFormat: requestOptions.listFormat,
          ),
        );
  }
}

class _NewTokenInfo {
  final String token;
  final String username;
  final String password;

  _NewTokenInfo({
    required this.token,
    required this.username,
    required this.password,
  });
}
