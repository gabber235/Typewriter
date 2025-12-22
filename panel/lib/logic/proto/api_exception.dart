import "package:typewriter_panel/generated/models/common.pb.dart" as proto;

/// Exception thrown when an API call returns an error response.
///
/// This exception wraps the proto Error message and provides
/// convenient access to error details.
class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.details = const [],
  });

  /// Creates an ApiException from a proto Error message.
  factory ApiException.fromProto(proto.Error error) {
    return ApiException(
      code: error.code,
      message: error.message,
      details: error.details.toList(),
    );
  }

  /// Creates an ApiException for common error scenarios.
  factory ApiException.notAuthenticated() {
    return const ApiException(code: 401, message: "User not authenticated");
  }

  factory ApiException.noOrganization() {
    return const ApiException(code: 400, message: "No organization selected");
  }

  factory ApiException.notFound(String resource) {
    return ApiException(code: 404, message: "$resource not found");
  }

  /// The error code
  final int code;

  /// Human-readable error message.
  final String message;

  /// Additional error details.
  final List<String> details;

  /// Returns true if this is a client error (4xx).
  bool get isClientError {
    return code >= 400 && code < 500;
  }

  /// Returns true if this is a server error (5xx).
  bool get isServerError {
    return code >= 500 && code < 600;
  }

  /// Returns true if this is an authentication error (401).
  bool get isAuthError => code == 401;

  /// Returns true if this is a forbidden error (403).
  bool get isForbidden => code == 403;

  /// Returns true if this is a not found error (404).
  bool get isNotFound => code == 404;

  @override
  String toString() {
    if (details.isEmpty) {
      return message;
    }
    return "$message\nDetails: ${details.join(", ")}";
  }

  /// Returns a user-friendly message suitable for display.
  String toUserMessage() {
    // For 500 errors, provide a generic message
    if (isServerError) {
      return "Something went wrong. Please try again later.";
    }
    return message;
  }
}
