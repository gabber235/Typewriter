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
/// presentation. Mutations use operation identities and optimistic revisions;
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
/// presentation. Mutations use operation identities and optimistic revisions;
/// conflicts update this projection with the backend value before returning a
/// conflict result so the caller can refresh or merge.
final class CanonicalOrganizationServicesProvider
    extends
        $StreamNotifierProvider<CanonicalOrganizationServices, List<Service>> {
  /// Owns the organization scoped canonical service identity projection.
  ///
  /// The provider combines the backend watch with committed mutation results
  /// published by the resource repository. Its state is canonical, while
  /// [projectedServices] and [projectedService] overlay unsaved editor values for
  /// presentation. Mutations use operation identities and optimistic revisions;
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
    r'ca7f3899d62573786c7d08d150f840767584f6a1';

/// Owns the organization scoped canonical service identity projection.
///
/// The provider combines the backend watch with committed mutation results
/// published by the resource repository. Its state is canonical, while
/// [projectedServices] and [projectedService] overlay unsaved editor values for
/// presentation. Mutations use operation identities and optimistic revisions;
/// conflicts update this projection with the backend value before returning a
/// conflict result so the caller can refresh or merge.

final class CanonicalOrganizationServicesFamily extends $Family
    with
        $ClassFamilyOverride<
          CanonicalOrganizationServices,
          AsyncValue<List<Service>>,
          List<Service>,
          Stream<List<Service>>,
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
  /// presentation. Mutations use operation identities and optimistic revisions;
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
/// presentation. Mutations use operation identities and optimistic revisions;
/// conflicts update this projection with the backend value before returning a
/// conflict result so the caller can refresh or merge.

abstract class _$CanonicalOrganizationServices
    extends $StreamNotifier<List<Service>> {
  late final _$args = ref.$arg as skir.RecordId;
  skir.RecordId get organizationId => _$args;

  Stream<List<Service>> build(skir.RecordId organizationId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Service>>, List<Service>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Service>>, List<Service>>,
              AsyncValue<List<Service>>,
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
        $FunctionalProvider<AsyncValue<Service?>, Service?, FutureOr<Service?>>
    with $FutureModifier<Service?>, $FutureProvider<Service?> {
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
  $FutureProviderElement<Service?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Service?> create(Ref ref) {
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

String _$canonicalServiceHash() => r'b4cabbb3f59a4a93bb98b2074038a92c916a1661';

/// Resolves one service from the organization scoped canonical projection.
///
/// A missing identifier is a normal absent result, not a transport failure.

final class CanonicalServiceFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Service?>, skir.RecordId> {
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

/// Adapts the organization scoped service projection to the current route.
///
/// The route provider owns no service data. It follows the selected
/// organization and delegates reads and mutations to
/// [CanonicalOrganizationServices], yielding an empty projection when no
/// organization is selected.

@ProviderFor(CanonicalServices)
final canonicalServicesProvider = CanonicalServicesProvider._();

/// Adapts the organization scoped service projection to the current route.
///
/// The route provider owns no service data. It follows the selected
/// organization and delegates reads and mutations to
/// [CanonicalOrganizationServices], yielding an empty projection when no
/// organization is selected.
final class CanonicalServicesProvider
    extends $StreamNotifierProvider<CanonicalServices, List<Service>> {
  /// Adapts the organization scoped service projection to the current route.
  ///
  /// The route provider owns no service data. It follows the selected
  /// organization and delegates reads and mutations to
  /// [CanonicalOrganizationServices], yielding an empty projection when no
  /// organization is selected.
  CanonicalServicesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'canonicalServicesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$canonicalServicesHash();

  @$internal
  @override
  CanonicalServices create() => CanonicalServices();
}

String _$canonicalServicesHash() => r'068de9cecaf6154f42b023858fd20ea83e4ee603';

/// Adapts the organization scoped service projection to the current route.
///
/// The route provider owns no service data. It follows the selected
/// organization and delegates reads and mutations to
/// [CanonicalOrganizationServices], yielding an empty projection when no
/// organization is selected.

abstract class _$CanonicalServices extends $StreamNotifier<List<Service>> {
  Stream<List<Service>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Service>>, List<Service>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Service>>, List<Service>>,
              AsyncValue<List<Service>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

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
          AsyncValue<List<Service>>,
          AsyncValue<List<Service>>,
          AsyncValue<List<Service>>
        >
    with $Provider<AsyncValue<List<Service>>> {
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
  $ProviderElement<AsyncValue<List<Service>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<Service>> create(Ref ref) {
    return projectedServices(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<Service>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<Service>>>(value),
    );
  }
}

String _$projectedServicesHash() => r'3b12ff8d3f1dfb2b264c2cc7604208167e89d319';

/// Resolves one service with its unsaved local identity draft applied.

@ProviderFor(projectedService)
final projectedServiceProvider = ProjectedServiceFamily._();

/// Resolves one service with its unsaved local identity draft applied.

final class ProjectedServiceProvider
    extends
        $FunctionalProvider<
          AsyncValue<Service?>,
          AsyncValue<Service?>,
          AsyncValue<Service?>
        >
    with $Provider<AsyncValue<Service?>> {
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
  $ProviderElement<AsyncValue<Service?>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<Service?> create(Ref ref) {
    final argument = this.argument as skir.RecordId;
    return projectedService(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<Service?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<Service?>>(value),
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

String _$projectedServiceHash() => r'a8ae591bfa8d83435ff7659db7a81506ebafec2d';

/// Resolves one service with its unsaved local identity draft applied.

final class ProjectedServiceFamily extends $Family
    with $FunctionalFamilyOverride<AsyncValue<Service?>, skir.RecordId> {
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
/// [OrganizationTopologyController] and yields an empty topology without an
/// organization.

@ProviderFor(organizationTopologyStream)
final organizationTopologyStreamProvider =
    OrganizationTopologyStreamProvider._();

/// Exposes topology for the organization selected by the current route.
///
/// The route projection delegates lifecycle and reconciliation to
/// [OrganizationTopologyController] and yields an empty topology without an
/// organization.

final class OrganizationTopologyStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<OrganizationTopology>,
          OrganizationTopology,
          Stream<OrganizationTopology>
        >
    with
        $FutureModifier<OrganizationTopology>,
        $StreamProvider<OrganizationTopology> {
  /// Exposes topology for the organization selected by the current route.
  ///
  /// The route projection delegates lifecycle and reconciliation to
  /// [OrganizationTopologyController] and yields an empty topology without an
  /// organization.
  OrganizationTopologyStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'organizationTopologyStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$organizationTopologyStreamHash();

  @$internal
  @override
  $StreamProviderElement<OrganizationTopology> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<OrganizationTopology> create(Ref ref) {
    return organizationTopologyStream(ref);
  }
}

String _$organizationTopologyStreamHash() =>
    r'9bb2fbcc6854c48e401a910ea007417828c91951';

/// Owns the live organization topology projection.
///
/// The projection combines the topology watch with committed configuration
/// changes from [ServiceResourceRepository]. [TopologyHost] contains desired
/// and applied configuration revisions alongside host runtime observations;
/// child realm and engine entries describe the resources currently reported by
/// that host. A topology entry is therefore not another service identity.
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
/// The projection combines the topology watch with committed configuration
/// changes from [ServiceResourceRepository]. [TopologyHost] contains desired
/// and applied configuration revisions alongside host runtime observations;
/// child realm and engine entries describe the resources currently reported by
/// that host. A topology entry is therefore not another service identity.
///
/// Consumers may use the projection to display current backend knowledge and
/// to choose configuration targets. They must not treat desired configuration
/// as proof that runtime resources are active, or infer service identity fields
/// from a host without resolving its service identifier.
final class OrganizationTopologyControllerProvider
    extends
        $StreamNotifierProvider<
          OrganizationTopologyController,
          OrganizationTopology
        > {
  /// Owns the live organization topology projection.
  ///
  /// The projection combines the topology watch with committed configuration
  /// changes from [ServiceResourceRepository]. [TopologyHost] contains desired
  /// and applied configuration revisions alongside host runtime observations;
  /// child realm and engine entries describe the resources currently reported by
  /// that host. A topology entry is therefore not another service identity.
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
    r'aa04502bebbe260b8e17dd4179f734ea8567b85c';

/// Owns the live organization topology projection.
///
/// The projection combines the topology watch with committed configuration
/// changes from [ServiceResourceRepository]. [TopologyHost] contains desired
/// and applied configuration revisions alongside host runtime observations;
/// child realm and engine entries describe the resources currently reported by
/// that host. A topology entry is therefore not another service identity.
///
/// Consumers may use the projection to display current backend knowledge and
/// to choose configuration targets. They must not treat desired configuration
/// as proof that runtime resources are active, or infer service identity fields
/// from a host without resolving its service identifier.

final class OrganizationTopologyControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          OrganizationTopologyController,
          AsyncValue<OrganizationTopology>,
          OrganizationTopology,
          Stream<OrganizationTopology>,
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
  /// The projection combines the topology watch with committed configuration
  /// changes from [ServiceResourceRepository]. [TopologyHost] contains desired
  /// and applied configuration revisions alongside host runtime observations;
  /// child realm and engine entries describe the resources currently reported by
  /// that host. A topology entry is therefore not another service identity.
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
/// The projection combines the topology watch with committed configuration
/// changes from [ServiceResourceRepository]. [TopologyHost] contains desired
/// and applied configuration revisions alongside host runtime observations;
/// child realm and engine entries describe the resources currently reported by
/// that host. A topology entry is therefore not another service identity.
///
/// Consumers may use the projection to display current backend knowledge and
/// to choose configuration targets. They must not treat desired configuration
/// as proof that runtime resources are active, or infer service identity fields
/// from a host without resolving its service identifier.

abstract class _$OrganizationTopologyController
    extends $StreamNotifier<OrganizationTopology> {
  late final _$args = ref.$arg as skir.RecordId;
  skir.RecordId get organizationId => _$args;

  Stream<OrganizationTopology> build(skir.RecordId organizationId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<OrganizationTopology>, OrganizationTopology>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<OrganizationTopology>,
                OrganizationTopology
              >,
              AsyncValue<OrganizationTopology>,
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
    r'81da9210c2a948b562f83b91902888be9edf7f2d';

/// Resolves host connectivity through its linked service heartbeat.
///
/// Host runtime status describes reconciliation, not transport reachability.
/// This provider therefore follows [TopologyHost.serviceId] into the shared
/// service deadline projection and returns false when either record is absent.

@ProviderFor(hostConnected)
final hostConnectedProvider = HostConnectedFamily._();

/// Resolves host connectivity through its linked service heartbeat.
///
/// Host runtime status describes reconciliation, not transport reachability.
/// This provider therefore follows [TopologyHost.serviceId] into the shared
/// service deadline projection and returns false when either record is absent.

final class HostConnectedProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Resolves host connectivity through its linked service heartbeat.
  ///
  /// Host runtime status describes reconciliation, not transport reachability.
  /// This provider therefore follows [TopologyHost.serviceId] into the shared
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

String _$hostConnectedHash() => r'09b1ee4918132ecf7c243b785b39033369b3ff63';

/// Resolves host connectivity through its linked service heartbeat.
///
/// Host runtime status describes reconciliation, not transport reachability.
/// This provider therefore follows [TopologyHost.serviceId] into the shared
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
  /// This provider therefore follows [TopologyHost.serviceId] into the shared
  /// service deadline projection and returns false when either record is absent.

  HostConnectedProvider call(skir.RecordId hostId) =>
      HostConnectedProvider._(argument: hostId, from: this);

  @override
  String toString() => r'hostConnectedProvider';
}
