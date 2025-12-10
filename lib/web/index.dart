// https://dart.dev/tools/pub/create-packages#conditionally-importing-and-exporting-library-files
export "web_none.dart" if (dart.library.html) "web.dart";
