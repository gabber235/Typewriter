// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tags.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Typed tag views of the shared working document.

@ProviderFor(workingTags)
final workingTagsProvider = WorkingTagsProvider._();

/// Typed tag views of the shared working document.

final class WorkingTagsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Tag>>,
          AsyncValue<List<Tag>>,
          AsyncValue<List<Tag>>
        >
    with $Provider<AsyncValue<List<Tag>>> {
  /// Typed tag views of the shared working document.
  WorkingTagsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workingTagsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workingTagsHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<Tag>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<Tag>> create(Ref ref) {
    return workingTags(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<Tag>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<Tag>>>(value),
    );
  }
}

String _$workingTagsHash() => r'0cd206afa3b25f42715597e4555d078fcdd13afc';

@ProviderFor(workingTag)
final workingTagProvider = WorkingTagFamily._();

final class WorkingTagProvider
    extends
        $FunctionalProvider<
          AsyncValue<Tag?>,
          AsyncValue<Tag?>,
          AsyncValue<Tag?>
        >
    with $Provider<AsyncValue<Tag?>> {
  WorkingTagProvider._({
    required WorkingTagFamily super.from,
    required skir.ResourceId super.argument,
  }) : super(
         retry: null,
         name: r'workingTagProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workingTagHash();

  @override
  String toString() {
    return r'workingTagProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<Tag?>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AsyncValue<Tag?> create(Ref ref) {
    final argument = this.argument as skir.ResourceId;
    return workingTag(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<Tag?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<Tag?>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WorkingTagProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workingTagHash() => r'814b32e7fed48ed4c2f88c79be8cfc88cc4546fb';

final class WorkingTagFamily extends $Family
    with $FunctionalFamilyOverride<AsyncValue<Tag?>, skir.ResourceId> {
  WorkingTagFamily._()
    : super(
        retry: null,
        name: r'workingTagProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkingTagProvider call(skir.ResourceId tagId) =>
      WorkingTagProvider._(argument: tagId, from: this);

  @override
  String toString() => r'workingTagProvider';
}
