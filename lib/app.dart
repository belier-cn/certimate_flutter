import "package:certimate/extension/index.dart";
import "package:certimate/generated/l10n.dart";
import "package:certimate/provider/language.dart";
import "package:certimate/provider/local_certimate.dart";
import "package:certimate/provider/platform.dart";
import "package:certimate/provider/security.dart";
import "package:certimate/provider/theme.dart";
import "package:certimate/provider/upgrader.dart";
import "package:certimate/router/router.dart";
import "package:certimate/theme/theme.dart";
import "package:certimate/widgets/index.dart";
import "package:device_wrapper/device_wrapper.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_platform_widgets/flutter_platform_widgets.dart";
import "package:flutter_smart_dialog/flutter_smart_dialog.dart";
import "package:form_builder_validators/form_builder_validators.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:upgrader/upgrader.dart";

class App extends HookConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceConfig = ref.watch(deviceModeProvider);
    final targetPlatform = ref.watch(targetPlatformProvider);
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final themeScheme = ref.watch(themeSchemeProvider);
    final language = ref.watch(languageProvider);
    final upgrader = ref.read(upgraderProviderProvider);
    final showUnlock = useValueNotifier(false);
    useEffect(() {
      if (ref.read(biometricProvider)) {
        Future.delayed(
          const Duration(seconds: 1),
          () => onAppLifecycleStateChangeBySecurity(
            ref,
            null,
            AppLifecycleState.inactive,
            showUnlock,
            first: true,
          ),
        );
      }
      ref.read(localCertimateManagerProvider).ensureLocalServersStarted();
      return null;
    }, []);
    useOnAppLifecycleStateChange(
      (previous, current) => onAppLifecycleStateChangeBySecurity(
        ref,
        previous,
        current,
        showUnlock,
      ),
    );

    return MaterialApp.router(
      scrollBehavior: const AppScrollBehavior(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: FlutterSmartDialog.init(
        builder: (context, child) {
          if (kDebugMode) {
            // 显示 Debug 按钮
            Future.delayed(
              const Duration(seconds: 1),
              () => DebugDraggableButton.show(),
            );
          }
          if (kIsWeb) {
            return PlatformProvider(
              settings: PlatformSettingsData(
                platformStyle: PlatformStyleData(
                  web:
                      targetPlatform == TargetPlatform.iOS ||
                          targetPlatform == TargetPlatform.macOS
                      ? PlatformStyle.Cupertino
                      : PlatformStyle.Material,
                ),
              ),
              builder: (BuildContext context) {
                return DeviceWrapper(
                  showModeToggle: true,
                  deviceList: deviceList,
                  initialDevice: deviceConfig,
                  onModeChanged: (device) {
                    ref.read(deviceModeProvider.notifier).update(device);
                  },
                  child: child!,
                );
              },
            );
          } else {
            return UpgradeAlert(
              key: upgraderKey,
              navigatorKey: router.routerDelegate.navigatorKey,
              dialogStyle:
                  targetPlatform == TargetPlatform.iOS ||
                      targetPlatform == TargetPlatform.macOS
                  ? UpgradeDialogStyle.cupertino
                  : UpgradeDialogStyle.material,
              upgrader: upgrader,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(highContrast: false),
                child: child!,
              ),
            );
          }
        },
      ),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FormBuilderLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      locale: language,
      themeMode: themeMode,
      theme: getThemeData(
        context,
        Brightness.light,
        targetPlatform,
        themeScheme,
      ),
      darkTheme: getThemeData(
        context,
        Brightness.dark,
        targetPlatform,
        themeScheme,
      ),
    );
  }
}
