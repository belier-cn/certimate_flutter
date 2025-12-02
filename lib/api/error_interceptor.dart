import "dart:async";
import "dart:io";

import "package:adaptive_dialog/adaptive_dialog.dart";
import "package:certimate/api/auth_api.dart";
import "package:certimate/api/http.dart";
import "package:certimate/database/servers_dao.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/pages/server/provider.dart";
import "package:certimate/provider/security.dart";
import "package:dio/dio.dart";
import "package:flutter_smart_dialog/flutter_smart_dialog.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:safemap/safemap.dart";

part "error_interceptor.g.dart";

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

class ErrorInterceptor extends Interceptor {
  final Ref ref;

  const ErrorInterceptor(this.ref);

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
        final server = ref.read(serverProvider(serverId)).value!;
        final newServer = await _getNewTokenServer(
          server,
          inputAccount: server.passwordId.isEmpty,
        );
        if (newServer != null) {
          ref
              .read(serverProvider(server.id).notifier)
              .updateServer(newServer, syncDatabase: true);
          try {
            final retryResponse = await _retryRequest(
              err.requestOptions,
              newServer,
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

  Future<ServerModel?> _getNewTokenServer(
    ServerModel server, {
    inputAccount = false,
  }) async {
    if (inputAccount) {
      final accountInfo = await _inputAccount(server);
      // 保存最新密码
      await secureStorage.write(key: server.passwordId, value: accountInfo[1]);
      if (accountInfo.isNotEmpty) {
        server = server.copyWith(username: accountInfo[0]);
      } else {
        return null;
      }
    }
    try {
      final newToken = await _refreshToken(server);
      return server.copyWith(token: newToken);
    } catch (err) {
      if (!inputAccount &&
          err is DioException &&
          err.response?.statusCode == 400) {
        return _getNewTokenServer(server, inputAccount: true);
      }
    }
    return null;
  }

  Future<String> _refreshToken(ServerModel server) async {
    final currentCompleter = ref.read(refreshTokenCompleterProvider(server.id));
    if (currentCompleter != null) {
      return currentCompleter.future;
    }
    final completer = Completer<String>();
    final completerNotifier = ref.read(
      refreshTokenCompleterProvider(server.id).notifier,
    );
    completerNotifier.updateCompleter(completer);
    try {
      final password = await secureStorage.read(key: server.passwordId);
      final loginRes = await ref
          .read(authApiProvider)
          .login(
            server.host,
            server.username,
            password ?? "",
            retryRequest: true,
          );
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

  Future<List<String>> _inputAccount(ServerModel server) async {
    final currentCompleter = ref.read(inputAccountCompleterProvider(server.id));
    if (currentCompleter != null) {
      return currentCompleter.future;
    }
    final completer = Completer<List<String>>();
    final completerNotifier = ref.read(
      inputAccountCompleterProvider(server.id).notifier,
    );
    completerNotifier.updateCompleter(completer);
    try {
      final tag = "refreshTokenInputAccount:${server.id}";
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
                  DialogTextField(
                    initialText: server.username,
                    hintText: s.username,
                  ),
                  DialogTextField(obscureText: true, hintText: s.password),
                ],
                onCancel: () => SmartDialog.dismiss(tag: tag),
                onSubmit: (values) =>
                    SmartDialog.dismiss(tag: tag, result: values),
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
    ServerModel newServer,
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
              ..addAll(newServer.getOptions().headers ?? {}),
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
