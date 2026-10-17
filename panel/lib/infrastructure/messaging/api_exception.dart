import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// A safe, user facing failure produced while translating a server response.
///
/// Feature application code uses this type to preserve the response category
/// while keeping transport details and server internals out of presentation.
/// Factories below encode the categories understood by the panel, rather than
/// making each caller reproduce HTTP style status and message decisions.
class ApiException implements Exception {
  const ApiException({required this.code, required this.message});

  /// Creates a server failure with a deliberately non diagnostic message.
  factory ApiException.internalServerError() {
    return ApiException(code: 500, message: funnyErrorTitles.randomElement());
  }

  /// Creates a failure for a response variant the panel cannot interpret.
  ///
  /// This is distinct from a server error because the server may be healthy
  /// while the panel and contract are out of sync.
  factory ApiException.unknownResponseMessage() {
    return ApiException(
      code: 422,
      message: "Invalid response, please try to update or refresh your browser",
    );
  }

  /// Rejects an operation that requires an authenticated principal.
  factory ApiException.notAuthenticated() {
    return const ApiException(code: 401, message: "User not authenticated");
  }

  /// Creates the local validation failure used when no organization is active.
  factory ApiException.noOrganization() {
    return const ApiException(code: 400, message: "No organization selected");
  }

  /// Creates a request validation failure with safe caller supplied context.
  factory ApiException.badRequest(String message) {
    return ApiException(code: 400, message: message);
  }

  /// Translates the typed record ID contract failure into actionable panel text.
  factory ApiException.invalidRecordId(skir.InvalidRecordIdError error) {
    final givenTables = error.givenTables.map((table) => "'$table'").join(", ");
    return ApiException.badRequest(
      "Expected record IDs from table '${error.expectedTable}', but received tables: $givenTables.",
    );
  }

  /// Creates the authorization failure for a user outside the organization.
  factory ApiException.userNotMemberError() {
    return const ApiException(
      code: 403,
      message: "User is not a member of this organization",
    );
  }

  /// Creates a missing resource failure using the resource's display form.
  factory ApiException.notFound(String resource) {
    return ApiException(code: 404, message: "${resource.formatted} not found");
  }

  /// Creates an unresolved resource failure when its exact server cause is unknown.
  factory ApiException.unknown(String resource) {
    return ApiException(code: 422, message: "${resource.formatted} not found");
  }

  /// Creates a conflict when the requested state cannot be applied as submitted.
  factory ApiException.conflict(String message) {
    return ApiException(code: 409, message: message);
  }

  /// The HTTP style category used by callers to choose recovery or presentation.
  final int code;

  final String message;

  bool get isClientError {
    return code >= 400 && code < 500;
  }

  bool get isServerError {
    return code >= 500 && code < 600;
  }

  bool get isAuthError => code == 401;

  bool get isForbidden => code == 403;

  bool get isNotFound => code == 404;

  @override
  String toString() {
    return "$code: $message";
  }
}
