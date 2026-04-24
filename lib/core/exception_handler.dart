class AppException implements Exception {
  const AppException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    return message;
  }
}

class ExceptionHandler {
  const ExceptionHandler._();

  static AppException handle(Object error) {
    if (error is AppException) {
      return error;
    }

    // fallback for unknown errors
    return const AppException('Something went wrong. Please try again.');
  }
}
