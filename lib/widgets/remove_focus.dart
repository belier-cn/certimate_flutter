import "package:flutter/material.dart";
import "package:keyboard_detection/keyboard_detection.dart";

class RemoveFocus extends StatelessWidget {
  final Widget? child;

  const RemoveFocus({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return KeyboardDetection(
      controller: KeyboardDetectionController(
        onChanged: (state) {
          if (state == KeyboardState.hidden) {
            FocusManager.instance.primaryFocus?.unfocus();
          }
        },
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: child,
      ),
    );
  }
}
