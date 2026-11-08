import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "membership_visibility.g.dart";

/// Shared display clock refreshed at the next observed membership expiry.
///
/// Visibility providers own and cancel their timers. This local clock filters
/// presentation; server commands still decide whether a request or code is valid.
@riverpod
DateTime membershipDisplayTime(Ref ref) {
  return clock.now();
}

@riverpod
AsyncValue<List<skir.OrganizationJoinRequest>> visibleOrganizationJoinRequests(
  Ref ref,
) {
  final requests = ref.watch(organizationJoinRequestsProvider);
  if (requests.mapUnready<List<skir.OrganizationJoinRequest>>()
      case final value?) {
    return value;
  }
  final now = ref.watch(membershipDisplayTimeProvider);
  ref.invalidateMembershipVisibilityAt(
    requests.requireValue.map((request) => request.expiresAt),
    now,
  );
  // Visibility follows confirmed collection events and expiry only.
  return AsyncData(
    List.unmodifiable(
      requests.requireValue.where((request) => request.expiresAt.isAfter(now)),
    ),
  );
}

@riverpod
AsyncValue<List<skir.JoinCode>> visibleOrganizationJoinCodes(Ref ref) {
  final codes = ref.watch(organizationJoinCodesProvider);
  if (codes.mapUnready<List<skir.JoinCode>>() case final value?) {
    return value;
  }
  final now = ref.watch(membershipDisplayTimeProvider);
  ref.invalidateMembershipVisibilityAt(
    codes.requireValue.map((code) => code.expiresAt).nonNulls,
    now,
  );
  // Visibility follows confirmed collection events and expiry only.
  return AsyncData(
    List.unmodifiable(
      codes.requireValue.where(
        (code) => code.expiresAt == null || code.expiresAt!.isAfter(now),
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
