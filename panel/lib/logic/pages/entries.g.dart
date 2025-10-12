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
      blueprint: EntryBlueprint.fromJson(
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
  inwardEdges: (json['inwardEdges'] as List<dynamic>)
      .map((e) => EntryEdge.fromJson(e as Map<String, dynamic>))
      .toList(),
  outwardEdges: (json['outwardEdges'] as List<dynamic>)
      .map((e) => EntryEdge.fromJson(e as Map<String, dynamic>))
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
  'inwardEdges': instance.inwardEdges.map((e) => e.toJson()).toList(),
  'outwardEdges': instance.outwardEdges.map((e) => e.toJson()).toList(),
  'metadata': instance.metadata.map((e) => e.toJson()).toList(),
  '_kind': instance.$type,
};

_EntryDefinition _$EntryDefinitionFromJson(
  Map<String, dynamic> json,
) => _EntryDefinition(
  id: json['id'] as String,
  name: json['name'] as String,
  blueprint: EntryBlueprint.fromJson(json['blueprint'] as Map<String, dynamic>),
  placement: EntryPlacement.fromJson(json['placement'] as Map<String, dynamic>),
  data: DynamicData.fromJson(json['data'] as Map<String, dynamic>),
  inwardEdges: (json['inwardEdges'] as List<dynamic>)
      .map((e) => EntryEdge.fromJson(e as Map<String, dynamic>))
      .toList(),
  outwardEdges: (json['outwardEdges'] as List<dynamic>)
      .map((e) => EntryEdge.fromJson(e as Map<String, dynamic>))
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

_EntryBlueprint _$EntryBlueprintFromJson(Map<String, dynamic> json) =>
    _EntryBlueprint(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      extension: json['extension'] as String,
      dataBlueprint: ObjectBlueprint.fromJson(
        json['dataBlueprint'] as Map<String, dynamic>,
      ),
      color: json['color'] == null
          ? Colors.grey
          : const ColorConverter().fromJson(json['color'] as String),
      icon: json['icon'] as String? ?? "fa-solid:question-circle",
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const <String>[],
      genericConstraints:
          (json['genericConstraints'] as List<dynamic>?)
              ?.map((e) => DataBlueprint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          null,
      variableDataBlueprint: json['variableDataBlueprint'] == null
          ? null
          : DataBlueprint.fromJson(
              json['variableDataBlueprint'] as Map<String, dynamic>,
            ),
      contextKeys:
          (json['contextKeys'] as List<dynamic>?)
              ?.map((e) => ContextKey.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      modifiers:
          (json['modifiers'] as List<dynamic>?)
              ?.map((e) => EntryModifier.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$EntryBlueprintToJson(_EntryBlueprint instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'extension': instance.extension,
      'dataBlueprint': instance.dataBlueprint.toJson(),
      'color': const ColorConverter().toJson(instance.color),
      'icon': instance.icon,
      'tags': instance.tags,
      'genericConstraints': instance.genericConstraints
          ?.map((e) => e.toJson())
          .toList(),
      'variableDataBlueprint': instance.variableDataBlueprint?.toJson(),
      'contextKeys': instance.contextKeys.map((e) => e.toJson()).toList(),
      'modifiers': instance.modifiers.map((e) => e.toJson()).toList(),
    };

_ContextKey _$ContextKeyFromJson(Map<String, dynamic> json) => _ContextKey(
  name: json['name'] as String,
  klassName: json['klassName'] as String,
  blueprint: DataBlueprint.fromJson(json['blueprint'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ContextKeyToJson(_ContextKey instance) =>
    <String, dynamic>{
      'name': instance.name,
      'klassName': instance.klassName,
      'blueprint': instance.blueprint.toJson(),
    };

_EmptyModifier _$EmptyModifierFromJson(Map<String, dynamic> json) =>
    _EmptyModifier($type: json['kind'] as String?);

Map<String, dynamic> _$EmptyModifierToJson(_EmptyModifier instance) =>
    <String, dynamic>{'kind': instance.$type};

DeprecatedModifier _$DeprecatedModifierFromJson(Map<String, dynamic> json) =>
    DeprecatedModifier(
      reason: json['reason'] as String? ?? "",
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$DeprecatedModifierToJson(DeprecatedModifier instance) =>
    <String, dynamic>{'reason': instance.reason, 'kind': instance.$type};

_EntryEdge _$EntryEdgeFromJson(Map<String, dynamic> json) => _EntryEdge(
  id: json['id'] as String,
  otherId: json['otherId'] as String,
  path: json['path'] as String,
);

Map<String, dynamic> _$EntryEdgeToJson(_EntryEdge instance) =>
    <String, dynamic>{
      'id': instance.id,
      'otherId': instance.otherId,
      'path': instance.path,
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

@ProviderFor(PageEntries)
const pageEntriesProvider = PageEntriesFamily._();

final class PageEntriesProvider
    extends $AsyncNotifierProvider<PageEntries, List<PageEntry>> {
  const PageEntriesProvider._({
    required PageEntriesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'pageEntriesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pageEntriesHash();

  @override
  String toString() {
    return r'pageEntriesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PageEntries create() => PageEntries();

  @override
  bool operator ==(Object other) {
    return other is PageEntriesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pageEntriesHash() => r'409a0267e73bf6ac7b72216319de66e95a2e93fa';

final class PageEntriesFamily extends $Family
    with
        $ClassFamilyOverride<
          PageEntries,
          AsyncValue<List<PageEntry>>,
          List<PageEntry>,
          FutureOr<List<PageEntry>>,
          String
        > {
  const PageEntriesFamily._()
    : super(
        retry: null,
        name: r'pageEntriesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PageEntriesProvider call(String pageId) =>
      PageEntriesProvider._(argument: pageId, from: this);

  @override
  String toString() => r'pageEntriesProvider';
}

abstract class _$PageEntries extends $AsyncNotifier<List<PageEntry>> {
  late final _$args = ref.$arg as String;
  String get pageId => _$args;

  FutureOr<List<PageEntry>> build(String pageId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<AsyncValue<List<PageEntry>>, List<PageEntry>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<PageEntry>>, List<PageEntry>>,
              AsyncValue<List<PageEntry>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(Entry)
const entryProvider = EntryFamily._();

final class EntryProvider
    extends $AsyncNotifierProvider<Entry, EntryDefinition?> {
  const EntryProvider._({
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
  const EntryFamily._()
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
    final created = build(_$args);
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
    element.handleValue(ref, created);
  }
}
