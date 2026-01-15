abstract class Failure {
  const Failure([List properties = const <dynamic>[]]);
}

// General failures
class ServerFailure extends Failure {}

class CacheFailure extends Failure {}

class NetworkFailure extends Failure {}

class UnknownFailure extends Failure {
  final String message;

  const UnknownFailure(this.message);
}
