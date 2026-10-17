// GENERATED CODE. DO NOT MODIFY BY HAND

part of 'realm_publication.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(realmPublicationRepository)
final realmPublicationRepositoryProvider = RealmPublicationRepositoryFamily._();

final class RealmPublicationRepositoryProvider
    extends
        $FunctionalProvider<
          RealmPublicationRepository,
          RealmPublicationRepository,
          RealmPublicationRepository
        >
    with $Provider<RealmPublicationRepository> {
  RealmPublicationRepositoryProvider._({
    required RealmPublicationRepositoryFamily super.from,
    required (skir.RecordId, skir.RecordId) super.argument,
  }) : super(
         retry: null,
         name: r'realmPublicationRepositoryProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$realmPublicationRepositoryHash();

  @override
  String toString() {
    return r'realmPublicationRepositoryProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<RealmPublicationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RealmPublicationRepository create(Ref ref) {
    final argument = this.argument as (skir.RecordId, skir.RecordId);
    return realmPublicationRepository(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RealmPublicationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RealmPublicationRepository>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RealmPublicationRepositoryProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$realmPublicationRepositoryHash() =>
    r'e52881cb58b7aa0ec99c6953fb4fb70429ac9d59';

final class RealmPublicationRepositoryFamily extends $Family
    with
        $FunctionalFamilyOverride<
          RealmPublicationRepository,
          (skir.RecordId, skir.RecordId)
        > {
  RealmPublicationRepositoryFamily._()
    : super(
        retry: null,
        name: r'realmPublicationRepositoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  RealmPublicationRepositoryProvider call(
    skir.RecordId organizationId,
    skir.RecordId realmId,
  ) => RealmPublicationRepositoryProvider._(
    argument: (organizationId, realmId),
    from: this,
  );

  @override
  String toString() => r'realmPublicationRepositoryProvider';
}

@ProviderFor(RealmPublication)
final realmPublicationProvider = RealmPublicationFamily._();

final class RealmPublicationProvider
    extends $StreamNotifierProvider<RealmPublication, RealmPublicationView> {
  RealmPublicationProvider._({
    required RealmPublicationFamily super.from,
    required (skir.RecordId, skir.RecordId) super.argument,
  }) : super(
         retry: null,
         name: r'realmPublicationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$realmPublicationHash();

  @override
  String toString() {
    return r'realmPublicationProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  RealmPublication create() => RealmPublication();

  @override
  bool operator ==(Object other) {
    return other is RealmPublicationProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$realmPublicationHash() => r'b07eb43249760d53b3e3e2ae73d6e1d954c634a3';

final class RealmPublicationFamily extends $Family
    with
        $ClassFamilyOverride<
          RealmPublication,
          AsyncValue<RealmPublicationView>,
          RealmPublicationView,
          Stream<RealmPublicationView>,
          (skir.RecordId, skir.RecordId)
        > {
  RealmPublicationFamily._()
    : super(
        retry: null,
        name: r'realmPublicationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RealmPublicationProvider call(
    skir.RecordId organizationId,
    skir.RecordId realmId,
  ) => RealmPublicationProvider._(
    argument: (organizationId, realmId),
    from: this,
  );

  @override
  String toString() => r'realmPublicationProvider';
}

abstract class _$RealmPublication
    extends $StreamNotifier<RealmPublicationView> {
  late final _$args = ref.$arg as (skir.RecordId, skir.RecordId);
  skir.RecordId get organizationId => _$args.$1;
  skir.RecordId get realmId => _$args.$2;

  Stream<RealmPublicationView> build(
    skir.RecordId organizationId,
    skir.RecordId realmId,
  );
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<RealmPublicationView>, RealmPublicationView>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<RealmPublicationView>,
                RealmPublicationView
              >,
              AsyncValue<RealmPublicationView>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
