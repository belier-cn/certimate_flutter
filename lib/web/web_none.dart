import "dart:ffi";

String getPathName() => throw UnsupportedError("getPathName");

void replacePath(String path) => throw UnsupportedError("replacePath");

void usePathUrlStrategy() => throw UnsupportedError("usePathUrlStrategy");

String getCurrentAbi() => Abi.current().toString();
