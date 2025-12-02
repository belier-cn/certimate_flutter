import "package:certimate/extension/index.dart";
import "package:flutter/material.dart";
import "package:flutter_platform_widgets/flutter_platform_widgets.dart";
import "package:flutter_smart_dialog/flutter_smart_dialog.dart";
import "package:uuid/uuid.dart";

typedef TipBuilder = String Function(BuildContext context);

Future<T?> showTip<T>({String content = "", TipBuilder? builder}) {
  final tag = "tip-${const Uuid().v4()}";
  return SmartDialog.show(
    tag: tag,
    clickMaskDismiss: false,
    builder: (context) {
      final s = context.s;
      return PlatformAlertDialog(
        title: Text(s.tip.capitalCase),
        content: Text(builder != null ? builder(context) : content),
        actions: [
          PlatformDialogAction(
            onPressed: () => SmartDialog.dismiss(tag: tag),
            child: Text(s.ok.toUpperCase()),
          ),
        ],
      );
    },
  );
}
