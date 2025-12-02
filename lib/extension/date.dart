import "package:intl/intl.dart";

extension FormatDateTimeExt on DateTime? {
  String toDateString() {
    if (this == null) {
      return "";
    }
    return DateFormat("yyyy-MM-dd").format(this!);
  }

  String toDateTimeString() {
    if (this == null) {
      return "";
    }
    return DateFormat("yyyy-MM-dd HH:mm:ss").format(this!);
  }
}
