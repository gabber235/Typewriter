// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Creates the process wide router and its route access owners.
///
/// The provider keeps one router for the application lifetime. Its disposal
/// order releases reevaluation first, then the access coordinator and its
/// modules, preventing callbacks from reaching disposed route state.

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// Creates the process wide router and its route access owners.
///
/// The provider keeps one router for the application lifetime. Its disposal
/// order releases reevaluation first, then the access coordinator and its
/// modules, preventing callbacks from reaching disposed route state.

final class AppRouterProvider
    extends $FunctionalProvider<Raw<AppRouter>, Raw<AppRouter>, Raw<AppRouter>>
    with $Provider<Raw<AppRouter>> {
  /// Creates the process wide router and its route access owners.
  ///
  /// The provider keeps one router for the application lifetime. Its disposal
  /// order releases reevaluation first, then the access coordinator and its
  /// modules, preventing callbacks from reaching disposed route state.
  AppRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRouterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appRouterHash();

  @$internal
  @override
  $ProviderElement<Raw<AppRouter>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Raw<AppRouter> create(Ref ref) {
    return appRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Raw<AppRouter> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Raw<AppRouter>>(value),
    );
  }
}

String _$appRouterHash() => r'59601f42521add9d9c465d8cc51d24d2ed45f2e3';
