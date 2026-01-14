import "package:certimate/extension/index.dart";
import "package:certimate/theme/border.dart";
import "package:chinese_font_library/chinese_font_library.dart";
import "package:flex_color_scheme/flex_color_scheme.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/foundation.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_settings_ui/flutter_settings_ui.dart";
import "package:material_design/material_design.dart";

class AppThemeData extends ThemeExtension<AppThemeData> {
  final EdgeInsets bodyPadding;
  final EdgeInsets cupertinoButtonPadding;
  final Color successColor;
  final Color errorColor;
  final Color infoColor;
  final Color warningColor;

  final List<Color> successColors;
  final List<Color> errorColors;
  final List<Color> infoColors;
  final List<Color> warningColors;

  const AppThemeData({
    this.bodyPadding = const EdgeInsets.symmetric(
      horizontal: M3Spacings.space16,
    ),
    this.cupertinoButtonPadding = const EdgeInsets.symmetric(
      horizontal: M3Spacings.space16,
    ),
    this.errorColor = const Color(0xFFA63C37),
    this.successColor = const Color(0xFF417C43),
    this.infoColor = const Color(0xFF3466A7),
    this.warningColor = const Color(0xFF9F7B2D),
    this.errorColors = const [Color(0xFFA63C37), Color(0xFFEC827C)],
    this.successColors = const [Color(0xFF417C43), Color(0xFF86C288)],
    this.infoColors = const [Color(0xFF3466A7), Color(0xFF79ABED)],
    this.warningColors = const [Color(0xFF9F7B2D), Color(0xFFE4C073)],
  });

  @override
  ThemeExtension<AppThemeData> copyWith() {
    return this;
  }

  @override
  ThemeExtension<AppThemeData> lerp(
    covariant ThemeExtension<AppThemeData>? other,
    double t,
  ) {
    return this;
  }
}

const lightSystemUiOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.dark,
  systemNavigationBarDividerColor: Colors.transparent,
  systemNavigationBarContrastEnforced: false,
);

late ThemeData _darkTheme;
late ThemeData _lightTheme;

ThemeData getDarkTheme() {
  return _darkTheme;
}

ThemeData getLightTheme() {
  return _lightTheme;
}

const darkSystemUiOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.light,
  systemNavigationBarDividerColor: Colors.transparent,
  systemNavigationBarContrastEnforced: false,
);

ThemeData getThemeData(
  BuildContext context,
  Brightness brightness,
  TargetPlatform? targetPlatform,
  FlexScheme themeScheme,
) {
  const flexSubThemesData = FlexSubThemesData(
    interactionEffects: true,
    tintedDisabledControls: true,
    useM2StyleDividerInM3: true,
    inputDecoratorSchemeColor: SchemeColor.surfaceContainerLowest,
    inputDecoratorIsFilled: true,
    inputDecoratorBorderSchemeColor: SchemeColor.primaryContainer,
    inputDecoratorBorderType: FlexInputBorderType.outline,
    inputCursorSchemeColor: SchemeColor.primaryContainer,
    inputSelectionSchemeColor: SchemeColor.primaryContainer,
    inputSelectionHandleSchemeColor: SchemeColor.primaryContainer,
    alignedDropdown: true,
    navigationRailUseIndicator: true,
  );
  final theme = brightness == Brightness.light
      ? FlexThemeData.light(
          platform: targetPlatform,
          scheme: themeScheme,
          subThemesData: flexSubThemesData,
          visualDensity: FlexColorScheme.comfortablePlatformDensity,
          cupertinoOverrideTheme: const CupertinoThemeData(
            applyThemeToAll: true,
          ),
        )
      : FlexThemeData.dark(
          platform: targetPlatform,
          scheme: themeScheme,
          subThemesData: flexSubThemesData,
          visualDensity: FlexColorScheme.comfortablePlatformDensity,
          cupertinoOverrideTheme: const CupertinoThemeData(
            applyThemeToAll: true,
          ),
        );
  final finalTheme = _initTheme(context, theme);
  if (brightness == Brightness.light) {
    _lightTheme = finalTheme;
  } else {
    _darkTheme = finalTheme;
  }
  return finalTheme;
}

// https://m3.material.io/develop/flutter
// https://docs.flutter.dev/ui/widgets/cupertino
// https://docs.flutter.dev/ui/widgets/material
// https://rydmike.com/flexcolorscheme/themesplayground-latest
ThemeData _initTheme(BuildContext context, ThemeData theme) {
  final cupertino =
      theme.platform == TargetPlatform.iOS ||
      theme.platform == TargetPlatform.macOS;
  final isLight = theme.brightness == Brightness.light;
  final scaffoldBackgroundColor = isLight
      ? (cupertino
            ? const Color(0xFFF2F2F7)
            : theme.colorScheme.surfaceContainerLowest)
      : Colors.black;
  final inputBorder = cupertino
      ? const OutlineInputBorder(
          borderSide: BorderSide(
            color: CupertinoDynamicColor.withBrightness(
              color: Color(0x33000000),
              darkColor: Color(0x33FFFFFF),
            ),
            width: 0,
          ),
          borderRadius: BorderRadius.all(Radius.circular(5)),
        )
      : getPolygonInputBorder(
          theme.inputDecorationTheme.border as WidgetStateInputBorder,
        );
  final errorInputBorder = cupertino
      ? inputBorder.copyWith(
          borderSide: inputBorder.borderSide.copyWith(
            color: theme.colorScheme.error,
          ),
        )
      : null;
  return theme.copyWith(
    scaffoldBackgroundColor: scaffoldBackgroundColor,
    textTheme: kIsWeb
        ? theme.textTheme
        : theme.textTheme.useSystemChineseFont(theme.brightness),
    appBarTheme: AppBarTheme(
      backgroundColor: scaffoldBackgroundColor,
      scrolledUnderElevation: RunPlatform.isDesktopUi ? 0 : null,
    ),
    tooltipTheme: const TooltipThemeData(
      decoration: BoxDecoration(color: Colors.transparent),
      textStyle: TextStyle(color: Colors.transparent),
      waitDuration: Duration.zero,
      showDuration: Duration.zero,
      triggerMode: TooltipTriggerMode.manual,
    ),
    cupertinoOverrideTheme: CupertinoThemeData(
      brightness: theme.brightness,
      applyThemeToAll: true,
      primaryColor: theme.colorScheme.primary,
      primaryContrastingColor: theme.colorScheme.onPrimary,
      scaffoldBackgroundColor: CupertinoColors.systemBackground,
      barBackgroundColor: scaffoldBackgroundColor,
    ),
    cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
    inputDecorationTheme: theme.inputDecorationTheme.copyWith(
      border: inputBorder,
      enabledBorder: cupertino ? inputBorder : null,
      focusedBorder: cupertino ? inputBorder : null,
      errorBorder: errorInputBorder,
      focusedErrorBorder: errorInputBorder,
      hintStyle: TextStyle(color: theme.hintColor),
      contentPadding: cupertino
          ? const EdgeInsets.symmetric(horizontal: 2, vertical: 5)
          : null,
      labelStyle: theme.inputDecorationTheme.labelStyle?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      isCollapsed: cupertino,
      fillColor: cupertino && !isLight ? const Color(0xFF1C1C1E) : null,
    ),
    extensions: [
      SettingsThemeData(
        settingsListBackground: scaffoldBackgroundColor,
        leadingIconsColor: theme.textTheme.labelSmall?.color?.withValues(
          alpha: 0.75,
        ),
        titleTextColor: theme.textTheme.labelSmall?.color,
      ),
      AppThemeData(
        cupertinoButtonPadding: cupertino
            ? const EdgeInsets.symmetric(horizontal: M3Spacings.space16)
            : const EdgeInsets.symmetric(horizontal: M3Spacings.space20),
      ),
    ],
  );
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.mouse,
    ...super.dragDevices,
  };
}
