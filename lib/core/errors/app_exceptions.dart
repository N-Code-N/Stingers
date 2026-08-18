/// The typed error set. Nothing above the network layer ever sees an HTTP status or a
/// `SocketException` — the API client maps every failure into one of these, and the UI
/// dispatches on the *type*, never on the message string.
sealed class AppException implements Exception {
  const AppException();
}

/// Transport failure: no route, DNS, TLS, timeout, connection reset.
///
/// This is deliberately not an error screen. A repository that catches it serves what
/// the local database already has; "no connection" is a quieter screen, not a broken one.
final class NetworkException extends AppException {
  const NetworkException([this.cause]);

  final Object? cause;

  @override
  String toString() => 'NetworkException($cause)';
}

/// A response the server produced deliberately. `message` is the server's own text and
/// is only ever shown where `describeError` decides it is safe to.
sealed class ApiException extends AppException {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType($message)';
}

/// The session is missing or rejected. The app signs in anonymously at startup, so in
/// practice this means the session could not be established at all.
final class UnauthenticatedException extends ApiException {
  const UnauthenticatedException(super.message);
}

final class NotFoundException extends ApiException {
  const NotFoundException(super.message);
}

/// The request never reached the shape the server expects — a client bug, not a
/// user-facing condition. Surfaced generically.
final class InvalidRequestException extends ApiException {
  const InvalidRequestException(super.message);
}

/// The vote was refused: rate limiting today, attestation failure later. Distinct from
/// every other failure because the user genuinely has to be told something honest
/// instead of "try again" — their vote did not land.
final class VoteRejectedException extends ApiException {
  const VoteRejectedException(super.message);
}

/// TMDb itself is unreachable from the Edge Function. Ours is up; theirs is not.
final class UpstreamUnavailableException extends ApiException {
  const UpstreamUnavailableException(super.message);
}

/// The fall-through arm. A server that grows a new `error_type` must never make an old
/// client throw while parsing the error.
final class UnknownApiException extends ApiException {
  const UnknownApiException(super.message);
}

/// Maps the backend's `{"error_type": ..., "error": ...}` envelope onto the set above.
///
/// `errorType` is nullable because a failing edge (a gateway, a proxy) can answer with
/// something that is not our envelope at all.
ApiException parseApiError({
  required int statusCode,
  String? errorType,
  String? message,
}) {
  final text = message ?? 'HTTP $statusCode';
  return switch (errorType) {
    'unauthenticated' => UnauthenticatedException(text),
    'not_found' => NotFoundException(text),
    'invalid_request' => InvalidRequestException(text),
    'rate_limited' => VoteRejectedException(text),
    'upstream_unavailable' => UpstreamUnavailableException(text),
    // Unknown discriminator: fall back to what the status code tells us, and only then
    // to `unknown`. Never throw while parsing an error.
    _ => switch (statusCode) {
      401 || 403 => UnauthenticatedException(text),
      404 => NotFoundException(text),
      429 => VoteRejectedException(text),
      502 || 503 || 504 => UpstreamUnavailableException(text),
      _ => UnknownApiException(text),
    },
  };
}
