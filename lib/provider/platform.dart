import "package:certimate/extension/index.dart";
import "package:device_wrapper/device_wrapper.dart";
import "package:flutter/foundation.dart";
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
      orElse: () => RunPlatform.isIOS || RunPlatform.isMacOS
          ? TargetPlatform.iOS
          : TargetPlatform.android,
    );
  }

  void update(TargetPlatform platform) {
    state = platform;
    SpUtil.putString(cacheKey, platform.name);
  }
}

@Riverpod(keepAlive: true)
class DeviceModeNotifier extends _$DeviceModeNotifier {
  final String cacheKey = "device_mode";

  @override
  DeviceConfig build() {
    final modeName = SpUtil.getString(cacheKey, defValue: "");
    deviceMode = deviceList.firstWhere(
      (mode) => mode.name == modeName,
      orElse: () => deviceMode,
    );
    return deviceMode;
  }

  void update(DeviceConfig model) {
    deviceMode = model;
    state = model;
    SpUtil.putString(cacheKey, model.name);
  }
}
