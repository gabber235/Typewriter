// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_work.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(localWorkScope)
final localWorkScopeProvider = LocalWorkScopeProvider._();

final class LocalWorkScopeProvider
    extends $FunctionalProvider<LocalWorkScope, LocalWorkScope, LocalWorkScope>
    with $Provider<LocalWorkScope> {
  LocalWorkScopeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localWorkScopeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localWorkScopeHash();

  @$internal
  @override
  $ProviderElement<LocalWorkScope> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LocalWorkScope create(Ref ref) {
    return localWorkScope(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalWorkScope value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalWorkScope>(value),
    );
  }
}

String _$localWorkScopeHash() => r'686c1ecadd0e013b82fac8bde21357df1b062236';

/// Stable command owner that privately replaces work when its scope changes.
///
/// Riverpod keeps this command surface stable for callers. Mutable resources,
/// reservations, submissions, and editor lifetimes belong to the current
/// [LocalWorkSession], which is discarded when [localWorkScope] changes.

@ProviderFor(LocalWork)
final localWorkProvider = LocalWorkProvider._();

/// Stable command owner that privately replaces work when its scope changes.
///
/// Riverpod keeps this command surface stable for callers. Mutable resources,
/// reservations, submissions, and editor lifetimes belong to the current
/// [LocalWorkSession], which is discarded when [localWorkScope] changes.
final class LocalWorkProvider
    extends $NotifierProvider<LocalWork, LocalWorkState> {
  /// Stable command owner that privately replaces work when its scope changes.
  ///
  /// Riverpod keeps this command surface stable for callers. Mutable resources,
  /// reservations, submissions, and editor lifetimes belong to the current
  /// [LocalWorkSession], which is discarded when [localWorkScope] changes.
  LocalWorkProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localWorkProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localWorkHash();

  @$internal
  @override
  LocalWork create() => LocalWork();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalWorkState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalWorkState>(value),
    );
  }
}

String _$localWorkHash() => r'ed499a07ae2ebc5e4a8e2788f3c6c17b3d3443cf';

/// Stable command owner that privately replaces work when its scope changes.
///
/// Riverpod keeps this command surface stable for callers. Mutable resources,
/// reservations, submissions, and editor lifetimes belong to the current
/// [LocalWorkSession], which is discarded when [localWorkScope] changes.

abstract class _$LocalWork extends $Notifier<LocalWorkState> {
  LocalWorkState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LocalWorkState, LocalWorkState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LocalWorkState, LocalWorkState>,
              LocalWorkState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Exposes the stable command owner without exposing its scoped session.
///
/// Callers use this provider for commands so they do not retain a session that
/// may have been invalidated by authentication or organization changes.

@ProviderFor(localWorkController)
final localWorkControllerProvider = LocalWorkControllerProvider._();

/// Exposes the stable command owner without exposing its scoped session.
///
/// Callers use this provider for commands so they do not retain a session that
/// may have been invalidated by authentication or organization changes.

final class LocalWorkControllerProvider
    extends
        $FunctionalProvider<
          LocalWorkCommands,
          LocalWorkCommands,
          LocalWorkCommands
        >
    with $Provider<LocalWorkCommands> {
  /// Exposes the stable command owner without exposing its scoped session.
  ///
  /// Callers use this provider for commands so they do not retain a session that
  /// may have been invalidated by authentication or organization changes.
  LocalWorkControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localWorkControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localWorkControllerHash();

  @$internal
  @override
  $ProviderElement<LocalWorkCommands> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocalWorkCommands create(Ref ref) {
    return localWorkController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalWorkCommands value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalWorkCommands>(value),
    );
  }
}

String _$localWorkControllerHash() =>
    r'2deda75dcc2b676ae8d3cd605d428ee9afc1f702';
