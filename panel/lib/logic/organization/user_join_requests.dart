import "package:flutter/foundation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

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

@riverpod
class UserJoinRequests extends _$UserJoinRequests {
  @override
  Future<List<UserJoinRequest>> build() async {
    // TODO: Implement fetching user's pending join requests from backend
    throw UnimplementedError();
  }

  Future<void> requestToJoin(String urlOrCode) async {
    // TODO: Implement requesting to join an organization
    throw UnimplementedError();
  }

  Future<void> cancelRequest(String requestId) async {
    // TODO: Implement canceling a join request
    throw UnimplementedError();
  }
}
