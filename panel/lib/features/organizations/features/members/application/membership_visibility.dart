import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "membership_visibility.g.dart";

@riverpod
Set<(MembershipRemovalKind, skir.RecordId)> pendingMembershipRemovals(Ref ref) {
  final work = ref.watch(localWorkProvider);
  if (!work.submissions.any((submission) => submission.sending)) {
    return const {};
  }
  final organization = ref.watch(organizationIdProvider);
  if (organization == null) return const {};
  final repository = ref
      .watch(resourceRepositoriesProvider)
      .membership(organization);
  return {
    for (final submission in work.submissions)
      if (submission.sending && repository.removalFor(submission.id) != null)
        repository.removalFor(submission.id)!,
  };
}

@riverpod
DateTime membershipDisplayTime(Ref ref) {
  return DateTime.now();
}

@riverpod
AsyncValue<List<OrganizationJoinRequest>> visibleOrganizationJoinRequests(
  Ref ref,
) {
  final requests = ref.watch(organizationJoinRequestsProvider);
  if (requests.mapUnready<List<OrganizationJoinRequest>>() case final value?) {
    return value;
  }
  final now = ref.watch(membershipDisplayTimeProvider);
  final pending = ref.watch(pendingMembershipRemovalsProvider);
  ref.invalidateMembershipVisibilityAt(
    requests.requireValue.map((request) => request.expiresAt),
    now,
  );
  return AsyncData(
    List.unmodifiable(
      requests.requireValue.where(
        (request) =>
            request.expiresAt.isAfter(now) &&
            !pending.contains((
              MembershipRemovalKind.joinRequest,
              request.requestId,
            )),
      ),
    ),
  );
}

@riverpod
AsyncValue<List<OrganizationJoinCode>> visibleOrganizationJoinCodes(Ref ref) {
  final codes = ref.watch(organizationJoinCodesProvider);
  if (codes.mapUnready<List<OrganizationJoinCode>>() case final value?) {
    return value;
  }
  final now = ref.watch(membershipDisplayTimeProvider);
  final pending = ref.watch(pendingMembershipRemovalsProvider);
  ref.invalidateMembershipVisibilityAt(
    codes.requireValue.map((code) => code.expiresAt).nonNulls,
    now,
  );
  return AsyncData(
    List.unmodifiable(
      codes.requireValue.where(
        (code) =>
            (code.expiresAt == null || code.expiresAt!.isAfter(now)) &&
            !pending.contains((MembershipRemovalKind.joinCode, code.code)),
      ),
    ),
  );
}

extension on Ref {
  void invalidateMembershipVisibilityAt(
    Iterable<DateTime> expirations,
    DateTime now,
  ) {
    final future = expirations.where((expiry) => expiry.isAfter(now)).toList()
      ..sort();
    if (future.isEmpty) return;
    final timer = Timer(
      future.first.difference(now),
      () => invalidate(membershipDisplayTimeProvider),
    );
    onDispose(timer.cancel);
  }
}
