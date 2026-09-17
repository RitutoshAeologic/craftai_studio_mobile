/// Sealed typed failures for every auth error path.
/// Never let a raw [AuthException.message] reach the UI layer —
/// always map to one of these types first (AuthController._failureToMessage).
sealed class AuthFailure {
  const AuthFailure();
}

/// Email or password is incorrect.
final class InvalidCredentials extends AuthFailure {
  const InvalidCredentials();
}

/// Attempted sign-up with an email that already has an account.
final class EmailAlreadyInUse extends AuthFailure {
  const EmailAlreadyInUse();
}

/// Password does not meet Supabase's minimum length requirement.
final class WeakPassword extends AuthFailure {
  const WeakPassword();
}

/// User signed up but has not confirmed their email yet.
final class EmailNotConfirmed extends AuthFailure {
  const EmailNotConfirmed();
}

/// Password-reset or lookup attempted for an email with no account.
final class UserNotFound extends AuthFailure {
  const UserNotFound();
}

/// Socket / timeout error — device is offline or server unreachable.
final class NetworkFailure extends AuthFailure {
  const NetworkFailure();
}

/// Catch-all for any Supabase [AuthException] not explicitly mapped above.
final class UnknownFailure extends AuthFailure {
  const UnknownFailure(this.message);
  final String message;
}
