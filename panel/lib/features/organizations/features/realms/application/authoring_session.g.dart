// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'authoring_session.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns the canonical authoring state for one organization and realm.
///
/// Canonical state contains server accepted resources and relations for every
/// retained selection. Local editor drafts belong to [LocalWorkCommands] and are
/// projected over this state by editor resources. A state [sequence] couples
/// every canonical projection to the server revision that produced it. The
/// session applies only the next sequence, buffers future changes, and fetches
/// a snapshot when a gap, conflict, reconnect, or indirect page dependency
/// makes incremental reconciliation unsafe.
///
/// Use a scope lease before reading a resource that needs an authoritative
/// snapshot. The lease keeps this provider alive, waits for subscriptions and
/// its initial refresh through [AuthoringSelectionLease.ready], and must be
/// released when the resource stops being used.
///
/// Direct create and delete commands are routed through [prepare] and
/// [apply]. Editor updates normally enter through
/// [AuthoringResourceRepository.combiner], so several editor intents can share
/// one authoring batch without the session owning editor presentation state.

@ProviderFor(AuthoringSession)
final authoringSessionProvider = AuthoringSessionFamily._();

/// Owns the canonical authoring state for one organization and realm.
///
/// Canonical state contains server accepted resources and relations for every
/// retained selection. Local editor drafts belong to [LocalWorkCommands] and are
/// projected over this state by editor resources. A state [sequence] couples
/// every canonical projection to the server revision that produced it. The
/// session applies only the next sequence, buffers future changes, and fetches
/// a snapshot when a gap, conflict, reconnect, or indirect page dependency
/// makes incremental reconciliation unsafe.
///
/// Use a scope lease before reading a resource that needs an authoritative
/// snapshot. The lease keeps this provider alive, waits for subscriptions and
/// its initial refresh through [AuthoringSelectionLease.ready], and must be
/// released when the resource stops being used.
///
/// Direct create and delete commands are routed through [prepare] and
/// [apply]. Editor updates normally enter through
/// [AuthoringResourceRepository.combiner], so several editor intents can share
/// one authoring batch without the session owning editor presentation state.
final class AuthoringSessionProvider
    extends $NotifierProvider<AuthoringSession, AuthoringSessionState> {
  /// Owns the canonical authoring state for one organization and realm.
  ///
  /// Canonical state contains server accepted resources and relations for every
  /// retained selection. Local editor drafts belong to [LocalWorkCommands] and are
  /// projected over this state by editor resources. A state [sequence] couples
  /// every canonical projection to the server revision that produced it. The
  /// session applies only the next sequence, buffers future changes, and fetches
  /// a snapshot when a gap, conflict, reconnect, or indirect page dependency
  /// makes incremental reconciliation unsafe.
  ///
  /// Use a scope lease before reading a resource that needs an authoritative
  /// snapshot. The lease keeps this provider alive, waits for subscriptions and
  /// its initial refresh through [AuthoringSelectionLease.ready], and must be
  /// released when the resource stops being used.
  ///
  /// Direct create and delete commands are routed through [prepare] and
  /// [apply]. Editor updates normally enter through
  /// [AuthoringResourceRepository.combiner], so several editor intents can share
  /// one authoring batch without the session owning editor presentation state.
  AuthoringSessionProvider._({
    required AuthoringSessionFamily super.from,
    required (skir.RecordId, skir.RecordId) super.argument,
  }) : super(
         retry: null,
         name: r'authoringSessionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$authoringSessionHash();

  @override
  String toString() {
    return r'authoringSessionProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  AuthoringSession create() => AuthoringSession();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthoringSessionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthoringSessionState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AuthoringSessionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$authoringSessionHash() => r'e19b3a4b2baaa5abcd13a02700a35e3223ca41e9';

/// Owns the canonical authoring state for one organization and realm.
///
/// Canonical state contains server accepted resources and relations for every
/// retained selection. Local editor drafts belong to [LocalWorkCommands] and are
/// projected over this state by editor resources. A state [sequence] couples
/// every canonical projection to the server revision that produced it. The
/// session applies only the next sequence, buffers future changes, and fetches
/// a snapshot when a gap, conflict, reconnect, or indirect page dependency
/// makes incremental reconciliation unsafe.
///
/// Use a scope lease before reading a resource that needs an authoritative
/// snapshot. The lease keeps this provider alive, waits for subscriptions and
/// its initial refresh through [AuthoringSelectionLease.ready], and must be
/// released when the resource stops being used.
///
/// Direct create and delete commands are routed through [prepare] and
/// [apply]. Editor updates normally enter through
/// [AuthoringResourceRepository.combiner], so several editor intents can share
/// one authoring batch without the session owning editor presentation state.

final class AuthoringSessionFamily extends $Family
    with
        $ClassFamilyOverride<
          AuthoringSession,
          AuthoringSessionState,
          AuthoringSessionState,
          AuthoringSessionState,
          (skir.RecordId, skir.RecordId)
        > {
  AuthoringSessionFamily._()
    : super(
        retry: null,
        name: r'authoringSessionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Owns the canonical authoring state for one organization and realm.
  ///
  /// Canonical state contains server accepted resources and relations for every
  /// retained selection. Local editor drafts belong to [LocalWorkCommands] and are
  /// projected over this state by editor resources. A state [sequence] couples
  /// every canonical projection to the server revision that produced it. The
  /// session applies only the next sequence, buffers future changes, and fetches
  /// a snapshot when a gap, conflict, reconnect, or indirect page dependency
  /// makes incremental reconciliation unsafe.
  ///
  /// Use a scope lease before reading a resource that needs an authoritative
  /// snapshot. The lease keeps this provider alive, waits for subscriptions and
  /// its initial refresh through [AuthoringSelectionLease.ready], and must be
  /// released when the resource stops being used.
  ///
  /// Direct create and delete commands are routed through [prepare] and
  /// [apply]. Editor updates normally enter through
  /// [AuthoringResourceRepository.combiner], so several editor intents can share
  /// one authoring batch without the session owning editor presentation state.

  AuthoringSessionProvider call(
    skir.RecordId organizationId,
    skir.RecordId realmId,
  ) => AuthoringSessionProvider._(
    argument: (organizationId, realmId),
    from: this,
  );

  @override
  String toString() => r'authoringSessionProvider';
}

/// Owns the canonical authoring state for one organization and realm.
///
/// Canonical state contains server accepted resources and relations for every
/// retained selection. Local editor drafts belong to [LocalWorkCommands] and are
/// projected over this state by editor resources. A state [sequence] couples
/// every canonical projection to the server revision that produced it. The
/// session applies only the next sequence, buffers future changes, and fetches
/// a snapshot when a gap, conflict, reconnect, or indirect page dependency
/// makes incremental reconciliation unsafe.
///
/// Use a scope lease before reading a resource that needs an authoritative
/// snapshot. The lease keeps this provider alive, waits for subscriptions and
/// its initial refresh through [AuthoringSelectionLease.ready], and must be
/// released when the resource stops being used.
///
/// Direct create and delete commands are routed through [prepare] and
/// [apply]. Editor updates normally enter through
/// [AuthoringResourceRepository.combiner], so several editor intents can share
/// one authoring batch without the session owning editor presentation state.

abstract class _$AuthoringSession extends $Notifier<AuthoringSessionState> {
  late final _$args = ref.$arg as (skir.RecordId, skir.RecordId);
  skir.RecordId get organizationId => _$args.$1;
  skir.RecordId get realmId => _$args.$2;

  AuthoringSessionState build(
    skir.RecordId organizationId,
    skir.RecordId realmId,
  );
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AuthoringSessionState, AuthoringSessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AuthoringSessionState, AuthoringSessionState>,
              AuthoringSessionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}

/// Keeps one arbitrary graph selection and its session alive while observed.

@ProviderFor(authoringSelectionLease)
final authoringSelectionLeaseProvider = AuthoringSelectionLeaseFamily._();

/// Keeps one arbitrary graph selection and its session alive while observed.

final class AuthoringSelectionLeaseProvider
    extends
        $FunctionalProvider<
          AuthoringSelectionLease,
          AuthoringSelectionLease,
          AuthoringSelectionLease
        >
    with $Provider<AuthoringSelectionLease> {
  /// Keeps one arbitrary graph selection and its session alive while observed.
  AuthoringSelectionLeaseProvider._({
    required AuthoringSelectionLeaseFamily super.from,
    required (skir.RecordId, skir.RecordId, skir.GraphSelection) super.argument,
  }) : super(
         retry: null,
         name: r'authoringSelectionLeaseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$authoringSelectionLeaseHash();

  @override
  String toString() {
    return r'authoringSelectionLeaseProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<AuthoringSelectionLease> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AuthoringSelectionLease create(Ref ref) {
    final argument =
        this.argument as (skir.RecordId, skir.RecordId, skir.GraphSelection);
    return authoringSelectionLease(ref, argument.$1, argument.$2, argument.$3);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthoringSelectionLease value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthoringSelectionLease>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AuthoringSelectionLeaseProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$authoringSelectionLeaseHash() =>
    r'3a1ada15c6015408deed86af1b9ebca792a16621';

/// Keeps one arbitrary graph selection and its session alive while observed.

final class AuthoringSelectionLeaseFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AuthoringSelectionLease,
          (skir.RecordId, skir.RecordId, skir.GraphSelection)
        > {
  AuthoringSelectionLeaseFamily._()
    : super(
        retry: null,
        name: r'authoringSelectionLeaseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Keeps one arbitrary graph selection and its session alive while observed.

  AuthoringSelectionLeaseProvider call(
    skir.RecordId organizationId,
    skir.RecordId realmId,
    skir.GraphSelection selection,
  ) => AuthoringSelectionLeaseProvider._(
    argument: (organizationId, realmId, selection),
    from: this,
  );

  @override
  String toString() => r'authoringSelectionLeaseProvider';
}
