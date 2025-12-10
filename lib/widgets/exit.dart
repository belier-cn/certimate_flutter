import "dart:io";

import "package:certimate/extension/index.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_smart_dialog/flutter_smart_dialog.dart";

class ExitInterceptor extends StatefulWidget {
  final Widget child;

  const ExitInterceptor({super.key, required this.child});

  @override
  ExitInterceptorState createState() => ExitInterceptorState();
}

class ExitInterceptorState extends State<ExitInterceptor> {
  // 上次点击时间
  DateTime? _lastPressedAt;

  // 两次点击时间间隔
  final Duration _duration = const Duration(milliseconds: 3000);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 拦截只针对 Android
      canPop: !kIsWeb && RunPlatform.isAndroid ? false : true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        final navigator = Navigator.of(context);
        final canPop = navigator.canPop();
        if (canPop) {
          // 有上一页，就正常返回上一页
          navigator.pop();
        } else {
          if (_lastPressedAt == null ||
              DateTime.now().difference(_lastPressedAt!) > _duration) {
            SmartDialog.showToast(context.s.exitTip, displayTime: _duration);
            _lastPressedAt = DateTime.now();
            return;
          }
          // 两次后强制退出
          if (RunPlatform.isIOS) {
            exit(0);
          } else {
            SystemNavigator.pop();
          }
        }
      },
      child: widget.child,
    );
  }
}
