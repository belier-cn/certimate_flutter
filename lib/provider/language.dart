import "package:certimate/generated/l10n.dart";
import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:sp_util/sp_util.dart";

part "language.g.dart";

@Riverpod(keepAlive: true)
class Language extends _$Language {
  final String cacheKey = "language";

  @override
  Locale? build() {
    final languageValue = SpUtil.getString(cacheKey, defValue: "");
    return S.delegate.supportedLocales.firstWhereOrNull(
      (local) => local.toLanguageTag() == languageValue,
    );
  }

  void update(Locale? local) {
    state = local;
    if (local == null) {
      SpUtil.remove(cacheKey);
    } else {
      SpUtil.putString(cacheKey, local.languageCode);
    }
  }
}
