import "package:device_wrapper/device_wrapper.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";

var deviceMode = DeviceConfig.mobile;

final deviceList = [
  DeviceConfig.mobile,
  DeviceConfig.tablet,
  DeviceConfig.desktop.copyWith(
    width: 800,
    height: 600,
    safePadding: EdgeInsets.zero,
  ),
];

abstract class RunPlatform {
  static bool get isDesktop => isMacOS || isWindows || isLinux;

  static bool get isDesktopUi =>
      (kIsWeb && deviceMode.mode == DeviceMode.desktop) ||
      (!kIsWeb && isDesktop);

  static bool get isPhone => isIOS || isAndroid || isOhos;

  static bool get isPhoneUi => !isDesktopUi;

  static bool get useShareDevice => isPhone || isMacOS;

  static bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;

  static bool get isOhos => defaultTargetPlatform.name == "ohos";

  static bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  static bool get isMacOS => defaultTargetPlatform == TargetPlatform.macOS;

  static bool get isWindows => defaultTargetPlatform == TargetPlatform.windows;

  static bool get isLinux => defaultTargetPlatform == TargetPlatform.linux;
}
