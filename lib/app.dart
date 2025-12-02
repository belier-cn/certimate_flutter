import "package:certimate/generated/l10n.dart";
import "package:certimate/provider/language.dart";
import "package:certimate/provider/platform.dart";
import "package:certimate/provider/security.dart";
import "package:certimate/provider/theme.dart";
import "package:certimate/router/router.dart";
import "package:certimate/theme/theme.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_smart_dialog/flutter_smart_dialog.dart";
import "package:form_builder_validators/form_builder_validators.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

class App extends HookConsumerWidget {
  const App({super.key});

  static const _certimateChannel = MethodChannel("certimateChannel");

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final themeScheme = ref.watch(themeSchemeProvider);
    final language = ref.watch(languageProvider);
    final targetPlatform = ref.watch(targetPlatformProvider);
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
      _certimateChannel.setMethodCallHandler((call) async {
        if (call.method == "openSettings") {
          router.push("/settings");
        }
      });
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
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(highContrast: false),
      child: MaterialApp.router(
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
            return child!;
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
      ),
    );
  }
}
