sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is FailureResult<T>;

  T? get valueOrNull => switch (this) {
        Success(:final value) => value,
        FailureResult() => null,
      };

  Failure? get failureOrNull => switch (this) {
        FailureResult(:final failure) => failure,
        Success() => null,
      };

  R when<R>({
    required R Function(T value) success,
    required R Function(Failure failure) failure,
  }) {
    return switch (this) {
      Success(:final value) => success(value),
      FailureResult(failure: final f) => failure(f),
    };
  }
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);
  final Failure failure;
}

sealed class Failure {
  const Failure(this.message);
  final String message;
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class EmailAlreadyExistsFailure extends Failure {
  const EmailAlreadyExistsFailure([
    super.message = 'An account with this email already exists.',
  ]);
}

final class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure([
    super.message = 'Email or password is not correct.',
  ]);
}

final class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Something went wrong saving data.']);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Not found.']);
}

final class AiFailure extends Failure {
  const AiFailure([
    super.message =
        'Không thể nhận phản hồi từ giáo viên AI lúc này. Em thử lại nhé.',
  ]);
}

final class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Network error. Check your connection and try again.',
  ]);
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = 'Session expired. Please sign in again.',
  ]);
}

final class ApiFailure extends Failure {
  const ApiFailure(super.message, {this.code, this.statusCode});

  final String? code;
  final int? statusCode;
}
