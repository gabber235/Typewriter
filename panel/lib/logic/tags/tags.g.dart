// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tags.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Tags)
const tagsProvider = TagsProvider._();

final class TagsProvider extends $StreamNotifierProvider<Tags, List<Tag>> {
  const TagsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tagsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tagsHash();

  @$internal
  @override
  Tags create() => Tags();
}

String _$tagsHash() => r'0454523d69a7dbd158a20f5820a636d1f7fe35ea';

abstract class _$Tags extends $StreamNotifier<List<Tag>> {
  Stream<List<Tag>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<Tag>>, List<Tag>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Tag>>, List<Tag>>,
              AsyncValue<List<Tag>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(tag)
const tagProvider = TagFamily._();

final class TagProvider
    extends $FunctionalProvider<AsyncValue<Tag?>, Tag?, FutureOr<Tag?>>
    with $FutureModifier<Tag?>, $FutureProvider<Tag?> {
  const TagProvider._({
    required TagFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tagProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tagHash();

  @override
  String toString() {
    return r'tagProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Tag?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Tag?> create(Ref ref) {
    final argument = this.argument as String;
    return tag(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TagProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tagHash() => r'ee3ea41098b35219090fc57dc2280616cabeb701';

final class TagFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Tag?>, String> {
  const TagFamily._()
    : super(
        retry: null,
        name: r'tagProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TagProvider call(String tagId) => TagProvider._(argument: tagId, from: this);

  @override
  String toString() => r'tagProvider';
}
