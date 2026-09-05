// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'authoring_session.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AuthoringSession)
final authoringSessionProvider = AuthoringSessionFamily._();

final class AuthoringSessionProvider
    extends $NotifierProvider<AuthoringSession, AuthoringSessionState> {
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

String _$authoringSessionHash() => r'3ab0d000f1e6706f0fdcd2c310aa3754a8b721b4';

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
  void runBuild() {
    final ref = this.ref as $Ref<AuthoringSessionState, AuthoringSessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AuthoringSessionState, AuthoringSessionState>,
              AuthoringSessionState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}

@ProviderFor(authoringLibraryScope)
final authoringLibraryScopeProvider = AuthoringLibraryScopeFamily._();

final class AuthoringLibraryScopeProvider
    extends
        $FunctionalProvider<
          AuthoringScopeLease,
          AuthoringScopeLease,
          AuthoringScopeLease
        >
    with $Provider<AuthoringScopeLease> {
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

@ProviderFor(authoringBookScope)
final authoringBookScopeProvider = AuthoringBookScopeFamily._();

final class AuthoringBookScopeProvider
    extends
        $FunctionalProvider<
          AuthoringScopeLease,
          AuthoringScopeLease,
          AuthoringScopeLease
        >
    with $Provider<AuthoringScopeLease> {
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

@ProviderFor(authoringPageScope)
final authoringPageScopeProvider = AuthoringPageScopeFamily._();

final class AuthoringPageScopeProvider
    extends
        $FunctionalProvider<
          AuthoringScopeLease,
          AuthoringScopeLease,
          AuthoringScopeLease
        >
    with $Provider<AuthoringScopeLease> {
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
