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
/// Loads one entry definition from the realm entry index and coordinates entry
/// edits with the page element owner.
///
/// The index is the current location authority. Mutations recheck that
/// location before submission, so a stale inspector cannot write to a page
/// after the entry has moved or the selected realm has changed.

@ProviderFor(Entry)
final entryProvider = EntryFamily._();

/// Loads one entry definition from the realm entry index and coordinates entry
/// edits with the page element owner.
///
/// The index is the current location authority. Mutations recheck that
/// location before submission, so a stale inspector cannot write to a page
/// after the entry has moved or the selected realm has changed.
final class EntryProvider
    extends $AsyncNotifierProvider<Entry, EntryDefinition?> {
  /// Loads one entry definition from the realm entry index and coordinates entry
  /// edits with the page element owner.
  ///
  /// The index is the current location authority. Mutations recheck that
  /// location before submission, so a stale inspector cannot write to a page
  /// after the entry has moved or the selected realm has changed.
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

String _$entryHash() => r'c25d732f2e96665b58c0f296a4177d9e3ddf3111';

/// Loads one entry definition from the realm entry index and coordinates entry
/// edits with the page element owner.
///
/// The index is the current location authority. Mutations recheck that
/// location before submission, so a stale inspector cannot write to a page
/// after the entry has moved or the selected realm has changed.

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

  /// Loads one entry definition from the realm entry index and coordinates entry
  /// edits with the page element owner.
  ///
  /// The index is the current location authority. Mutations recheck that
  /// location before submission, so a stale inspector cannot write to a page
  /// after the entry has moved or the selected realm has changed.

  EntryProvider call(String entryId) =>
      EntryProvider._(argument: entryId, from: this);

  @override
  String toString() => r'entryProvider';
}

/// Loads one entry definition from the realm entry index and coordinates entry
/// edits with the page element owner.
///
/// The index is the current location authority. Mutations recheck that
/// location before submission, so a stale inspector cannot write to a page
/// after the entry has moved or the selected realm has changed.

abstract class _$Entry extends $AsyncNotifier<EntryDefinition?> {
  late final _$args = ref.$arg as String;
  String get entryId => _$args;

  FutureOr<EntryDefinition?> build(String entryId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
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
    return element.handleCreate(ref, () => build(_$args));
  }
}
