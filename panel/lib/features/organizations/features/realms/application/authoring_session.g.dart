// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'authoring_session.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns the canonical authoring state for one organization and realm.
///
/// Canonical state contains only server accepted books, tags, pages, and page
/// documents. Local editor drafts belong to [LocalWorkCommands] and are
/// projected over this state by editor resources. A state [sequence] couples
/// every canonical projection to the server revision that produced it. The
/// session applies only the next sequence, buffers future changes, and fetches
/// a snapshot when a gap, conflict, reconnect, or indirect page dependency
/// makes incremental reconciliation unsafe.
///
/// Use a scope lease before reading a resource that needs an authoritative
/// snapshot. The lease keeps this provider alive, waits for subscriptions and
/// its initial refresh through [AuthoringScopeLease.ready], and must be
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
/// Canonical state contains only server accepted books, tags, pages, and page
/// documents. Local editor drafts belong to [LocalWorkCommands] and are
/// projected over this state by editor resources. A state [sequence] couples
/// every canonical projection to the server revision that produced it. The
/// session applies only the next sequence, buffers future changes, and fetches
/// a snapshot when a gap, conflict, reconnect, or indirect page dependency
/// makes incremental reconciliation unsafe.
///
/// Use a scope lease before reading a resource that needs an authoritative
/// snapshot. The lease keeps this provider alive, waits for subscriptions and
/// its initial refresh through [AuthoringScopeLease.ready], and must be
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
  /// Canonical state contains only server accepted books, tags, pages, and page
  /// documents. Local editor drafts belong to [LocalWorkCommands] and are
  /// projected over this state by editor resources. A state [sequence] couples
  /// every canonical projection to the server revision that produced it. The
  /// session applies only the next sequence, buffers future changes, and fetches
  /// a snapshot when a gap, conflict, reconnect, or indirect page dependency
  /// makes incremental reconciliation unsafe.
  ///
  /// Use a scope lease before reading a resource that needs an authoritative
  /// snapshot. The lease keeps this provider alive, waits for subscriptions and
  /// its initial refresh through [AuthoringScopeLease.ready], and must be
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

String _$authoringSessionHash() => r'ddc11ebe9866187b7ef505c751432efd815778f9';

/// Owns the canonical authoring state for one organization and realm.
///
/// Canonical state contains only server accepted books, tags, pages, and page
/// documents. Local editor drafts belong to [LocalWorkCommands] and are
/// projected over this state by editor resources. A state [sequence] couples
/// every canonical projection to the server revision that produced it. The
/// session applies only the next sequence, buffers future changes, and fetches
/// a snapshot when a gap, conflict, reconnect, or indirect page dependency
/// makes incremental reconciliation unsafe.
///
/// Use a scope lease before reading a resource that needs an authoritative
/// snapshot. The lease keeps this provider alive, waits for subscriptions and
/// its initial refresh through [AuthoringScopeLease.ready], and must be
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
  /// Canonical state contains only server accepted books, tags, pages, and page
  /// documents. Local editor drafts belong to [LocalWorkCommands] and are
  /// projected over this state by editor resources. A state [sequence] couples
  /// every canonical projection to the server revision that produced it. The
  /// session applies only the next sequence, buffers future changes, and fetches
  /// a snapshot when a gap, conflict, reconnect, or indirect page dependency
  /// makes incremental reconciliation unsafe.
  ///
  /// Use a scope lease before reading a resource that needs an authoritative
  /// snapshot. The lease keeps this provider alive, waits for subscriptions and
  /// its initial refresh through [AuthoringScopeLease.ready], and must be
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
/// Canonical state contains only server accepted books, tags, pages, and page
/// documents. Local editor drafts belong to [LocalWorkCommands] and are
/// projected over this state by editor resources. A state [sequence] couples
/// every canonical projection to the server revision that produced it. The
/// session applies only the next sequence, buffers future changes, and fetches
/// a snapshot when a gap, conflict, reconnect, or indirect page dependency
/// makes incremental reconciliation unsafe.
///
/// Use a scope lease before reading a resource that needs an authoritative
/// snapshot. The lease keeps this provider alive, waits for subscriptions and
/// its initial refresh through [AuthoringScopeLease.ready], and must be
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

/// Keeps the library projection and its session alive while observed.

@ProviderFor(authoringLibraryScope)
final authoringLibraryScopeProvider = AuthoringLibraryScopeFamily._();

/// Keeps the library projection and its session alive while observed.

final class AuthoringLibraryScopeProvider
    extends
        $FunctionalProvider<
          AuthoringScopeLease,
          AuthoringScopeLease,
          AuthoringScopeLease
        >
    with $Provider<AuthoringScopeLease> {
  /// Keeps the library projection and its session alive while observed.
  AuthoringLibraryScopeProvider._({
    required AuthoringLibraryScopeFamily super.from,
    required (skir.RecordId, skir.RecordId) super.argument,
  }) : super(
         retry: null,
         name: r'authoringLibraryScopeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$authoringLibraryScopeHash();

  @override
  String toString() {
    return r'authoringLibraryScopeProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<AuthoringScopeLease> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AuthoringScopeLease create(Ref ref) {
    final argument = this.argument as (skir.RecordId, skir.RecordId);
    return authoringLibraryScope(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthoringScopeLease value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthoringScopeLease>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AuthoringLibraryScopeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$authoringLibraryScopeHash() =>
    r'454351addd0d65f985b9e40a71bb472b30e9d1a5';

/// Keeps the library projection and its session alive while observed.

final class AuthoringLibraryScopeFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AuthoringScopeLease,
          (skir.RecordId, skir.RecordId)
        > {
  AuthoringLibraryScopeFamily._()
    : super(
        retry: null,
        name: r'authoringLibraryScopeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Keeps the library projection and its session alive while observed.

  AuthoringLibraryScopeProvider call(
    skir.RecordId organizationId,
    skir.RecordId realmId,
  ) => AuthoringLibraryScopeProvider._(
    argument: (organizationId, realmId),
    from: this,
  );

  @override
  String toString() => r'authoringLibraryScopeProvider';
}

/// Keeps a book projection and its session alive while observed.

@ProviderFor(authoringBookScope)
final authoringBookScopeProvider = AuthoringBookScopeFamily._();

/// Keeps a book projection and its session alive while observed.

final class AuthoringBookScopeProvider
    extends
        $FunctionalProvider<
          AuthoringScopeLease,
          AuthoringScopeLease,
          AuthoringScopeLease
        >
    with $Provider<AuthoringScopeLease> {
  /// Keeps a book projection and its session alive while observed.
  AuthoringBookScopeProvider._({
    required AuthoringBookScopeFamily super.from,
    required (skir.RecordId, skir.RecordId, skir.RecordId) super.argument,
  }) : super(
         retry: null,
         name: r'authoringBookScopeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$authoringBookScopeHash();

  @override
  String toString() {
    return r'authoringBookScopeProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<AuthoringScopeLease> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AuthoringScopeLease create(Ref ref) {
    final argument =
        this.argument as (skir.RecordId, skir.RecordId, skir.RecordId);
    return authoringBookScope(ref, argument.$1, argument.$2, argument.$3);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthoringScopeLease value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthoringScopeLease>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AuthoringBookScopeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$authoringBookScopeHash() =>
    r'1a226ad5d72cecd97ca053dbaace05f26b78ec56';

/// Keeps a book projection and its session alive while observed.

final class AuthoringBookScopeFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AuthoringScopeLease,
          (skir.RecordId, skir.RecordId, skir.RecordId)
        > {
  AuthoringBookScopeFamily._()
    : super(
        retry: null,
        name: r'authoringBookScopeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Keeps a book projection and its session alive while observed.

  AuthoringBookScopeProvider call(
    skir.RecordId organizationId,
    skir.RecordId realmId,
    skir.RecordId bookId,
  ) => AuthoringBookScopeProvider._(
    argument: (organizationId, realmId, bookId),
    from: this,
  );

  @override
  String toString() => r'authoringBookScopeProvider';
}

/// Keeps a page projection and its session alive while observed.

@ProviderFor(authoringPageScope)
final authoringPageScopeProvider = AuthoringPageScopeFamily._();

/// Keeps a page projection and its session alive while observed.

final class AuthoringPageScopeProvider
    extends
        $FunctionalProvider<
          AuthoringScopeLease,
          AuthoringScopeLease,
          AuthoringScopeLease
        >
    with $Provider<AuthoringScopeLease> {
  /// Keeps a page projection and its session alive while observed.
  AuthoringPageScopeProvider._({
    required AuthoringPageScopeFamily super.from,
    required (skir.RecordId, skir.RecordId, skir.RecordId) super.argument,
  }) : super(
         retry: null,
         name: r'authoringPageScopeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$authoringPageScopeHash();

  @override
  String toString() {
    return r'authoringPageScopeProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<AuthoringScopeLease> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AuthoringScopeLease create(Ref ref) {
    final argument =
        this.argument as (skir.RecordId, skir.RecordId, skir.RecordId);
    return authoringPageScope(ref, argument.$1, argument.$2, argument.$3);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthoringScopeLease value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthoringScopeLease>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AuthoringPageScopeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$authoringPageScopeHash() =>
    r'c44890a703bb89f8493bdc840dba77f605c3752b';

/// Keeps a page projection and its session alive while observed.

final class AuthoringPageScopeFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AuthoringScopeLease,
          (skir.RecordId, skir.RecordId, skir.RecordId)
        > {
  AuthoringPageScopeFamily._()
    : super(
        retry: null,
        name: r'authoringPageScopeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Keeps a page projection and its session alive while observed.

  AuthoringPageScopeProvider call(
    skir.RecordId organizationId,
    skir.RecordId realmId,
    skir.RecordId pageId,
  ) => AuthoringPageScopeProvider._(
    argument: (organizationId, realmId, pageId),
    from: this,
  );

  @override
  String toString() => r'authoringPageScopeProvider';
}
