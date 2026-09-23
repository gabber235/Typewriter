// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'realm_relation_field_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(relationFieldForResource)
final relationFieldForResourceProvider = RelationFieldForResourceFamily._();

final class RelationFieldForResourceProvider
    extends
        $FunctionalProvider<
          AsyncValue<RealmRelationField>,
          AsyncValue<RealmRelationField>,
          AsyncValue<RealmRelationField>
        >
    with $Provider<AsyncValue<RealmRelationField>> {
  RelationFieldForResourceProvider._({
    required RelationFieldForResourceFamily super.from,
    required (skir.ResourceId, DataPath) super.argument,
  }) : super(
         retry: null,
         name: r'relationFieldForResourceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$relationFieldForResourceHash();

  @override
  String toString() {
    return r'relationFieldForResourceProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<RealmRelationField>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<RealmRelationField> create(Ref ref) {
    final argument = this.argument as (skir.ResourceId, DataPath);
    return relationFieldForResource(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<RealmRelationField> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<RealmRelationField>>(
        value,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RelationFieldForResourceProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$relationFieldForResourceHash() =>
    r'2236b67fcfe6106d8709496f9d510877c37fae05';

final class RelationFieldForResourceFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AsyncValue<RealmRelationField>,
          (skir.ResourceId, DataPath)
        > {
  RelationFieldForResourceFamily._()
    : super(
        retry: null,
        name: r'relationFieldForResourceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RelationFieldForResourceProvider call(skir.ResourceId owner, DataPath path) =>
      RelationFieldForResourceProvider._(argument: (owner, path), from: this);

  @override
  String toString() => r'relationFieldForResourceProvider';
}
