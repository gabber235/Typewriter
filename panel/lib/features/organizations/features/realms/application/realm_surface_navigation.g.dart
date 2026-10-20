// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'realm_surface_navigation.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The resource the resource route opens, from its route parameter.

@ProviderFor(routedResourceId)
final routedResourceIdProvider = RoutedResourceIdProvider._();

/// The resource the resource route opens, from its route parameter.

final class RoutedResourceIdProvider
    extends
        $FunctionalProvider<
          skir.ResourceId?,
          skir.ResourceId?,
          skir.ResourceId?
        >
    with $Provider<skir.ResourceId?> {
  /// The resource the resource route opens, from its route parameter.
  RoutedResourceIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routedResourceIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routedResourceIdHash();

  @$internal
  @override
  $ProviderElement<skir.ResourceId?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  skir.ResourceId? create(Ref ref) {
    return routedResourceId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(skir.ResourceId? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<skir.ResourceId?>(value),
    );
  }
}

String _$routedResourceIdHash() => r'84bc9946db44689a09df4c59ca5cb4c333c05634';

/// The resource the realm route of [scope] shows: the routed resource, or the
/// first section on the realm home. Null outside the realm route.

@ProviderFor(routedResource)
final routedResourceProvider = RoutedResourceFamily._();

/// The resource the realm route of [scope] shows: the routed resource, or the
/// first section on the realm home. Null outside the realm route.

final class RoutedResourceProvider
    extends
        $FunctionalProvider<
          skir.ResourceId?,
          skir.ResourceId?,
          skir.ResourceId?
        >
    with $Provider<skir.ResourceId?> {
  /// The resource the realm route of [scope] shows: the routed resource, or the
  /// first section on the realm home. Null outside the realm route.
  RoutedResourceProvider._({
    required RoutedResourceFamily super.from,
    required AuthoringScope super.argument,
  }) : super(
         retry: null,
         name: r'routedResourceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$routedResourceHash();

  @override
  String toString() {
    return r'routedResourceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<skir.ResourceId?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  skir.ResourceId? create(Ref ref) {
    final argument = this.argument as AuthoringScope;
    return routedResource(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(skir.ResourceId? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<skir.ResourceId?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RoutedResourceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$routedResourceHash() => r'447765942f782ab7e04549b07adec9c69fd95032';

/// The resource the realm route of [scope] shows: the routed resource, or the
/// first section on the realm home. Null outside the realm route.

final class RoutedResourceFamily extends $Family
    with $FunctionalFamilyOverride<skir.ResourceId?, AuthoringScope> {
  RoutedResourceFamily._()
    : super(
        retry: null,
        name: r'routedResourceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The resource the realm route of [scope] shows: the routed resource, or the
  /// first section on the realm home. Null outside the realm route.

  RoutedResourceProvider call(AuthoringScope scope) =>
      RoutedResourceProvider._(argument: scope, from: this);

  @override
  String toString() => r'routedResourceProvider';
}

/// Whether the realm shell shows the side inspector beside [scope]'s routed
/// resource. A resource without a workspace shows its inspector in the main
/// area instead.

@ProviderFor(showsSideInspector)
final showsSideInspectorProvider = ShowsSideInspectorFamily._();

/// Whether the realm shell shows the side inspector beside [scope]'s routed
/// resource. A resource without a workspace shows its inspector in the main
/// area instead.

final class ShowsSideInspectorProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the realm shell shows the side inspector beside [scope]'s routed
  /// resource. A resource without a workspace shows its inspector in the main
  /// area instead.
  ShowsSideInspectorProvider._({
    required ShowsSideInspectorFamily super.from,
    required AuthoringScope super.argument,
  }) : super(
         retry: null,
         name: r'showsSideInspectorProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$showsSideInspectorHash();

  @override
  String toString() {
    return r'showsSideInspectorProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as AuthoringScope;
    return showsSideInspector(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ShowsSideInspectorProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$showsSideInspectorHash() =>
    r'c91fdb2b249adfcc78888a04cbe646e4c2ae23ac';

/// Whether the realm shell shows the side inspector beside [scope]'s routed
/// resource. A resource without a workspace shows its inspector in the main
/// area instead.

final class ShowsSideInspectorFamily extends $Family
    with $FunctionalFamilyOverride<bool, AuthoringScope> {
  ShowsSideInspectorFamily._()
    : super(
        retry: null,
        name: r'showsSideInspectorProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether the realm shell shows the side inspector beside [scope]'s routed
  /// resource. A resource without a workspace shows its inspector in the main
  /// area instead.

  ShowsSideInspectorProvider call(AuthoringScope scope) =>
      ShowsSideInspectorProvider._(argument: scope, from: this);

  @override
  String toString() => r'showsSideInspectorProvider';
}

/// The section of the realm root that holds [scope]'s routed resource, which
/// the shell sidebar marks as routed.

@ProviderFor(routedSection)
final routedSectionProvider = RoutedSectionFamily._();

/// The section of the realm root that holds [scope]'s routed resource, which
/// the shell sidebar marks as routed.

final class RoutedSectionProvider
    extends
        $FunctionalProvider<
          skir.ResourceId?,
          skir.ResourceId?,
          skir.ResourceId?
        >
    with $Provider<skir.ResourceId?> {
  /// The section of the realm root that holds [scope]'s routed resource, which
  /// the shell sidebar marks as routed.
  RoutedSectionProvider._({
    required RoutedSectionFamily super.from,
    required AuthoringScope super.argument,
  }) : super(
         retry: null,
         name: r'routedSectionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$routedSectionHash();

  @override
  String toString() {
    return r'routedSectionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<skir.ResourceId?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  skir.ResourceId? create(Ref ref) {
    final argument = this.argument as AuthoringScope;
    return routedSection(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(skir.ResourceId? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<skir.ResourceId?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RoutedSectionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$routedSectionHash() => r'91e888d0c0df31e2e055bc7ef0c604b04fedce90';

/// The section of the realm root that holds [scope]'s routed resource, which
/// the shell sidebar marks as routed.

final class RoutedSectionFamily extends $Family
    with $FunctionalFamilyOverride<skir.ResourceId?, AuthoringScope> {
  RoutedSectionFamily._()
    : super(
        retry: null,
        name: r'routedSectionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The section of the realm root that holds [scope]'s routed resource, which
  /// the shell sidebar marks as routed.

  RoutedSectionProvider call(AuthoringScope scope) =>
      RoutedSectionProvider._(argument: scope, from: this);

  @override
  String toString() => r'routedSectionProvider';
}

/// The breadcrumbs of [scope]'s routed resource.

@ProviderFor(resourceBreadcrumbs)
final resourceBreadcrumbsProvider = ResourceBreadcrumbsFamily._();

/// The breadcrumbs of [scope]'s routed resource.

final class ResourceBreadcrumbsProvider
    extends
        $FunctionalProvider<
          List<ResourceCrumb>,
          List<ResourceCrumb>,
          List<ResourceCrumb>
        >
    with $Provider<List<ResourceCrumb>> {
  /// The breadcrumbs of [scope]'s routed resource.
  ResourceBreadcrumbsProvider._({
    required ResourceBreadcrumbsFamily super.from,
    required AuthoringScope super.argument,
  }) : super(
         retry: null,
         name: r'resourceBreadcrumbsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$resourceBreadcrumbsHash();

  @override
  String toString() {
    return r'resourceBreadcrumbsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<ResourceCrumb>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<ResourceCrumb> create(Ref ref) {
    final argument = this.argument as AuthoringScope;
    return resourceBreadcrumbs(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ResourceCrumb> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ResourceCrumb>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ResourceBreadcrumbsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$resourceBreadcrumbsHash() =>
    r'a120425b34d86af01aba89f0e21a7732db4a25d5';

/// The breadcrumbs of [scope]'s routed resource.

final class ResourceBreadcrumbsFamily extends $Family
    with $FunctionalFamilyOverride<List<ResourceCrumb>, AuthoringScope> {
  ResourceBreadcrumbsFamily._()
    : super(
        retry: null,
        name: r'resourceBreadcrumbsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The breadcrumbs of [scope]'s routed resource.

  ResourceBreadcrumbsProvider call(AuthoringScope scope) =>
      ResourceBreadcrumbsProvider._(argument: scope, from: this);

  @override
  String toString() => r'resourceBreadcrumbsProvider';
}

/// Kept alive: navigation outlives the widget or provider that started it.

@ProviderFor(realmSurfaceNavigation)
final realmSurfaceNavigationProvider = RealmSurfaceNavigationProvider._();

/// Kept alive: navigation outlives the widget or provider that started it.

final class RealmSurfaceNavigationProvider
    extends
        $FunctionalProvider<
          RealmSurfaceNavigation,
          RealmSurfaceNavigation,
          RealmSurfaceNavigation
        >
    with $Provider<RealmSurfaceNavigation> {
  /// Kept alive: navigation outlives the widget or provider that started it.
  RealmSurfaceNavigationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'realmSurfaceNavigationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$realmSurfaceNavigationHash();

  @$internal
  @override
  $ProviderElement<RealmSurfaceNavigation> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RealmSurfaceNavigation create(Ref ref) {
    return realmSurfaceNavigation(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RealmSurfaceNavigation value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RealmSurfaceNavigation>(value),
    );
  }
}

String _$realmSurfaceNavigationHash() =>
    r'a1d0b59c27c10fce79db6a00d66255e1de6cd77b';

@ProviderFor(realmLocationReveal)
final realmLocationRevealProvider = RealmLocationRevealFamily._();

final class RealmLocationRevealProvider
    extends
        $FunctionalProvider<
          PortableLocationRevealController,
          PortableLocationRevealController,
          PortableLocationRevealController
        >
    with $Provider<PortableLocationRevealController> {
  RealmLocationRevealProvider._({
    required RealmLocationRevealFamily super.from,
    required AuthoringScope super.argument,
  }) : super(
         retry: null,
         name: r'realmLocationRevealProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$realmLocationRevealHash();

  @override
  String toString() {
    return r'realmLocationRevealProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<PortableLocationRevealController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PortableLocationRevealController create(Ref ref) {
    final argument = this.argument as AuthoringScope;
    return realmLocationReveal(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PortableLocationRevealController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PortableLocationRevealController>(
        value,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RealmLocationRevealProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$realmLocationRevealHash() =>
    r'12337a2749f89b993e297662a60e96771307aabc';

final class RealmLocationRevealFamily extends $Family
    with
        $FunctionalFamilyOverride<
          PortableLocationRevealController,
          AuthoringScope
        > {
  RealmLocationRevealFamily._()
    : super(
        retry: null,
        name: r'realmLocationRevealProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RealmLocationRevealProvider call(AuthoringScope scope) =>
      RealmLocationRevealProvider._(argument: scope, from: this);

  @override
  String toString() => r'realmLocationRevealProvider';
}
