import "dart:io";

import "package:flutter/material.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:sp_util/sp_util.dart";

part "platform.g.dart";

@Riverpod(keepAlive: true)
class TargetPlatformNotifier extends _$TargetPlatformNotifier {
  final String cacheKey = "target_platform";

  @override
  TargetPlatform? build() {
    final themeValue = SpUtil.getString(cacheKey, defValue: "");
    return TargetPlatform.values.firstWhere(
      (theme) => theme.name == themeValue,
      // 兼容 adaptive_dialog style 的判断
      orElse: () => Platform.isIOS || Platform.isMacOS
          ? TargetPlatform.iOS
          : TargetPlatform.android,
    );
  }

  void update(TargetPlatform platform) {
    state = platform;
    SpUtil.putString(cacheKey, platform.name);
  }
}
