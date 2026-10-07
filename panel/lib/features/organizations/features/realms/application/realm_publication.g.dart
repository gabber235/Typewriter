// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'realm_publication.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(realmPublicationSource)
final realmPublicationSourceProvider = RealmPublicationSourceFamily._();

final class RealmPublicationSourceProvider
    extends
        $FunctionalProvider<
          RealmPublicationSource,
          RealmPublicationSource,
          RealmPublicationSource
        >
    with $Provider<RealmPublicationSource> {
  RealmPublicationSourceProvider._({
    required RealmPublicationSourceFamily super.from,
    required (skir.RecordId, skir.RecordId) super.argument,
  }) : super(
         retry: null,
         name: r'realmPublicationSourceProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$realmPublicationSourceHash();

  @override
  String toString() {
    return r'realmPublicationSourceProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<RealmPublicationSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RealmPublicationSource create(Ref ref) {
    final argument = this.argument as (skir.RecordId, skir.RecordId);
    return realmPublicationSource(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RealmPublicationSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RealmPublicationSource>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RealmPublicationSourceProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$realmPublicationSourceHash() =>
    r'701b769e08eb8aece7c0f89578371e70db9d205d';

final class RealmPublicationSourceFamily extends $Family
    with
        $FunctionalFamilyOverride<
          RealmPublicationSource,
          (skir.RecordId, skir.RecordId)
        > {
  RealmPublicationSourceFamily._()
    : super(
        retry: null,
        name: r'realmPublicationSourceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  RealmPublicationSourceProvider call(
    skir.RecordId organizationId,
    skir.RecordId realmId,
  ) => RealmPublicationSourceProvider._(
    argument: (organizationId, realmId),
    from: this,
  );

  @override
  String toString() => r'realmPublicationSourceProvider';
}

@ProviderFor(RealmPublication)
final realmPublicationProvider = RealmPublicationFamily._();

final class RealmPublicationProvider
    extends $StreamNotifierProvider<RealmPublication, skir.PublicationReport?> {
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

String _$realmPublicationHash() => r'd90c55ffb43765e4cb15b303286cebd37dae8053';

final class RealmPublicationFamily extends $Family
    with
        $ClassFamilyOverride<
          RealmPublication,
          AsyncValue<skir.PublicationReport?>,
          skir.PublicationReport?,
          Stream<skir.PublicationReport?>,
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
    extends $StreamNotifier<skir.PublicationReport?> {
  late final _$args = ref.$arg as (skir.RecordId, skir.RecordId);
  skir.RecordId get organizationId => _$args.$1;
  skir.RecordId get realmId => _$args.$2;

  Stream<skir.PublicationReport?> build(
    skir.RecordId organizationId,
    skir.RecordId realmId,
  );
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<skir.PublicationReport?>,
              skir.PublicationReport?
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<skir.PublicationReport?>,
                skir.PublicationReport?
              >,
              AsyncValue<skir.PublicationReport?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
