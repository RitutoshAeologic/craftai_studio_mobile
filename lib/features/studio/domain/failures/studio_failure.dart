sealed class StudioFailure {
  final String message;
  final String? code;

  const StudioFailure(this.message, {this.code});
}

final class StudioNetworkFailure extends StudioFailure {
  const StudioNetworkFailure([super.message = 'Network connection failure. Please check your internet.'])
      : super(code: 'NETWORK_ERROR');
}

final class StudioTimeoutFailure extends StudioFailure {
  const StudioTimeoutFailure([super.message = 'Generation timed out. Circuit breaker initiated.'])
      : super(code: 'TIMEOUT');
}

final class StudioRateLimitFailure extends StudioFailure {
  const StudioRateLimitFailure([super.message = 'Rate limit reached. Please wait a moment before trying again.'])
      : super(code: 'RATE_LIMIT_429');
}

final class StudioValidationFailure extends StudioFailure {
  const StudioValidationFailure([super.message = 'Invalid prompt or studio parameter.'])
      : super(code: 'VALIDATION_400');
}

final class StudioModerationFailure extends StudioFailure {
  const StudioModerationFailure([super.message = 'Prompt flagged by safety and content moderation policy.'])
      : super(code: 'MODERATION_422');
}

final class StudioServerFailure extends StudioFailure {
  const StudioServerFailure(super.message, {super.code = 'SERVER_ERROR'});
}

final class StudioUnknownFailure extends StudioFailure {
  const StudioUnknownFailure([super.message = 'An unexpected studio error occurred.'])
      : super(code: 'UNKNOWN');
}
