// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'navigation.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The application router for code below the app.
///
/// The app installs it through appOverrides; reading it without the app is a
/// wiring error.

@ProviderFor(navigationRouter)
final navigationRouterProvider = NavigationRouterProvider._();

/// The application router for code below the app.
///
/// The app installs it through appOverrides; reading it without the app is a
/// wiring error.

final class NavigationRouterProvider
    extends
        $FunctionalProvider<
          Raw<NavigationRouter>,
          Raw<NavigationRouter>,
          Raw<NavigationRouter>
        >
    with $Provider<Raw<NavigationRouter>> {
  /// The application router for code below the app.
  ///
  /// The app installs it through appOverrides; reading it without the app is a
  /// wiring error.
  NavigationRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'navigationRouterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$navigationRouterHash();

  @$internal
  @override
  $ProviderElement<Raw<NavigationRouter>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Raw<NavigationRouter> create(Ref ref) {
    return navigationRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Raw<NavigationRouter> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Raw<NavigationRouter>>(value),
    );
  }
}

String _$navigationRouterHash() => r'bc3b2eb62c6659a7e177c57a772cff6b2e908674';

/// Exposes the router's current path as reactive application state.

@ProviderFor(CurrentRoute)
final currentRouteProvider = CurrentRouteProvider._();

/// Exposes the router's current path as reactive application state.
final class CurrentRouteProvider
    extends $NotifierProvider<CurrentRoute, String> {
  /// Exposes the router's current path as reactive application state.
  CurrentRouteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentRouteProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentRouteHash();

  @$internal
  @override
  CurrentRoute create() => CurrentRoute();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$currentRouteHash() => r'db691523c8ff76110d68919cd2ec327beb53e232';

/// Exposes the router's current path as reactive application state.

abstract class _$CurrentRoute extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Reads an inherited path parameter from the router's active top route.
///
/// A missing parameter returns null. Consumers use this provider for route
/// scoped resource lookup and should handle that absence before constructing an
/// identifier.

@ProviderFor(routeParam)
final routeParamProvider = RouteParamFamily._();

/// Reads an inherited path parameter from the router's active top route.
///
/// A missing parameter returns null. Consumers use this provider for route
/// scoped resource lookup and should handle that absence before constructing an
/// identifier.

final class RouteParamProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// Reads an inherited path parameter from the router's active top route.
  ///
  /// A missing parameter returns null. Consumers use this provider for route
  /// scoped resource lookup and should handle that absence before constructing an
  /// identifier.
  RouteParamProvider._({
    required RouteParamFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'routeParamProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$routeParamHash();

  @override
  String toString() {
    return r'routeParamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    final argument = this.argument as String;
    return routeParam(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RouteParamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$routeParamHash() => r'156bc178435851c0edda37383fd04545255bd8d2';

/// Reads an inherited path parameter from the router's active top route.
///
/// A missing parameter returns null. Consumers use this provider for route
/// scoped resource lookup and should handle that absence before constructing an
/// identifier.

final class RouteParamFamily extends $Family
    with $FunctionalFamilyOverride<String?, String> {
  RouteParamFamily._()
    : super(
        retry: null,
        name: r'routeParamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Reads an inherited path parameter from the router's active top route.
  ///
  /// A missing parameter returns null. Consumers use this provider for route
  /// scoped resource lookup and should handle that absence before constructing an
  /// identifier.

  RouteParamProvider call(String id) =>
      RouteParamProvider._(argument: id, from: this);

  @override
  String toString() => r'routeParamProvider';
}
