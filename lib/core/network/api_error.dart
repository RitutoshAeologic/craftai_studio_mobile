/// Base sealed class for all strongly-typed network and API exceptions.
/// Decouples UI and Domain layers from low-level Dio/HTTP libraries.
sealed class AppNetworkException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  const AppNetworkException(this.message, {this.code, this.statusCode});

  @override
  String toString() => '$runtimeType: $message (code: $code, statusCode: $statusCode)';
}

/// Transport Layer: No internet, DNS lookup failure, or socket connection refused.
class ConnectionException extends AppNetworkException {
  const ConnectionException([super.message = 'No internet connection. Please verify your Wi-Fi or mobile data.'])
      : super(code: 'CONNECTION_ERROR');
}

/// Transport Layer: Connection, send, or receive timeout exceeded.
class NetworkTimeoutException extends AppNetworkException {
  const NetworkTimeoutException([super.message = 'Network request timed out. Please tap retry.'])
      : super(code: 'TIMEOUT');
}

/// Gateway Layer: Reverse proxy / tunnel dropped (502 Bad Gateway / 503 Tunnel Unavailable).
class TunnelUnavailableException extends AppNetworkException {
  const TunnelUnavailableException([
    super.message = 'Backend tunnel connection is temporarily unavailable. Attempting fallback connection...',
    int? statusCode = 503,
  ]) : super(code: 'TUNNEL_UNAVAILABLE', statusCode: statusCode);
}

/// Auth Layer: 401 Unauthorized / Token expired.
class AuthTokenException extends AppNetworkException {
  const AuthTokenException([
    super.message = 'Your session has expired. Please sign in again.',
    int? statusCode = 401,
  ]) : super(code: 'UNAUTHORIZED_401', statusCode: statusCode);
}

/// Rate Limit Layer: 429 Too Many Requests / Quota exceeded.
class RateLimitException extends AppNetworkException {
  const RateLimitException([
    super.message = 'Too many requests. Please wait a moment before trying again.',
    int? statusCode = 429,
  ]) : super(code: 'RATE_LIMIT_429', statusCode: statusCode);
}

/// Backend Application Layer: 400, 422, or 500 response from FastAPI business logic.
class ServerException extends AppNetworkException {
  final dynamic responseData;

  const ServerException(
    super.message, {
    super.code = 'SERVER_ERROR',
    super.statusCode,
    this.responseData,
  });
}

