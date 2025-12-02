import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";

typedef TextEditingControllerListener = void Function(String value);

TextEditingController useListenerTextEditingController({
  String? text,
  List<Object?>? keys,
  List<TextEditingControllerListener>? listeners,
}) {
  final controller = useTextEditingController(text: text, keys: keys);
  useEffect(() {
    void listener() {
      if (listeners == null) {
        return;
      }
      final text = controller.text;
      for (final listener in listeners) {
        listener(text);
      }
    }

    controller.addListener(listener);
    return () => controller.removeListener(listener);
  }, [controller]);
  return controller;
}
