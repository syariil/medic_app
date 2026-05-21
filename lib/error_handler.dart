import 'package:flutter/foundation.dart';

/// Utility class untuk handling error dan logging di seluruh aplikasi
class ErrorHandler {
  static const String _tag = '[ErrorHandler]';

  /// Enum untuk tipe error
  enum ErrorType {
    network,
    database,
    validation,
    parsing,
    unknown,
    notFound,
    unauthorized,
    conflict,
    timeout,
  }

  /// Custom exception class
  static class AppException implements Exception {
    final String message;
    final ErrorType type;
    final dynamic originalException;
    final StackTrace? stackTrace;

    AppException({
      required this.message,
      required this.type,
      this.originalException,
      this.stackTrace,
    });

    @override
    String toString() => message;
  }

  /// Dapatkan error message yang mudah dibaca untuk user
  static String getReadableError(dynamic error) {
    if (error is AppException) {
      return error.message;
    }

    if (error is String) {
      return error;
    }

    if (error is Exception) {
      final message = error.toString();

      // Network errors
      if (message.contains('SocketException') ||
          message.contains('HandshakeException')) {
        return 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
      }

      // Timeout errors
      if (message.contains('TimeoutException')) {
        return 'Permintaan timeout. Coba lagi dengan koneksi yang lebih baik.';
      }

      // Database errors
      if (message.contains('DatabaseException') ||
          message.contains('SqliteException')) {
        return 'Terjadi kesalahan pada database. Coba lagi nanti.';
      }

      // Parsing errors
      if (message.contains('FormatException') ||
          message.contains('DeserializationException')) {
        return 'Gagal memproses data. Format data tidak valid.';
      }

      return message;
    }

    return 'Terjadi kesalahan yang tidak diketahui';
  }

  /// Dapatkan error type dari exception
  static ErrorType getErrorType(dynamic error) {
    if (error is AppException) {
      return error.type;
    }

    if (error is String || error is Exception) {
      final message = error.toString().toLowerCase();

      if (message.contains('socket') ||
          message.contains('handshake') ||
          message.contains('connection')) {
        return ErrorType.network;
      }

      if (message.contains('database') || message.contains('sqlite')) {
        return ErrorType.database;
      }

      if (message.contains('validation')) {
        return ErrorType.validation;
      }

      if (message.contains('format') || message.contains('parse')) {
        return ErrorType.parsing;
      }

      if (message.contains('404') || message.contains('not found')) {
        return ErrorType.notFound;
      }

      if (message.contains('401') || message.contains('unauthorized')) {
        return ErrorType.unauthorized;
      }

      if (message.contains('409') || message.contains('conflict')) {
        return ErrorType.conflict;
      }

      if (message.contains('timeout')) {
        return ErrorType.timeout;
      }
    }

    return ErrorType.unknown;
  }

  /// Log error dengan stack trace
  static void logError(
    dynamic error, {
    StackTrace? stackTrace,
    String? tag,
    String? context,
  }) {
    if (!kDebugMode) return;

    final errorTag = tag ?? _tag;
    final errorMessage = error.toString();
    final contextStr = context != null ? ' [$context]' : '';
    final errorType = getErrorType(error);

    print('$errorTag ERROR$contextStr [${errorType.name}]: $errorMessage');

    if (stackTrace != null) {
      print('$errorTag STACK TRACE:');
      print(stackTrace);
    }

    // Anda dapat menambahkan crash reporting di sini (Sentry, Firebase Crashlytics, dll)
    // _reportToCrashlytics(error, stackTrace, context);
  }

  /// Log warning message
  static void logWarning(
    String message, {
    String? tag,
    String? context,
  }) {
    if (!kDebugMode) return;

    final warningTag = tag ?? _tag;
    final contextStr = context != null ? ' [$context]' : '';

    print('$warningTag WARNING$contextStr: $message');
  }

  /// Log info message
  static void logInfo(
    String message, {
    String? tag,
    String? context,
  }) {
    if (!kDebugMode) return;

    final infoTag = tag ?? _tag;
    final contextStr = context != null ? ' [$context]' : '';

    print('$infoTag INFO$contextStr: $message');
  }

  /// Log debug message (hanya di debug mode)
  static void logDebug(
    String message, {
    String? tag,
    String? context,
  }) {
    if (!kDebugMode) return;

    final debugTag = tag ?? _tag;
    final contextStr = context != null ? ' [$context]' : '';

    print('$debugTag DEBUG$contextStr: $message');
  }

  /// Wrap async operation dengan error handling
  static Future<T> executeAsync<T>(
    Future<T> Function() operation, {
    required String context,
    T? fallbackValue,
  }) async {
    try {
      logInfo('Menjalankan: $context');
      final result = await operation();
      logInfo('Berhasil: $context');
      return result;
    } catch (error, stackTrace) {
      logError(
        error,
        stackTrace: stackTrace,
        context: context,
      );

      if (fallbackValue != null) {
        return fallbackValue;
      }

      rethrow;
    }
  }

  /// Wrap sync operation dengan error handling
  static T execute<T>(
    T Function() operation, {
    required String context,
    T? fallbackValue,
  }) {
    try {
      logInfo('Menjalankan: $context');
      final result = operation();
      logInfo('Berhasil: $context');
      return result;
    } catch (error, stackTrace) {
      logError(
        error,
        stackTrace: stackTrace,
        context: context,
      );

      if (fallbackValue != null) {
        return fallbackValue;
      }

      rethrow;
    }
  }

  /// Throw AppException
  static Never throwError({
    required String message,
    required ErrorType type,
    dynamic originalException,
    StackTrace? stackTrace,
  }) {
    throw AppException(
      message: message,
      type: type,
      originalException: originalException,
      stackTrace: stackTrace,
    );
  }

  /// Helper untuk throw validation error
  static Never throwValidationError(String message) {
    throwError(
      message: message,
      type: ErrorType.validation,
    );
  }

  /// Helper untuk throw network error
  static Never throwNetworkError(String message) {
    throwError(
      message: message,
      type: ErrorType.network,
    );
  }

  /// Helper untuk throw database error
  static Never throwDatabaseError(String message) {
    throwError(
      message: message,
      type: ErrorType.database,
    );
  }

  /// Helper untuk throw not found error
  static Never throwNotFoundError(String message) {
    throwError(
      message: message,
      type: ErrorType.notFound,
    );
  }

  /// Format error response dari API
  static String formatApiError(dynamic response) {
    try {
      if (response is Map<String, dynamic>) {
        // Coba ambil message field
        if (response.containsKey('message')) {
          return response['message'] as String;
        }

        // Coba ambil error field
        if (response.containsKey('error')) {
          final error = response['error'];
          if (error is String) {
            return error;
          }
          if (error is Map && error.containsKey('message')) {
            return error['message'] as String;
          }
        }

        // Coba ambil errors field (untuk validation errors)
        if (response.containsKey('errors')) {
          final errors = response['errors'];
          if (errors is Map) {
            return errors.values.first.toString();
          }
        }
      }
    } catch (e) {
      logError(e, context: 'formatApiError');
    }

    return 'Terjadi kesalahan. Silakan coba lagi.';
  }
}
