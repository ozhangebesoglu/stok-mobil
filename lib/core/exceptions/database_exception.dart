/// Database Exception Handler
/// Context7 pattern for comprehensive error handling
class DatabaseException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;
  final StackTrace? stackTrace;

  const DatabaseException(
    this.message, {
    this.code,
    this.originalException,
    this.stackTrace,
  });

  @override
  String toString() {
    return 'DatabaseException: $message${code != null ? ' (Code: $code)' : ''}';
  }

  /// Factory constructors for specific error types
  factory DatabaseException.connectionFailed([String? details]) {
    return DatabaseException(
      'Database connection failed${details != null ? ': $details' : ''}',
      code: 'CONNECTION_FAILED',
    );
  }

  factory DatabaseException.queryFailed(String query, [dynamic error]) {
    return DatabaseException(
      'Database query failed: $query',
      code: 'QUERY_FAILED',
      originalException: error,
    );
  }

  factory DatabaseException.transactionFailed([dynamic error]) {
    return DatabaseException(
      'Database transaction failed',
      code: 'TRANSACTION_FAILED',
      originalException: error,
    );
  }

  factory DatabaseException.insertFailed(String table, [dynamic error]) {
    return DatabaseException(
      'Insert operation failed in table: $table',
      code: 'INSERT_FAILED',
      originalException: error,
    );
  }

  factory DatabaseException.updateFailed(String table, [dynamic error]) {
    return DatabaseException(
      'Update operation failed in table: $table',
      code: 'UPDATE_FAILED',
      originalException: error,
    );
  }

  factory DatabaseException.deleteFailed(String table, [dynamic error]) {
    return DatabaseException(
      'Delete operation failed in table: $table',
      code: 'DELETE_FAILED',
      originalException: error,
    );
  }

  factory DatabaseException.notFound(String resource) {
    return DatabaseException('$resource not found', code: 'NOT_FOUND');
  }

  factory DatabaseException.constraintViolation(
    String constraint, [
    dynamic error,
  ]) {
    return DatabaseException(
      'Database constraint violation: $constraint',
      code: 'CONSTRAINT_VIOLATION',
      originalException: error,
    );
  }
}
