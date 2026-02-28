// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_selectable.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tagSelectable)
const tagSelectableProvider = TagSelectableFamily._();

final class TagSelectableProvider
    extends $FunctionalProvider<TagSelectable?, TagSelectable?, TagSelectable?>
    with $Provider<TagSelectable?> {
  const TagSelectableProvider._({
    required TagSelectableFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tagSelectableProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tagSelectableHash();

  @override
  String toString() {
    return r'tagSelectableProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<TagSelectable?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TagSelectable? create(Ref ref) {
    final argument = this.argument as String;
    return tagSelectable(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TagSelectable? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TagSelectable?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TagSelectableProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tagSelectableHash() => r'7fedc24154becaf8f153837bf25e8c04aaca034c';

final class TagSelectableFamily extends $Family
    with $FunctionalFamilyOverride<TagSelectable?, String> {
  const TagSelectableFamily._()
    : super(
        retry: null,
        name: r'tagSelectableProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TagSelectableProvider call(String tagId) =>
      TagSelectableProvider._(argument: tagId, from: this);

  @override
  String toString() => r'tagSelectableProvider';
}
