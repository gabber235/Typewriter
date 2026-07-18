// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entries.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DefinitionPageEntry _$DefinitionPageEntryFromJson(Map<String, dynamic> json) =>
    DefinitionPageEntry(
      definition: EntryDefinition.fromJson(
        json['definition'] as Map<String, dynamic>,
      ),
      $type: json['_kind'] as String?,
    );

Map<String, dynamic> _$DefinitionPageEntryToJson(
  DefinitionPageEntry instance,
) => <String, dynamic>{
  'definition': instance.definition.toJson(),
  '_kind': instance.$type,
};

ReferencePageEntry _$ReferencePageEntryFromJson(Map<String, dynamic> json) =>
    ReferencePageEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      blueprint: ElementBlueprint.fromJson(
        json['blueprint'] as Map<String, dynamic>,
      ),
      pageId: json['pageId'] as String,
      metadata:
          (json['metadata'] as List<dynamic>?)
              ?.map((e) => EntryMetadata.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      $type: json['_kind'] as String?,
    );

Map<String, dynamic> _$ReferencePageEntryToJson(ReferencePageEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'blueprint': instance.blueprint.toJson(),
      'pageId': instance.pageId,
      'metadata': instance.metadata.map((e) => e.toJson()).toList(),
      '_kind': instance.$type,
    };

NonexistentPageEntry _$NonexistentPageEntryFromJson(
  Map<String, dynamic> json,
) => NonexistentPageEntry(
  id: json['id'] as String,
  $type: json['_kind'] as String?,
);

Map<String, dynamic> _$NonexistentPageEntryToJson(
  NonexistentPageEntry instance,
) => <String, dynamic>{'id': instance.id, '_kind': instance.$type};

NoBlueprintPageEntry _$NoBlueprintPageEntryFromJson(
  Map<String, dynamic> json,
) => NoBlueprintPageEntry(
  id: json['id'] as String,
  name: json['name'] as String,
  placement: EntryPlacement.fromJson(json['placement'] as Map<String, dynamic>),
  inwardLinks: (json['inwardLinks'] as List<dynamic>)
      .map((e) => ElementLink.fromJson(e as Map<String, dynamic>))
      .toList(),
  outwardLinks: (json['outwardLinks'] as List<dynamic>)
      .map((e) => ElementLink.fromJson(e as Map<String, dynamic>))
      .toList(),
  metadata:
      (json['metadata'] as List<dynamic>?)
          ?.map((e) => EntryMetadata.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  $type: json['_kind'] as String?,
);

Map<String, dynamic> _$NoBlueprintPageEntryToJson(
  NoBlueprintPageEntry instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'placement': instance.placement.toJson(),
  'inwardLinks': instance.inwardLinks.map((e) => e.toJson()).toList(),
  'outwardLinks': instance.outwardLinks.map((e) => e.toJson()).toList(),
  'metadata': instance.metadata.map((e) => e.toJson()).toList(),
  '_kind': instance.$type,
};

_EntryDefinition _$EntryDefinitionFromJson(Map<String, dynamic> json) =>
    _EntryDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      blueprint: ElementBlueprint.fromJson(
        json['blueprint'] as Map<String, dynamic>,
      ),
      placement: EntryPlacement.fromJson(
        json['placement'] as Map<String, dynamic>,
      ),
      data: DynamicData.fromJson(json['data'] as Map<String, dynamic>),
      inwardEdges: (json['inwardEdges'] as List<dynamic>)
          .map((e) => ElementLink.fromJson(e as Map<String, dynamic>))
          .toList(),
      outwardEdges: (json['outwardEdges'] as List<dynamic>)
          .map((e) => ElementLink.fromJson(e as Map<String, dynamic>))
          .toList(),
      metadata:
          (json['metadata'] as List<dynamic>?)
              ?.map((e) => EntryMetadata.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$EntryDefinitionToJson(_EntryDefinition instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'blueprint': instance.blueprint.toJson(),
      'placement': instance.placement.toJson(),
      'data': instance.data.toJson(),
      'inwardEdges': instance.inwardEdges.map((e) => e.toJson()).toList(),
      'outwardEdges': instance.outwardEdges.map((e) => e.toJson()).toList(),
      'metadata': instance.metadata.map((e) => e.toJson()).toList(),
    };

_EntryPlacement _$EntryPlacementFromJson(Map<String, dynamic> json) =>
    _EntryPlacement(
      x: (json['x'] as num).toInt(),
      y: (json['y'] as num).toInt(),
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
    );

Map<String, dynamic> _$EntryPlacementToJson(_EntryPlacement instance) =>
    <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
      'width': instance.width,
      'height': instance.height,
    };

CustomEntryMetadata _$CustomEntryMetadataFromJson(Map<String, dynamic> json) =>
    CustomEntryMetadata(name: json['name'] as String, data: json['data']);

Map<String, dynamic> _$CustomEntryMetadataToJson(
  CustomEntryMetadata instance,
) => <String, dynamic>{'name': instance.name, 'data': instance.data};

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Entry)
final entryProvider = EntryFamily._();

final class EntryProvider
    extends $AsyncNotifierProvider<Entry, EntryDefinition?> {
  EntryProvider._({
    required EntryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'entryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$entryHash();

  @override
  String toString() {
    return r'entryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  Entry create() => Entry();

  @override
  bool operator ==(Object other) {
    return other is EntryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$entryHash() => r'87002d25623d406347e71cb7e129993c0836b751';

final class EntryFamily extends $Family
    with
        $ClassFamilyOverride<
          Entry,
          AsyncValue<EntryDefinition?>,
          EntryDefinition?,
          FutureOr<EntryDefinition?>,
          String
        > {
  EntryFamily._()
    : super(
        retry: null,
        name: r'entryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EntryProvider call(String entryId) =>
      EntryProvider._(argument: entryId, from: this);

  @override
  String toString() => r'entryProvider';
}

abstract class _$Entry extends $AsyncNotifier<EntryDefinition?> {
  late final _$args = ref.$arg as String;
  String get entryId => _$args;

  FutureOr<EntryDefinition?> build(String entryId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<EntryDefinition?>, EntryDefinition?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<EntryDefinition?>, EntryDefinition?>,
              AsyncValue<EntryDefinition?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
