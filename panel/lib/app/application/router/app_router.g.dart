// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

final class AppRouterProvider
    extends $FunctionalProvider<Raw<AppRouter>, Raw<AppRouter>, Raw<AppRouter>>
    with $Provider<Raw<AppRouter>> {
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

String _$appRouterHash() => r'dcba6f0b62eea76b19a03b6a9a3d3a97e2cb8b06';

@ProviderFor(CurrentRoute)
final currentRouteProvider = CurrentRouteProvider._();

final class CurrentRouteProvider
    extends $NotifierProvider<CurrentRoute, String> {
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

String _$currentRouteHash() => r'4d674e4c2628483be0c07103bd68ab85d47f7c82';

abstract class _$CurrentRoute extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(routeParam)
final routeParamProvider = RouteParamFamily._();

final class RouteParamProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  RouteParamProvider._({
    required RouteParamFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'routeParamProvider',
         isAutoDispose: true,
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

String _$routeParamHash() => r'8c4dfa29f3ca899f30f1b754f79b73a38dbb6f3f';

final class RouteParamFamily extends $Family
    with $FunctionalFamilyOverride<String?, String> {
  RouteParamFamily._()
    : super(
        retry: null,
        name: r'routeParamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RouteParamProvider call(String id) =>
      RouteParamProvider._(argument: id, from: this);

  @override
  String toString() => r'routeParamProvider';
}
