import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:flutter_lucide_animated/flutter_lucide_animated.dart";

LucideAnimatedIconController useLucideIconController() {
  return use(const _LucideIconControllerHook());
}

class _LucideIconControllerHook extends Hook<LucideAnimatedIconController> {
  const _LucideIconControllerHook();

  @override
  _LucideIconControllerState createState() => _LucideIconControllerState();
}

class _LucideIconControllerState
    extends HookState<LucideAnimatedIconController, _LucideIconControllerHook> {
  final LucideAnimatedIconController _controller =
      LucideAnimatedIconController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  LucideAnimatedIconController build(BuildContext context) {
    return _controller;
  }
}
