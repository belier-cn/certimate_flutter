import "package:certimate/extension/platform.dart";
import "package:certimate/provider/device.dart";
import "package:certimate/provider/language.dart";
import "package:device_info_plus/device_info_plus.dart";
import "package:flutter/material.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:upgrader/upgrader.dart";
import "package:version/version.dart";

part "upgrader.g.dart";

final upgraderKey = GlobalKey<UpgradeAlertState>();

@Riverpod(keepAlive: true)
class UpgraderProvider extends _$UpgraderProvider {
  @override
  Upgrader build() {
    final deviceInfo = ref.read(deviceInfoProvider);
    final language = ref.watch(languageProvider);
    final osVersion = getCurrentOSVersion(deviceInfo);
    final upgraderStore = UpgraderAppcastStore(
      appcastURL: "https://belier-cn.github.io/certimate_flutter/appcast.xml",
      osVersion: osVersion,
    );
    return Upgrader(
      debugLogging: true,
      messages: MyUpgraderMessages(code: language?.languageCode),
      upgraderOS: MyUpgraderOS(),
      storeController: UpgraderStoreController(
        oniOS: () => upgraderStore,
        onAndroid: () => upgraderStore,
        onMacOS: () => upgraderStore,
        onWindows: () => upgraderStore,
        onLinux: () => upgraderStore,
      ),
    );
  }

  Version getCurrentOSVersion(BaseDeviceInfo? devicInfo) {
    final osVersionString = getOsVersionString(devicInfo);
    try {
      return osVersionString?.isNotEmpty == true
          ? Version.parse(osVersionString!)
          : Version(0, 0, 0);
    } catch (e) {
      return Version(0, 0, 0);
    }
  }

  String? getOsVersionString(BaseDeviceInfo? devicInfo) {
    if (devicInfo == null) {
      return null;
    }
    if (RunPlatform.isAndroid) {
      return AndroidDeviceInfo.fromMap(devicInfo.data).version.baseOS;
    } else if (RunPlatform.isOhos) {
      final osFullName = devicInfo.data["osFullName"];
      return osFullName is String ? osFullName : null;
    } else if (RunPlatform.isIOS) {
      return IosDeviceInfo.fromMap(devicInfo.data).systemVersion;
    } else if (RunPlatform.isLinux) {
      return (devicInfo as LinuxDeviceInfo).version;
    } else if (RunPlatform.isMacOS) {
      final release = MacOsDeviceInfo.fromMap(devicInfo.data).osRelease;
      // For macOS the release string looks like: Version 13.2.1 (Build 22D68)
      // We need to parse out the actual OS version number.
      final regExpSource = r"[\w]*[\s]*(?<version>[^\s]+)";
      final regExp = RegExp(regExpSource, caseSensitive: false);
      final match = regExp.firstMatch(release);
      final version = match?.namedGroup("version");
      return version;
    } else if (RunPlatform.isWindows) {
      return (devicInfo as WindowsDeviceInfo).displayVersion;
    }
    return null;
  }
}

class MyUpgraderOS extends UpgraderOS {
  @override
  String get current {
    return RunPlatform.isOhos ? "ohos" : super.current;
  }
}

class MyUpgraderMessages extends UpgraderMessages {
  MyUpgraderMessages({super.code});

  @override
  String? message(UpgraderMessage messageKey) {
    if (languageCode == "zh") {
      if (messageKey == UpgraderMessage.releaseNotes) {
        return "更新内容";
      }
      if (messageKey == UpgraderMessage.buttonTitleIgnore) {
        return "忽略这个版本";
      }
    }
    return super.message(messageKey);
  }
}
