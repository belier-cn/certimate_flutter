import "package:easy_refresh/easy_refresh.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";

EasyRefreshController useRefreshController() {
  return use(const _RefreshControllerHook());
}

class _RefreshControllerHook extends Hook<EasyRefreshController> {
  const _RefreshControllerHook();

  @override
  _RefreshControllerState createState() => _RefreshControllerState();
}

class _RefreshControllerState
    extends HookState<EasyRefreshController, _RefreshControllerHook> {
  final EasyRefreshController _controller = EasyRefreshController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  EasyRefreshController build(BuildContext context) {
    return _controller;
  }
}
