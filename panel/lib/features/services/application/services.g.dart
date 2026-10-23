// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'services.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns the organization scoped canonical service identity projection.
///
/// The provider combines the backend watch with committed mutation results
/// published by the resource repository. Its state is canonical, while
/// [projectedServices] and [projectedService] overlay unsaved editor values for
/// presentation. Mutations use optimistic revisions;
/// conflicts update this projection with the backend value before returning a
/// conflict result so the caller can refresh or merge.

@ProviderFor(CanonicalOrganizationServices)
final canonicalOrganizationServicesProvider =
    CanonicalOrganizationServicesFamily._();

/// Owns the organization scoped canonical service identity projection.
///
/// The provider combines the backend watch with committed mutation results
/// published by the resource repository. Its state is canonical, while
/// [projectedServices] and [projectedService] overlay unsaved editor values for
/// presentation. Mutations use optimistic revisions;
/// conflicts update this projection with the backend value before returning a
/// conflict result so the caller can refresh or merge.
final class CanonicalOrganizationServicesProvider
    extends
        $StreamNotifierProvider<
          CanonicalOrganizationServices,
          List<skir.Service>
        > {
  /// Owns the organization scoped canonical service identity projection.
  ///
  /// The provider combines the backend watch with committed mutation results
  /// published by the resource repository. Its state is canonical, while
  /// [projectedServices] and [projectedService] overlay unsaved editor values for
  /// presentation. Mutations use optimistic revisions;
  /// conflicts update this projection with the backend value before returning a
  /// conflict result so the caller can refresh or merge.
  CanonicalOrganizationServicesProvider._({
    required CanonicalOrganizationServicesFamily super.from,
    required skir.RecordId super.argument,
  }) : super(
         retry: null,
         name: r'canonicalOrganizationServicesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$canonicalOrganizationServicesHash();

  @override
  String toString() {
    return r'canonicalOrganizationServicesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CanonicalOrganizationServices create() => CanonicalOrganizationServices();

  @override
  bool operator ==(Object other) {
    return other is CanonicalOrganizationServicesProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$canonicalOrganizationServicesHash() =>
    r'8c8b42d69ff5882417a21739d0818892e3b074a0';

/// Owns the organization scoped canonical service identity projection.
///
/// The provider combines the backend watch with committed mutation results
/// published by the resource repository. Its state is canonical, while
/// [projectedServices] and [projectedService] overlay unsaved editor values for
/// presentation. Mutations use optimistic revisions;
/// conflicts update this projection with the backend value before returning a
/// conflict result so the caller can refresh or merge.

final class CanonicalOrganizationServicesFamily extends $Family
    with
        $ClassFamilyOverride<
          CanonicalOrganizationServices,
          AsyncValue<List<skir.Service>>,
          List<skir.Service>,
          Stream<List<skir.Service>>,
          skir.RecordId
        > {
  CanonicalOrganizationServicesFamily._()
    : super(
        retry: null,
        name: r'canonicalOrganizationServicesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Owns the organization scoped canonical service identity projection.
  ///
  /// The provider combines the backend watch with committed mutation results
  /// published by the resource repository. Its state is canonical, while
  /// [projectedServices] and [projectedService] overlay unsaved editor values for
  /// presentation. Mutations use optimistic revisions;
  /// conflicts update this projection with the backend value before returning a
  /// conflict result so the caller can refresh or merge.

  CanonicalOrganizationServicesProvider call(skir.RecordId organizationId) =>
      CanonicalOrganizationServicesProvider._(
        argument: organizationId,
        from: this,
      );

  @override
  String toString() => r'canonicalOrganizationServicesProvider';
}

/// Owns the organization scoped canonical service identity projection.
///
/// The provider combines the backend watch with committed mutation results
/// published by the resource repository. Its state is canonical, while
/// [projectedServices] and [projectedService] overlay unsaved editor values for
/// presentation. Mutations use optimistic revisions;
/// conflicts update this projection with the backend value before returning a
/// conflict result so the caller can refresh or merge.

abstract class _$CanonicalOrganizationServices
    extends $StreamNotifier<List<skir.Service>> {
  late final _$args = ref.$arg as skir.RecordId;
  skir.RecordId get organizationId => _$args;

  Stream<List<skir.Service>> build(skir.RecordId organizationId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<skir.Service>>, List<skir.Service>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<skir.Service>>, List<skir.Service>>,
              AsyncValue<List<skir.Service>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Resolves one service from the organization scoped canonical projection.
///
/// A missing identifier is a normal absent result, not a transport failure.

@ProviderFor(canonicalService)
final canonicalServiceProvider = CanonicalServiceFamily._();

/// Resolves one service from the organization scoped canonical projection.
///
/// A missing identifier is a normal absent result, not a transport failure.

final class CanonicalServiceProvider
    extends
        $FunctionalProvider<
          AsyncValue<skir.Service?>,
          skir.Service?,
          FutureOr<skir.Service?>
        >
    with $FutureModifier<skir.Service?>, $FutureProvider<skir.Service?> {
  /// Resolves one service from the organization scoped canonical projection.
  ///
  /// A missing identifier is a normal absent result, not a transport failure.
  CanonicalServiceProvider._({
    required CanonicalServiceFamily super.from,
    required skir.RecordId super.argument,
  }) : super(
         retry: null,
         name: r'canonicalServiceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$canonicalServiceHash();

  @override
  String toString() {
    return r'canonicalServiceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<skir.Service?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<skir.Service?> create(Ref ref) {
    final argument = this.argument as skir.RecordId;
    return canonicalService(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CanonicalServiceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$canonicalServiceHash() => r'77b86d5ef72eee1ddb6bde3ebbbab9a5fd4630d8';

/// Resolves one service from the organization scoped canonical projection.
///
/// A missing identifier is a normal absent result, not a transport failure.

final class CanonicalServiceFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<skir.Service?>, skir.RecordId> {
  CanonicalServiceFamily._()
    : super(
        retry: null,
        name: r'canonicalServiceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Resolves one service from the organization scoped canonical projection.
  ///
  /// A missing identifier is a normal absent result, not a transport failure.

  CanonicalServiceProvider call(skir.RecordId id) =>
      CanonicalServiceProvider._(argument: id, from: this);

  @override
  String toString() => r'canonicalServiceProvider';
}

/// Owns the live organization topology projection.
///
/// The projection combines the topology watch with canonical configuration
/// replies from [ServiceResourceRepository]. [skir.ServiceHost] contains desired
/// and applied configuration revisions alongside host runtime observations.
/// Snapshots and configuration changes own child membership. Runtime reports
/// update observed state only and cannot create or revive child resources. A
/// topology entry is therefore not another service identity.
///
/// Consumers may use the projection to display current backend knowledge and
/// to choose configuration targets. They must not treat desired configuration
/// as proof that runtime resources are active, or infer service identity fields
/// from a host without resolving its service identifier.

@ProviderFor(OrganizationTopologyController)
final organizationTopologyControllerProvider =
    OrganizationTopologyControllerFamily._();

/// Owns the live organization topology projection.
///
/// The projection combines the topology watch with canonical configuration
/// replies from [ServiceResourceRepository]. [skir.ServiceHost] contains desired
/// and applied configuration revisions alongside host runtime observations.
/// Snapshots and configuration changes own child membership. Runtime reports
/// update observed state only and cannot create or revive child resources. A
/// topology entry is therefore not another service identity.
///
/// Consumers may use the projection to display current backend knowledge and
/// to choose configuration targets. They must not treat desired configuration
/// as proof that runtime resources are active, or infer service identity fields
/// from a host without resolving its service identifier.
final class OrganizationTopologyControllerProvider
    extends
        $StreamNotifierProvider<
          OrganizationTopologyController,
          skir.OrganizationTopologySnapshot
        > {
  /// Owns the live organization topology projection.
  ///
  /// The projection combines the topology watch with canonical configuration
  /// replies from [ServiceResourceRepository]. [skir.ServiceHost] contains desired
  /// and applied configuration revisions alongside host runtime observations.
  /// Snapshots and configuration changes own child membership. Runtime reports
  /// update observed state only and cannot create or revive child resources. A
  /// topology entry is therefore not another service identity.
  ///
  /// Consumers may use the projection to display current backend knowledge and
  /// to choose configuration targets. They must not treat desired configuration
  /// as proof that runtime resources are active, or infer service identity fields
  /// from a host without resolving its service identifier.
  OrganizationTopologyControllerProvider._({
    required OrganizationTopologyControllerFamily super.from,
    required skir.RecordId super.argument,
  }) : super(
         retry: null,
         name: r'organizationTopologyControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$organizationTopologyControllerHash();

  @override
  String toString() {
    return r'organizationTopologyControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  OrganizationTopologyController create() => OrganizationTopologyController();

  @override
  bool operator ==(Object other) {
    return other is OrganizationTopologyControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$organizationTopologyControllerHash() =>
    r'b4fdc45ff0a804156b1bd5f57e11afe21780fe4d';

/// Owns the live organization topology projection.
///
/// The projection combines the topology watch with canonical configuration
/// replies from [ServiceResourceRepository]. [skir.ServiceHost] contains desired
/// and applied configuration revisions alongside host runtime observations.
/// Snapshots and configuration changes own child membership. Runtime reports
/// update observed state only and cannot create or revive child resources. A
/// topology entry is therefore not another service identity.
///
/// Consumers may use the projection to display current backend knowledge and
/// to choose configuration targets. They must not treat desired configuration
/// as proof that runtime resources are active, or infer service identity fields
/// from a host without resolving its service identifier.

final class OrganizationTopologyControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          OrganizationTopologyController,
          AsyncValue<skir.OrganizationTopologySnapshot>,
          skir.OrganizationTopologySnapshot,
          Stream<skir.OrganizationTopologySnapshot>,
          skir.RecordId
        > {
  OrganizationTopologyControllerFamily._()
    : super(
        retry: null,
        name: r'organizationTopologyControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Owns the live organization topology projection.
  ///
  /// The projection combines the topology watch with canonical configuration
  /// replies from [ServiceResourceRepository]. [skir.ServiceHost] contains desired
  /// and applied configuration revisions alongside host runtime observations.
  /// Snapshots and configuration changes own child membership. Runtime reports
  /// update observed state only and cannot create or revive child resources. A
  /// topology entry is therefore not another service identity.
  ///
  /// Consumers may use the projection to display current backend knowledge and
  /// to choose configuration targets. They must not treat desired configuration
  /// as proof that runtime resources are active, or infer service identity fields
  /// from a host without resolving its service identifier.

  OrganizationTopologyControllerProvider call(skir.RecordId organizationId) =>
      OrganizationTopologyControllerProvider._(
        argument: organizationId,
        from: this,
      );

  @override
  String toString() => r'organizationTopologyControllerProvider';
}

/// Owns the live organization topology projection.
///
/// The projection combines the topology watch with canonical configuration
/// replies from [ServiceResourceRepository]. [skir.ServiceHost] contains desired
/// and applied configuration revisions alongside host runtime observations.
/// Snapshots and configuration changes own child membership. Runtime reports
/// update observed state only and cannot create or revive child resources. A
/// topology entry is therefore not another service identity.
///
/// Consumers may use the projection to display current backend knowledge and
/// to choose configuration targets. They must not treat desired configuration
/// as proof that runtime resources are active, or infer service identity fields
/// from a host without resolving its service identifier.

abstract class _$OrganizationTopologyController
    extends $StreamNotifier<skir.OrganizationTopologySnapshot> {
  late final _$args = ref.$arg as skir.RecordId;
  skir.RecordId get organizationId => _$args;

  Stream<skir.OrganizationTopologySnapshot> build(skir.RecordId organizationId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<skir.OrganizationTopologySnapshot>,
              skir.OrganizationTopologySnapshot
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<skir.OrganizationTopologySnapshot>,
                skir.OrganizationTopologySnapshot
              >,
              AsyncValue<skir.OrganizationTopologySnapshot>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Shares one deadline projection for a service list across its consumers.

@ProviderFor(serviceConnections)
final serviceConnectionsProvider = ServiceConnectionsProvider._();

/// Shares one deadline projection for a service list across its consumers.

final class ServiceConnectionsProvider
    extends
        $FunctionalProvider<
          Map<skir.RecordId, bool>,
          Map<skir.RecordId, bool>,
          Map<skir.RecordId, bool>
        >
    with $Provider<Map<skir.RecordId, bool>> {
  /// Shares one deadline projection for a service list across its consumers.
  ServiceConnectionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serviceConnectionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serviceConnectionsHash();

  @$internal
  @override
  $ProviderElement<Map<skir.RecordId, bool>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<skir.RecordId, bool> create(Ref ref) {
    return serviceConnections(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<skir.RecordId, bool> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<skir.RecordId, bool>>(value),
    );
  }
}

String _$serviceConnectionsHash() =>
    r'79795a576937e494a0c747506ea3f8418a507412';

/// Resolves host connectivity through its linked service heartbeat.
///
/// Host runtime status describes reconciliation, not transport reachability.
/// This provider therefore follows [skir.ServiceHost.serviceId] into the shared
/// service deadline projection and returns false when either record is absent.

@ProviderFor(hostConnected)
final hostConnectedProvider = HostConnectedFamily._();

/// Resolves host connectivity through its linked service heartbeat.
///
/// Host runtime status describes reconciliation, not transport reachability.
/// This provider therefore follows [skir.ServiceHost.serviceId] into the shared
/// service deadline projection and returns false when either record is absent.

final class HostConnectedProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Resolves host connectivity through its linked service heartbeat.
  ///
  /// Host runtime status describes reconciliation, not transport reachability.
  /// This provider therefore follows [skir.ServiceHost.serviceId] into the shared
  /// service deadline projection and returns false when either record is absent.
  HostConnectedProvider._({
    required HostConnectedFamily super.from,
    required skir.RecordId super.argument,
  }) : super(
         retry: null,
         name: r'hostConnectedProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$hostConnectedHash();

  @override
  String toString() {
    return r'hostConnectedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as skir.RecordId;
    return hostConnected(ref, argument);
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
    return other is HostConnectedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$hostConnectedHash() => r'0de38fbae6e101f0292ab3e1283be5a8fad89257';

/// Resolves host connectivity through its linked service heartbeat.
///
/// Host runtime status describes reconciliation, not transport reachability.
/// This provider therefore follows [skir.ServiceHost.serviceId] into the shared
/// service deadline projection and returns false when either record is absent.

final class HostConnectedFamily extends $Family
    with $FunctionalFamilyOverride<bool, skir.RecordId> {
  HostConnectedFamily._()
    : super(
        retry: null,
        name: r'hostConnectedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Resolves host connectivity through its linked service heartbeat.
  ///
  /// Host runtime status describes reconciliation, not transport reachability.
  /// This provider therefore follows [skir.ServiceHost.serviceId] into the shared
  /// service deadline projection and returns false when either record is absent.

  HostConnectedProvider call(skir.RecordId hostId) =>
      HostConnectedProvider._(argument: hostId, from: this);

  @override
  String toString() => r'hostConnectedProvider';
}

/// Adapts the organization scoped service projection to the current route.
///
/// The route provider owns no service data. It follows the selected
/// organization and watches [CanonicalOrganizationServices], returning an empty
/// projection when no organization is selected.
/// Ready observations propagate synchronously so a heartbeat does not create
/// a loading interval. An actual source refresh retains its pending state.

@ProviderFor(canonicalServices)
final canonicalServicesProvider = CanonicalServicesProvider._();

/// Adapts the organization scoped service projection to the current route.
///
/// The route provider owns no service data. It follows the selected
/// organization and watches [CanonicalOrganizationServices], returning an empty
/// projection when no organization is selected.
/// Ready observations propagate synchronously so a heartbeat does not create
/// a loading interval. An actual source refresh retains its pending state.

final class CanonicalServicesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<skir.Service>>,
          List<skir.Service>,
          FutureOr<List<skir.Service>>
        >
    with
        $FutureModifier<List<skir.Service>>,
        $FutureProvider<List<skir.Service>> {
  /// Adapts the organization scoped service projection to the current route.
  ///
  /// The route provider owns no service data. It follows the selected
  /// organization and watches [CanonicalOrganizationServices], returning an empty
  /// projection when no organization is selected.
  /// Ready observations propagate synchronously so a heartbeat does not create
  /// a loading interval. An actual source refresh retains its pending state.
  CanonicalServicesProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRouteRetry,
        name: r'canonicalServicesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$canonicalServicesHash();

  @$internal
  @override
  $FutureProviderElement<List<skir.Service>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<skir.Service>> create(Ref ref) {
    return canonicalServices(ref);
  }
}

String _$canonicalServicesHash() => r'4bd39c3bb1e35442d334fc2f4f228da58e01b695';

/// Overlays active local editor drafts on canonical service identities.
///
/// Canonical revisions and runtime observations remain untouched. Consumers
/// that render editable names should use this projection, while mutation
/// preparation must retain the canonical snapshot.

@ProviderFor(projectedServices)
final projectedServicesProvider = ProjectedServicesProvider._();

/// Overlays active local editor drafts on canonical service identities.
///
/// Canonical revisions and runtime observations remain untouched. Consumers
/// that render editable names should use this projection, while mutation
/// preparation must retain the canonical snapshot.

final class ProjectedServicesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<skir.Service>>,
          AsyncValue<List<skir.Service>>,
          AsyncValue<List<skir.Service>>
        >
    with $Provider<AsyncValue<List<skir.Service>>> {
  /// Overlays active local editor drafts on canonical service identities.
  ///
  /// Canonical revisions and runtime observations remain untouched. Consumers
  /// that render editable names should use this projection, while mutation
  /// preparation must retain the canonical snapshot.
  ProjectedServicesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectedServicesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectedServicesHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<skir.Service>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<skir.Service>> create(Ref ref) {
    return projectedServices(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<skir.Service>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<skir.Service>>>(
        value,
      ),
    );
  }
}

String _$projectedServicesHash() => r'5cbee7da16318852d43dbe9be3e7ab581436c7f8';

/// Resolves one service with its unsaved local identity draft applied.

@ProviderFor(projectedService)
final projectedServiceProvider = ProjectedServiceFamily._();

/// Resolves one service with its unsaved local identity draft applied.

final class ProjectedServiceProvider
    extends
        $FunctionalProvider<
          AsyncValue<skir.Service?>,
          AsyncValue<skir.Service?>,
          AsyncValue<skir.Service?>
        >
    with $Provider<AsyncValue<skir.Service?>> {
  /// Resolves one service with its unsaved local identity draft applied.
  ProjectedServiceProvider._({
    required ProjectedServiceFamily super.from,
    required skir.RecordId super.argument,
  }) : super(
         retry: null,
         name: r'projectedServiceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$projectedServiceHash();

  @override
  String toString() {
    return r'projectedServiceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<skir.Service?>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<skir.Service?> create(Ref ref) {
    final argument = this.argument as skir.RecordId;
    return projectedService(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<skir.Service?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<skir.Service?>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProjectedServiceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$projectedServiceHash() => r'21178cd32133cfcd399698eabb3beba2ebd1073d';

/// Resolves one service with its unsaved local identity draft applied.

final class ProjectedServiceFamily extends $Family
    with $FunctionalFamilyOverride<AsyncValue<skir.Service?>, skir.RecordId> {
  ProjectedServiceFamily._()
    : super(
        retry: null,
        name: r'projectedServiceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Resolves one service with its unsaved local identity draft applied.

  ProjectedServiceProvider call(skir.RecordId serviceId) =>
      ProjectedServiceProvider._(argument: serviceId, from: this);

  @override
  String toString() => r'projectedServiceProvider';
}

/// Exposes topology for the organization selected by the current route.
///
/// The route projection delegates lifecycle and reconciliation to
/// [OrganizationTopologyController] and returns an empty topology without an
/// organization. Each canonical update recomputes this route projection.
/// Projection updates are synchronous; only an unresolved source can introduce
/// a loading state for consumers such as the realm interaction gate.

@ProviderFor(organizationTopology)
final organizationTopologyProvider = OrganizationTopologyProvider._();

/// Exposes topology for the organization selected by the current route.
///
/// The route projection delegates lifecycle and reconciliation to
/// [OrganizationTopologyController] and returns an empty topology without an
/// organization. Each canonical update recomputes this route projection.
/// Projection updates are synchronous; only an unresolved source can introduce
/// a loading state for consumers such as the realm interaction gate.

final class OrganizationTopologyProvider
    extends
        $FunctionalProvider<
          AsyncValue<skir.OrganizationTopologySnapshot>,
          skir.OrganizationTopologySnapshot,
          FutureOr<skir.OrganizationTopologySnapshot>
        >
    with
        $FutureModifier<skir.OrganizationTopologySnapshot>,
        $FutureProvider<skir.OrganizationTopologySnapshot> {
  /// Exposes topology for the organization selected by the current route.
  ///
  /// The route projection delegates lifecycle and reconciliation to
  /// [OrganizationTopologyController] and returns an empty topology without an
  /// organization. Each canonical update recomputes this route projection.
  /// Projection updates are synchronous; only an unresolved source can introduce
  /// a loading state for consumers such as the realm interaction gate.
  OrganizationTopologyProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRouteRetry,
        name: r'organizationTopologyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$organizationTopologyHash();

  @$internal
  @override
  $FutureProviderElement<skir.OrganizationTopologySnapshot> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<skir.OrganizationTopologySnapshot> create(Ref ref) {
    return organizationTopology(ref);
  }
}

String _$organizationTopologyHash() =>
    r'7fcd091267f37c1a8ff4bbb6bffb66a8836e7faa';
