import "package:flutter/foundation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/generated/api/user/organization.pb.dart"
    as api;
import "package:typewriter_panel/generated/models/organization/member.pb.dart"
    as models;
import "package:typewriter_panel/logic/auth.dart";
import "package:typewriter_panel/logic/nats.dart";
import "package:typewriter_panel/logic/proto/api_exception.dart";
import "package:typewriter_panel/utils/riverpod.dart";

part "user_join_requests.g.dart";

@immutable
class UserJoinRequest {
  const UserJoinRequest({
    required this.id,
    required this.organizationId,
    required this.organizationName,
    required this.organizationIconUrl,
    required this.requestedAt,
    required this.expiresAt,
  });

  final String id;
  final String organizationId;
  final String organizationName;
  final String organizationIconUrl;
  final DateTime requestedAt;
  final DateTime expiresAt;

  Duration get remainingDuration {
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get isExpired => remainingDuration == Duration.zero;
}

/// Converts a proto UserJoinRequest to a dart UserJoinRequest.
UserJoinRequest _protoToUserJoinRequest(models.UserJoinRequest proto) {
  return UserJoinRequest(
    id: proto.id,
    organizationId: proto.organizationId,
    organizationName: proto.organizationName,
    organizationIconUrl: proto.organizationIconUrl,
    requestedAt: proto.requestedAt.toDateTime(),
    expiresAt: proto.expiresAt.toDateTime(),
  );
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

    final request = api.ListUserJoinRequestsRequest();
    final stream = ref.requestProtoThenListen(
      subject: "cloud.out.user.$userId.organization.join_requests.list",
      listenSubject: "cloud.in.user.$userId.organization.join_requests.list",
      request: request,
      responseBuilder: api.ListUserJoinRequestsResponse.new,
    );

    await for (final response in stream) {
      if (response.hasError()) {
        throw ApiException.fromProto(response.error);
      }

      yield response.requests.requests.map(_protoToUserJoinRequest).toList();
    }
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

    final request = api.RequestToJoinRequest()..code = code;

    final response = await ref
        .read(natsProvider)
        .requestProto(
          "cloud.out.user.$userId.organization.join_requests.request",
          request,
          api.RequestToJoinResponse.new,
        );

    if (response.hasError()) {
      throw ApiException.fromProto(response.error);
    }

    if (response.hasRequest()) {
      final newRequest = _protoToUserJoinRequest(response.request);
      state = AsyncValue.data([...state.requireValue, newRequest]);
    }
  }

  /// Cancels a pending join request.
  Future<void> cancelRequest(String requestId) async {
    final userId = await ref.read(userIdProvider.future);
    if (userId == null) {
      throw ApiException.notAuthenticated();
    }

    state.ensureReady();
    final previousState = state;

    state = AsyncValue.data(
      state.requireValue.where((r) => r.id != requestId).toList(),
    );

    try {
      final request = api.CancelJoinRequestRequest()..requestId = requestId;

      final response = await ref
          .read(natsProvider)
          .requestProto(
            "cloud.out.user.$userId.organization.join_requests.cancel",
            request,
            api.CancelJoinRequestResponse.new,
          );

      if (response.hasError()) {
        state = previousState;
        ref.invalidateSelf();
        throw ApiException.fromProto(response.error);
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
