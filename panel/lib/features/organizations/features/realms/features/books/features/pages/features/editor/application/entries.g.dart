// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entries.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EntryPlacement _$EntryPlacementFromJson(Map<String, dynamic> json) =>
    _EntryPlacement(
      x: (json['x'] as num).toInt(),
      y: (json['y'] as num).toInt(),
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      kind:
          $enumDecodeNullable(_$EntryPlacementKindEnumMap, json['kind']) ??
          EntryPlacementKind.graph,
    );

Map<String, dynamic> _$EntryPlacementToJson(_EntryPlacement instance) =>
    <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
      'width': instance.width,
      'height': instance.height,
      'kind': _$EntryPlacementKindEnumMap[instance.kind]!,
    };

const _$EntryPlacementKindEnumMap = {
  EntryPlacementKind.graph: 'graph',
  EntryPlacementKind.timelineEntry: 'timelineEntry',
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

String _$entryHash() => r'cf714024b8c810f2e32bfc90dd6d11683ae2b6db';

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
