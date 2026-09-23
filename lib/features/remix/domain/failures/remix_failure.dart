sealed class RemixFailure {
  final String message;
  final String? code;
  final String? actionLabel;

  const RemixFailure(this.message, {this.code, this.actionLabel});
}

final class RemixNetworkFailure extends RemixFailure {
  const RemixNetworkFailure([
    super.message = 'Connection was interrupted while refining your prompt. Your draft is safe.',
  ]) : super(code: 'NETWORK_ERROR', actionLabel: 'Retry');
}

final class RemixTurnLimitFailure extends RemixFailure {
  const RemixTurnLimitFailure([
    super.message = 'Refinement turn limit reached (5/5). Your prompt recipe is armed and ready to generate!',
  ]) : super(code: 'TURN_LIMIT_REACHED', actionLabel: 'Generate Remix');
}

final class RemixValidationFailure extends RemixFailure {
  const RemixValidationFailure(
    super.message, {
    super.code = 'VALIDATION_ERROR',
    super.actionLabel = 'Edit Prompt',
  });
}

final class RemixInsufficientCreditsFailure extends RemixFailure {
  const RemixInsufficientCreditsFailure([
    super.message = 'Low credit balance. You need 1 credit to synthesize this remix variation.',
  ]) : super(code: 'INSUFFICIENT_CREDITS', actionLabel: 'Top Up');
}

final class RemixServerFailure extends RemixFailure {
  const RemixServerFailure(
    super.message, {
    super.code = 'SERVER_ERROR',
    super.actionLabel = 'Try Again',
  });
}
