import "package:flutter/foundation.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/features/auth/application/auth.dart";
import "package:typewriter_panel/infrastructure/messaging/api_exception.dart";
import "package:typewriter_panel/infrastructure/messaging/nats.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/converters.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart" as skir;
import "package:typewriter_panel/shared/utilities/collection.dart";
import "package:typewriter_panel/shared/utilities/riverpod.dart";

part "user_join_requests.freezed.dart";
part "user_join_requests.g.dart";

@freezed
abstract class UserJoinRequest with _$UserJoinRequest {
  const factory UserJoinRequest({
    required skir.RecordId requestId,
    required skir.RecordId organizationId,
    required String organizationName,
    required String organizationLogoUrl,
    required DateTime requestedAt,
    required DateTime expiresAt,
  }) = _UserJoinRequest;

  const UserJoinRequest._();

  factory UserJoinRequest.fromSkir(skir.UserJoinRequest request) {
    return UserJoinRequest(
      requestId: request.requestId,
      organizationId: request.organizationId,
      organizationName: request.organizationName,
      organizationLogoUrl: request.organizationLogoUrl,
      requestedAt: request.requestedAt,
      expiresAt: request.expiresAt,
    );
  }

  skir.UserJoinRequest toSkir() {
    return skir.UserJoinRequest(
      requestId: requestId,
      organizationId: organizationId,
      organizationName: organizationName,
      organizationLogoUrl: organizationLogoUrl,
      requestedAt: requestedAt,
      expiresAt: expiresAt,
    );
  }

  Duration get remainingDuration {
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get isExpired => remainingDuration == Duration.zero;
}

@riverpod
class UserJoinRequests extends _$UserJoinRequests {
  @override
  Stream<List<UserJoinRequest>> build() async* {
    final userId = await ref.watch(userIdProvider.future);
    if (userId == null) {
      yield [];
      return;
    }

    final request = skir.WatchUserJoinRequestsRequest();
    yield* ref.watchRequest(
      subject: "cloud.to.user.$userId.organization.join_requests.watch",
      listenSubject: "cloud.from.user.$userId.organization.join_requests.watch",
      requestBytes: skir.WatchUserJoinRequestsRequest.serializer.toBytes(
        request,
      ),
      serializer: skir.WatchUserJoinRequestsResponse.serializer,
      transformer: (previous, response) {
        switch (response) {
          case skir.WatchUserJoinRequestsResponse_unknown():
            throw ApiException.unknownResponseMessage();
          case skir.WatchUserJoinRequestsResponse_internalErrorWrapper():
            throw ApiException.internalServerError();
          case skir.WatchUserJoinRequestsResponse_listWrapper(:final value):
            return value.map(UserJoinRequest.fromSkir).toList();
          case skir.WatchUserJoinRequestsResponse_addWrapper(:final value):
            return previous.upsertByKey(
              (request) => request.requestId,
              UserJoinRequest.fromSkir(value),
            );
          case skir.WatchUserJoinRequestsResponse_removeWrapper(:final value):
            return previous?.where((r) => r.requestId != value).toList() ?? [];
        }
      },
    );
  }

  /// Requests to join an organization using a join code or URL.
  /// The urlOrCode parameter can be either a join code (e.g., "abc123")
  /// or a full URL containing the code.
  Future<void> requestToJoin(String urlOrCode) async {
    final userId = await ref.read(userIdProvider.future);
    if (userId == null) {
      throw ApiException.notAuthenticated();
    }

    state.ensureReady();
    final code = _extractCode(urlOrCode);
    final codeId = recordId("organization_join_codes:$code");

    final request = skir.SubmitUserJoinRequestRequest(code: codeId);

    final response = await ref.requestSkir(
      "cloud.to.user.$userId.organization.join_requests.request",
      skir.SubmitUserJoinRequestRequest.serializer.toBytes(request),
      skir.SubmitUserJoinRequestResponse.serializer,
    );

    switch (response) {
      case skir.SubmitUserJoinRequestResponse_unknown():
        throw ApiException.unknownResponseMessage();
      case skir.SubmitUserJoinRequestResponse_codeNotFoundErrorWrapper():
        throw ApiException.notFound("Join code not found or expired");
      case skir.SubmitUserJoinRequestResponse_internalErrorWrapper():
        throw ApiException.internalServerError();
      case skir.SubmitUserJoinRequestResponse_alreadyMemberErrorWrapper():
        throw ApiException.conflict(
          "You are already a member of this organization",
        );
      case skir.SubmitUserJoinRequestResponse_noAssignableRolesErrorWrapper():
        throw ApiException.badRequest(
          "No assignable roles available for this organization",
        );
      case skir.SubmitUserJoinRequestResponse_maxPendingRequestsErrorWrapper():
        throw ApiException.badRequest("Maximum pending join requests reached");
      case skir.SubmitUserJoinRequestResponse_pendingRequestExistsErrorWrapper():
        throw ApiException.conflict(
          "You already have a pending join request for this organization",
        );
      case skir.SubmitUserJoinRequestResponse_requestMadeWrapper(:final value):
        state = AsyncValue.data([
          ...state.requireValue,
          UserJoinRequest.fromSkir(value),
        ]);
      case skir.SubmitUserJoinRequestResponse_autoAcceptedWrapper():
        debugPrint("User was auto-accepted as a member");
    }
  }

  /// Cancels a pending join request.
  Future<void> cancelRequest(skir.RecordId requestId) async {
    final userId = await ref.read(userIdProvider.future);
    if (userId == null) {
      throw ApiException.notAuthenticated();
    }

    state.ensureReady();
    final previousState = state;

    state = AsyncValue.data(
      state.requireValue.where((r) => r.requestId != requestId).toList(),
    );

    try {
      final request = skir.CancelUserJoinRequestRequest(requestId: requestId);

      final response = await ref.requestSkir(
        "cloud.to.user.$userId.organization.join_requests.cancel",
        skir.CancelUserJoinRequestRequest.serializer.toBytes(request),
        skir.CancelUserJoinRequestResponse.serializer,
      );

      switch (response) {
        case skir.CancelUserJoinRequestResponse_unknown():
          throw ApiException.unknownResponseMessage();
        case skir.CancelUserJoinRequestResponse_internalErrorWrapper():
          throw ApiException.internalServerError();
        case skir.CancelUserJoinRequestResponse_requestNotFoundErrorWrapper():
          throw ApiException.notFound("Join request not found");
        case skir.CancelUserJoinRequestResponse_successWrapper():
          debugPrint("Join request $requestId cancelled successfully");
      }
    } catch (e) {
      state = previousState;
      ref.invalidateSelf();
      rethrow;
    }
  }

  /// Extracts the join code from a URL or returns the code as-is.
  /// URL format: https://example.com/join/abc123 or just "abc123"
  String _extractCode(String urlOrCode) {
    final uri = Uri.tryParse(urlOrCode);
    if (uri != null && uri.hasScheme && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    return urlOrCode;
  }
}
