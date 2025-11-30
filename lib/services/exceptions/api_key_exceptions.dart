class ApiKeyException implements Exception {
  final String message;
  final dynamic originalError;

  ApiKeyException(this.message, [this.originalError]);

  @override
  String toString() =>
      'ApiKeyException: $message${originalError != null ? '\nOriginal error: $originalError' : ''}';
}

class ApiKeyValidationException extends ApiKeyException {
  ApiKeyValidationException(super.message, [super.originalError]);
}

class ApiKeyStorageException extends ApiKeyException {
  ApiKeyStorageException(super.message, [super.originalError]);
}

class ApiKeyInitializationException extends ApiKeyException {
  ApiKeyInitializationException(super.message, [super.originalError]);
}
