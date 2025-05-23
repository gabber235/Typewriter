// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(appRouter)
const appRouterProvider = AppRouterProvider._();

final class AppRouterProvider
    extends $FunctionalProvider<Raw<AppRouter>, Raw<AppRouter>>
    with $Provider<Raw<AppRouter>> {
  const AppRouterProvider._()
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
      providerOverride: $ValueProvider<Raw<AppRouter>>(value),
    );
  }
}

String _$appRouterHash() => r'babffb8e22cefce44520192b1132c6d68d9f20a5';

/// Provides the current route data for the given [name].
@ProviderFor(currentRouteData)
const currentRouteDataProvider = CurrentRouteDataFamily._();

/// Provides the current route data for the given [name].
final class CurrentRouteDataProvider
    extends $FunctionalProvider<RouteData?, RouteData?>
    with $Provider<RouteData?> {
  /// Provides the current route data for the given [name].
  const CurrentRouteDataProvider._(
      {required CurrentRouteDataFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'currentRouteDataProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$currentRouteDataHash();

  @override
  String toString() {
    return r'currentRouteDataProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<RouteData?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RouteData? create(Ref ref) {
    final argument = this.argument as String;
    return currentRouteData(
      ref,
      argument,
    );
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RouteData? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $ValueProvider<RouteData?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CurrentRouteDataProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$currentRouteDataHash() => r'96880f9b38b944f98b3aa12563542439e5021ae7';

/// Provides the current route data for the given [name].
final class CurrentRouteDataFamily extends $Family
    with $FunctionalFamilyOverride<RouteData?, String> {
  const CurrentRouteDataFamily._()
      : super(
          retry: null,
          name: r'currentRouteDataProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: false,
        );

  /// Provides the current route data for the given [name].
  CurrentRouteDataProvider call(
    String path,
  ) =>
      CurrentRouteDataProvider._(argument: path, from: this);

  @override
  String toString() => r'currentRouteDataProvider';
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
