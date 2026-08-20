import '../errors/app_exceptions.dart';
import 'l10n.dart';

/// The only place an error becomes copy — and the only place that decides what a user is
/// allowed to read.
///
/// `ApiException.message` is never passed through. The backend has no user-facing
/// validation text to forward: everything it says is either internal detail or a hint
/// about which anti-abuse layer fired, and an attacker reading a precise rejection
/// reason is exactly the feedback loop PROJECT_PLAN.md §6 is built to deny.
String describeError(AppLocalizations l10n, Object error) => switch (error) {
  NetworkException() => l10n.errorOffline,
  UnauthenticatedException() => l10n.errorSession,
  NotFoundException() => l10n.errorNotFound,
  VoteRejectedException() => l10n.errorVoteRejected,
  UpstreamUnavailableException() => l10n.errorUpstream,
  // `InvalidRequestException` and `UnknownApiException` land here too, and should: a
  // client-side bug and a discriminator this build has never heard of are both things
  // the user can do nothing about, so they read the same generic line.
  _ => l10n.errorGeneric,
};
