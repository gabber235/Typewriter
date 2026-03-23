// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_elements.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PageElementEntry _$PageElementEntryFromJson(Map<String, dynamic> json) =>
    PageElementEntry(
      entry: PageEntry.fromJson(json['entry'] as Map<String, dynamic>),
      $type: json['_kind'] as String?,
    );

Map<String, dynamic> _$PageElementEntryToJson(PageElementEntry instance) =>
    <String, dynamic>{
      'entry': instance.entry.toJson(),
      '_kind': instance.$type,
    };

PageElementGroup _$PageElementGroupFromJson(Map<String, dynamic> json) =>
    PageElementGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      placement: EntryPlacement.fromJson(
        json['placement'] as Map<String, dynamic>,
      ),
      $type: json['_kind'] as String?,
    );

Map<String, dynamic> _$PageElementGroupToJson(PageElementGroup instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'placement': instance.placement.toJson(),
      '_kind': instance.$type,
    };

PageElementCue _$PageElementCueFromJson(Map<String, dynamic> json) =>
    PageElementCue(
      cue: Cue.fromJson(json['cue'] as Map<String, dynamic>),
      $type: json['_kind'] as String?,
    );

Map<String, dynamic> _$PageElementCueToJson(PageElementCue instance) =>
    <String, dynamic>{'cue': instance.cue.toJson(), '_kind': instance.$type};

_ElementLink _$ElementLinkFromJson(Map<String, dynamic> json) => _ElementLink(
  linkId: json['linkId'] as String,
  otherId: json['otherId'] as String,
  path: json['path'] as String,
);

Map<String, dynamic> _$ElementLinkToJson(_ElementLink instance) =>
    <String, dynamic>{
      'linkId': instance.linkId,
      'otherId': instance.otherId,
      'path': instance.path,
    };

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PageElements)
final pageElementsProvider = PageElementsFamily._();

final class PageElementsProvider
    extends $AsyncNotifierProvider<PageElements, List<PageElement>> {
  PageElementsProvider._({
    required PageElementsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'pageElementsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pageElementsHash();

  @override
  String toString() {
    return r'pageElementsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PageElements create() => PageElements();

  @override
  bool operator ==(Object other) {
    return other is PageElementsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pageElementsHash() => r'c6a8c883cc897208b47433b837103fb218eb6f4c';

final class PageElementsFamily extends $Family
    with
        $ClassFamilyOverride<
          PageElements,
          AsyncValue<List<PageElement>>,
          List<PageElement>,
          FutureOr<List<PageElement>>,
          String
        > {
  PageElementsFamily._()
    : super(
        retry: null,
        name: r'pageElementsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PageElementsProvider call(String pageId) =>
      PageElementsProvider._(argument: pageId, from: this);

  @override
  String toString() => r'pageElementsProvider';
}

abstract class _$PageElements extends $AsyncNotifier<List<PageElement>> {
  late final _$args = ref.$arg as String;
  String get pageId => _$args;

  FutureOr<List<PageElement>> build(String pageId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<PageElement>>, List<PageElement>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<PageElement>>, List<PageElement>>,
              AsyncValue<List<PageElement>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
