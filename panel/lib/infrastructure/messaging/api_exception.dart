import "package:typewriter_panel/infrastructure/protocols/protobuf/generated/models/common.pb.dart"
    as proto;
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart" as proto;
import "package:typewriter_panel/typewriter_panel.dart";

/// Exception thrown when an API call returns an error response.
///
/// This exception wraps the proto Error message and provides
/// convenient access to error details.
class ApiException implements Exception {
  const ApiException({required this.code, required this.message});

  /// Creates an ApiException from a proto Error message.
  factory ApiException.fromProto(proto.Error error) {
    return ApiException(code: error.code, message: error.message);
  }

  factory ApiException.internalServerError() {
    return ApiException(code: 500, message: funnyErrorTitles.randomElement());
  }

  factory ApiException.unknownResponseMessage() {
    return ApiException(
      code: 422,
      message: "Invalid response, please try to update or refresh your browser",
    );
  }

  /// Creates an ApiException for common error scenarios.
  factory ApiException.notAuthenticated() {
    return const ApiException(code: 401, message: "User not authenticated");
  }

  factory ApiException.noOrganization() {
    return const ApiException(code: 400, message: "No organization selected");
  }

  factory ApiException.badRequest(String message) {
    return ApiException(code: 400, message: message);
  }

  factory ApiException.invalidRecordId(skir.InvalidRecordIdError error) {
    final givenTables = error.givenTables.map((table) => "'$table'").join(", ");
    return ApiException.badRequest(
      "Expected record IDs from table '${error.expectedTable}', but received tables: $givenTables.",
    );
  }

  factory ApiException.userNotMemberError() {
    return const ApiException(
      code: 403,
      message: "User is not a member of this organization",
    );
  }

  factory ApiException.notFound(String resource) {
    return ApiException(code: 404, message: "${resource.formatted} not found");
  }

  factory ApiException.unknown(String resource) {
    return ApiException(code: 422, message: "${resource.formatted} not found");
  }

  factory ApiException.conflict(String message) {
    return ApiException(code: 409, message: message);
  }

  /// The error code
  final int code;

  /// Human-readable error message.
  final String message;

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
    return "$code: $message";
  }
}
