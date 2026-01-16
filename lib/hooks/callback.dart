import "dart:ui";

import "package:flutter_hooks/flutter_hooks.dart";

void useCallOnceWhen(bool condition, VoidCallback callback) {
  final called = useRef(false);
  useEffect(() {
    if (!called.value && condition) {
      called.value = true;
      callback();
    }
    return null;
  }, [condition]);
}
