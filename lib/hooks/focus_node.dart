import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";

List<FocusNode> useFocusNodes({required int count}) {
  final focusNodes = useMemoized(
    () => List.generate(count, (_) => FocusNode()),
    [count],
  );
  useEffect(() {
    return () {
      for (final node in focusNodes) {
        node.dispose();
      }
    };
  }, [focusNodes]);
  return focusNodes;
}
