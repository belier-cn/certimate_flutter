import "package:talker/talker.dart";

abstract class Logger {
  static final Talker _logger = Talker();

  static Talker getLogger() {
    return _logger;
  }

  static void v(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.verbose(message, error, stackTrace);
  }

  static void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.debug(message, error, stackTrace);
  }

  static void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.info(message, error, stackTrace);
  }

  static void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.warning(message, error, stackTrace);
  }

  static void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.error(message, error, stackTrace);
  }
}
