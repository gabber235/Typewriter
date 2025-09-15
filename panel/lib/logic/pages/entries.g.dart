// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entries.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EntryBlueprint _$EntryBlueprintFromJson(Map<String, dynamic> json) =>
    _EntryBlueprint(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      extension: json['extension'] as String,
      dataBlueprint: ObjectBlueprint.fromJson(
          json['dataBlueprint'] as Map<String, dynamic>),
      color: json['color'] == null
          ? Colors.grey
          : const ColorConverter().fromJson(json['color'] as String),
      icon: json['icon'] as String? ?? "fa-solid:question-circle",
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const <String>[],
      genericConstraints: (json['genericConstraints'] as List<dynamic>?)
              ?.map((e) => DataBlueprint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          null,
      variableDataBlueprint: json['variableDataBlueprint'] == null
          ? null
          : DataBlueprint.fromJson(
              json['variableDataBlueprint'] as Map<String, dynamic>),
      contextKeys: (json['contextKeys'] as List<dynamic>?)
              ?.map((e) => ContextKey.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      modifiers: (json['modifiers'] as List<dynamic>?)
              ?.map((e) => EntryModifier.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      wikiUrl: json['wikiUrl'] as String? ?? null,
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
      'genericConstraints':
          instance.genericConstraints?.map((e) => e.toJson()).toList(),
      'variableDataBlueprint': instance.variableDataBlueprint?.toJson(),
      'contextKeys': instance.contextKeys.map((e) => e.toJson()).toList(),
      'modifiers': instance.modifiers.map((e) => e.toJson()).toList(),
      'wikiUrl': instance.wikiUrl,
    };

_ContextKey _$ContextKeyFromJson(Map<String, dynamic> json) => _ContextKey(
      name: json['name'] as String,
      klassName: json['klassName'] as String,
      blueprint:
          DataBlueprint.fromJson(json['blueprint'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ContextKeyToJson(_ContextKey instance) =>
    <String, dynamic>{
      'name': instance.name,
      'klassName': instance.klassName,
      'blueprint': instance.blueprint.toJson(),
    };

_EmptyModifier _$EmptyModifierFromJson(Map<String, dynamic> json) =>
    _EmptyModifier(
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$EmptyModifierToJson(_EmptyModifier instance) =>
    <String, dynamic>{
      'kind': instance.$type,
    };

DeprecatedModifier _$DeprecatedModifierFromJson(Map<String, dynamic> json) =>
    DeprecatedModifier(
      reason: json['reason'] as String? ?? "",
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$DeprecatedModifierToJson(DeprecatedModifier instance) =>
    <String, dynamic>{
      'reason': instance.reason,
      'kind': instance.$type,
    };

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(PageEntries)
const pageEntriesProvider = PageEntriesFamily._();

final class PageEntriesProvider
    extends $AsyncNotifierProvider<PageEntries, List<String>> {
  const PageEntriesProvider._(
      {required PageEntriesFamily super.from, required String super.argument})
      : super(
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

String _$pageEntriesHash() => r'b824b76f394a7937287b9b1df61ba211229eac7d';

final class PageEntriesFamily extends $Family
    with
        $ClassFamilyOverride<PageEntries, AsyncValue<List<String>>,
            List<String>, FutureOr<List<String>>, String> {
  const PageEntriesFamily._()
      : super(
          retry: null,
          name: r'pageEntriesProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  PageEntriesProvider call(
    String pageId,
  ) =>
      PageEntriesProvider._(argument: pageId, from: this);

  @override
  String toString() => r'pageEntriesProvider';
}

abstract class _$PageEntries extends $AsyncNotifier<List<String>> {
  late final _$args = ref.$arg as String;
  String get pageId => _$args;

  FutureOr<List<String>> build(
    String pageId,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(
      _$args,
    );
    final ref = this.ref as $Ref<AsyncValue<List<String>>, List<String>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<String>>, List<String>>,
        AsyncValue<List<String>>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}

@ProviderFor(Entry)
const entryProvider = EntryFamily._();

final class EntryProvider
    extends $AsyncNotifierProvider<Entry, EntryDefinition?> {
  const EntryProvider._(
      {required EntryFamily super.from, required String super.argument})
      : super(
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

String _$entryHash() => r'be9ada5d1be471876af5338572f57af3008c21a1';

final class EntryFamily extends $Family
    with
        $ClassFamilyOverride<Entry, AsyncValue<EntryDefinition?>,
            EntryDefinition?, FutureOr<EntryDefinition?>, String> {
  const EntryFamily._()
      : super(
          retry: null,
          name: r'entryProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  EntryProvider call(
    String entryId,
  ) =>
      EntryProvider._(argument: entryId, from: this);

  @override
  String toString() => r'entryProvider';
}

abstract class _$Entry extends $AsyncNotifier<EntryDefinition?> {
  late final _$args = ref.$arg as String;
  String get entryId => _$args;

  FutureOr<EntryDefinition?> build(
    String entryId,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(
      _$args,
    );
    final ref =
        this.ref as $Ref<AsyncValue<EntryDefinition?>, EntryDefinition?>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<EntryDefinition?>, EntryDefinition?>,
        AsyncValue<EntryDefinition?>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
