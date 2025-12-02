import "package:flex_color_scheme/flex_color_scheme.dart";
import "package:flutter/material.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:sp_util/sp_util.dart";

part "theme.g.dart";

@Riverpod(keepAlive: true)
class ThemeModeNotifier extends _$ThemeModeNotifier {
  final String cacheKey = "theme-model";

  @override
  ThemeMode build() {
    final themeValue = SpUtil.getString(cacheKey, defValue: "");
    return ThemeMode.values.firstWhere(
      (theme) => theme.name == themeValue,
      orElse: () => ThemeMode.system,
    );
  }

  void update(ThemeMode mode) {
    state = mode;
    SpUtil.putString(cacheKey, mode.name);
  }
}

@riverpod
class ThemeSchemeNotifier extends _$ThemeSchemeNotifier {
  final String cacheKey = "theme-scheme";

  @override
  FlexScheme build() {
    final themeValue = SpUtil.getString(cacheKey, defValue: "");
    return FlexScheme.values.firstWhere(
      (theme) => theme.name == themeValue,
      orElse: () => FlexScheme.gold,
    );
  }

  void update(FlexScheme scheme) {
    state = scheme;
    SpUtil.putString(cacheKey, scheme.name);
  }
}
