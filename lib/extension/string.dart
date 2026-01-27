import "dart:convert";

import "package:certimate/router/route.dart";
import "package:certimate/widgets/tip.dart" as tip;
import "package:flutter/cupertino.dart";
import "package:inflector_dart/inflector_dart.dart";

extension CapitalCaseExt on String {
  String _toCapitalCase({bool first = true}) {
    if (isEmpty) {
      return this;
    }
    return first ? this[0].toUpperCase() + substring(1) : camel2words(this);
  }

  String get capitalCase => _toCapitalCase(first: true);

  String get titleCase => _toCapitalCase(first: false);
}

extension StringExt on String? {
  bool get isNotEmptyOrNull => this?.isNotEmpty == true;

  bool get isEmptyOrNull => !isNotEmptyOrNull;

  String get showVal => _val("-");

  String _val(String value) => isNotEmptyOrNull ? this! : value;
}

extension StringUrlExt on String {
  String get fullHost {
    final uri = Uri.tryParse(this);
    final origin = uri?.origin;
    if (uri == null || origin == null || origin.isEmpty) {
      return this;
    }
    return origin.replaceFirst("${uri.scheme}://", "");
  }
}

extension DialogExt on String {
  Future<T?> showTip<T>() => tip.showTip<T>(content: this);
}

extension ProviderSvgExt on String {
  String providerSvg(String host) {
    return "$host/imgs/providers/${this == 'wecombot' ? 'wecom' : this}.svg";
  }
}

extension ServerWebViewExt on String {
  Future<T?> toServerWebview<T>(BuildContext context, int serverId) {
    return ServerWebViewRoute(url: this, serverId: serverId).push<T>(context);
  }
}

final _jsonEncoder = const JsonEncoder.withIndent("  ");

extension JsonExt on Object? {
  String toJsonString() => _jsonEncoder.convert(this);
}
