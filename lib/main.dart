import "package:certimate/app.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/provider/device.dart";
import "package:certimate/provider/package.dart";
import "package:certimate/provider/security.dart";
import "package:certimate/theme/theme.dart";
import "package:certimate/web/index.dart" as web;
import "package:device_info_plus/device_info_plus.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_native_splash/flutter_native_splash.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:local_auth/local_auth.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:sp_util/sp_util.dart";
import "package:window_manager/window_manager.dart";

void main() {
  init().then((res) {
    if (RunPlatform.isAndroid || RunPlatform.isIOS) {
      FlutterNativeSplash.remove();
    }
    runApp(
      ProviderScope(
        overrides: [
          packageInfoProvider.overrideWithValue(res.$1),
          deviceInfoProvider.overrideWithValue(res.$2),
          biometricsProvider.overrideWithValue(res.$3),
        ],
        child: const App(),
        retry: (retryCount, error) => null,
      ),
    );
  });
}

Future<(PackageInfo, BaseDeviceInfo, List<BiometricType>)> init() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  if (RunPlatform.isAndroid || RunPlatform.isIOS) {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  }
  final baseDeviceInfo = await DeviceInfoPlugin().deviceInfo;
  if (kIsWeb) {
    web.usePathUrlStrategy();
  } else if (RunPlatform.isDesktop) {
    await windowManager.ensureInitialized();
    final windowOptions = const WindowOptions(
      size: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  } else {
    if (RunPlatform.isAndroid || RunPlatform.isOhos) {
      // 配置状态栏和虚拟按钮主题
      SystemChrome.setSystemUIOverlayStyle(lightSystemUiOverlayStyle);
      // 导航栏设置，开启全面屏（安卓10开始支持）
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    if (RunPlatform.isAndroid ||
        RunPlatform.isOhos ||
        (RunPlatform.isIOS &&
            (IosDeviceInfo.fromMap(
              baseDeviceInfo.data,
            )).systemName.contains("iOS"))) {
      // 强制竖屏
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }
  await SpUtil.getInstance();
  return (
    await PackageInfo.fromPlatform(),
    baseDeviceInfo,
    await getAvailableBiometrics(),
  );
}
