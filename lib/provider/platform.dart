import "package:collection/collection.dart";
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
    return TargetPlatform.values.firstWhereOrNull(
      (theme) => theme.name == themeValue,
    );
  }

  void update(TargetPlatform platform) {
    state = platform;
    SpUtil.putString(cacheKey, platform.name);
  }
}
