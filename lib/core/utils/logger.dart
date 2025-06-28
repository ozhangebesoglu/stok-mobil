import 'package:flutter/foundation.dart';

/// Logger utility for safe debugging in production
/// Replaces direct print() calls with conditional logging
class Logger {
  static const String _prefix = '[KASAP_STOK]';

  /// Log info message (only in debug mode)
  static void info(String message) {
    if (kDebugMode) {
      print('$_prefix INFO: $message');
    }
  }

  /// Log error message (only in debug mode)
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('$_prefix ERROR: $message');
      if (error != null) {
        print('$_prefix ERROR Details: $error');
      }
      if (stackTrace != null) {
        print('$_prefix STACK: $stackTrace');
      }
    }
  }

  /// Log warning message (only in debug mode)
  static void warning(String message) {
    if (kDebugMode) {
      print('$_prefix WARNING: $message');
    }
  }

  /// Log debug message (only in debug mode)
  static void debug(String message) {
    if (kDebugMode) {
      print('$_prefix DEBUG: $message');
    }
  }

  /// Log database operations (only in debug mode)
  static void database(String operation, [String? details]) {
    if (kDebugMode) {
      print('$_prefix DB: $operation${details != null ? ' - $details' : ''}');
    }
  }

  /// Log provider operations (only in debug mode)
  static void provider(String providerName, String operation) {
    if (kDebugMode) {
      print('$_prefix PROVIDER: $providerName - $operation');
    }
  }
}
