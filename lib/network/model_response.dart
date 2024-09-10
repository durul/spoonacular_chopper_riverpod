/// It’s a simple blueprint for a result with a generic type T.
sealed class Result<T> {}

/// Generic response class holds either a successful response or an error.
class Success<T> extends Result<T> {
  final T value;

  Success(this.value);
}

class Error<T> extends Result<T> {
  final Exception exception;

  Error(this.exception);
}
