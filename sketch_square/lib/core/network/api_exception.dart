import 'package:dio/dio.dart';

/// Error codes produced client-side (the backend sends its own `code`s).
abstract final class ApiErrorCodes {
  static const network = 'NETWORK_ERROR';
  static const timeout = 'TIMEOUT';
  static const cancelled = 'CANCELLED';
  static const unknown = 'UNKNOWN';

  // Server codes, see docs/API_CONTRACT.md.
  static const validation = 'VALIDATION_ERROR';
  static const unauthorized = 'UNAUTHORIZED';
  static const forbidden = 'FORBIDDEN';
  static const verificationRequired = 'VERIFICATION_REQUIRED';
  static const notFound = 'NOT_FOUND';
  static const conflict = 'CONFLICT';
  static const freeLimitReached = 'FREE_LIMIT_REACHED';
  static const contributionRequired = 'CONTRIBUTION_REQUIRED';
  static const insufficientBalance = 'INSUFFICIENT_BALANCE';
  static const belowMinWithdrawal = 'BELOW_MIN_WITHDRAWAL';
  static const withdrawalBlocked = 'WITHDRAWAL_BLOCKED';
  static const uploadInvalid = 'UPLOAD_INVALID';
  static const rateLimited = 'RATE_LIMITED';
  static const internal = 'INTERNAL';

  /// Fallback code when the server sent a status but no error envelope.
  static String? forStatus(int? status) => switch (status) {
    400 => validation,
    401 => unauthorized,
    403 => forbidden,
    404 => notFound,
    409 => conflict,
    429 => rateLimited,
    final s? when s >= 500 => internal,
    _ => null,
  };
}

/// Client-side mirror of the backend error shape:
/// `{ "error": { "code": "...", "message": "...", "details": ... } }`.
class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.details,
    this.statusCode,
  });

  final String code;
  final String message;
  final Object? details;
  final int? statusCode;

  /// Parses a decoded response body. Returns null if it isn't the backend
  /// error envelope.
  static ApiException? tryParseBody(Object? body, {int? statusCode}) {
    if (body is! Map) return null;
    final error = body['error'];
    if (error is! Map) return null;
    final code = error['code'];
    final message = error['message'];
    if (code is! String || message == null) return null;
    return ApiException(
      code: code,
      // Validation errors may send a list of messages.
      message: message is List ? message.join('\n') : message.toString(),
      details: error['details'],
      statusCode: statusCode,
    );
  }

  factory ApiException.fromDioException(DioException e) {
    final existing = e.error;
    if (existing is ApiException) return existing;

    final status = e.response?.statusCode;
    final parsed = ApiException.tryParseBody(
      e.response?.data,
      statusCode: status,
    );
    if (parsed != null) return parsed;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return ApiException(
          code: ApiErrorCodes.timeout,
          message: 'The request timed out. Please try again.',
          statusCode: status,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          code: ApiErrorCodes.network,
          message: 'Unable to reach the server. Check your connection.',
          statusCode: status,
        );
      case DioExceptionType.cancel:
        return ApiException(
          code: ApiErrorCodes.cancelled,
          message: 'The request was cancelled.',
          statusCode: status,
        );
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        return ApiException(
          code: ApiErrorCodes.forStatus(status) ?? ApiErrorCodes.unknown,
          message:
              status == null
                  ? 'Something went wrong. Please try again.'
                  : 'Unexpected server response ($status).',
          statusCode: status,
        );
    }
  }

  bool get isUnauthorized => statusCode == 401;
  bool get isVerificationRequired => code == ApiErrorCodes.verificationRequired;

  @override
  String toString() => 'ApiException($code, $message, status: $statusCode)';
}

/// Turns any thrown object into a user-presentable [ApiException].
ApiException toApiException(Object error) {
  if (error is ApiException) return error;
  if (error is DioException) return ApiException.fromDioException(error);
  return const ApiException(
    code: ApiErrorCodes.unknown,
    message: 'Something went wrong. Please try again.',
  );
}
