// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tags.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns the current Realm tag projection and its authoring mutations.
///
/// The provider waits for its graph selection before reading the session, then
/// follows session revisions through [ref.listen]. Creation and deletion use
/// direct guarded operations. Editing is delegated to the shared editor owner
/// so drafts, validation, and response reconciliation follow the same path as
/// other Realm resources.

@ProviderFor(CanonicalTags)
final canonicalTagsProvider = CanonicalTagsProvider._();

/// Owns the current Realm tag projection and its authoring mutations.
///
/// The provider waits for its graph selection before reading the session, then
/// follows session revisions through [ref.listen]. Creation and deletion use
/// direct guarded operations. Editing is delegated to the shared editor owner
/// so drafts, validation, and response reconciliation follow the same path as
/// other Realm resources.
final class CanonicalTagsProvider
    extends $AsyncNotifierProvider<CanonicalTags, List<Tag>> {
  /// Owns the current Realm tag projection and its authoring mutations.
  ///
  /// The provider waits for its graph selection before reading the session, then
  /// follows session revisions through [ref.listen]. Creation and deletion use
  /// direct guarded operations. Editing is delegated to the shared editor owner
  /// so drafts, validation, and response reconciliation follow the same path as
  /// other Realm resources.
  CanonicalTagsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'canonicalTagsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$canonicalTagsHash();

  @$internal
  @override
  CanonicalTags create() => CanonicalTags();
}

String _$canonicalTagsHash() => r'772d5dedb4f2193bc2a5ce406796e1abbb0a880a';

/// Owns the current Realm tag projection and its authoring mutations.
///
/// The provider waits for its graph selection before reading the session, then
/// follows session revisions through [ref.listen]. Creation and deletion use
/// direct guarded operations. Editing is delegated to the shared editor owner
/// so drafts, validation, and response reconciliation follow the same path as
/// other Realm resources.

abstract class _$CanonicalTags extends $AsyncNotifier<List<Tag>> {
  FutureOr<List<Tag>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Tag>>, List<Tag>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Tag>>, List<Tag>>,
              AsyncValue<List<Tag>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Reads one tag from the canonical Realm projection.

@ProviderFor(canonicalTag)
final canonicalTagProvider = CanonicalTagFamily._();

/// Reads one tag from the canonical Realm projection.

final class CanonicalTagProvider
    extends $FunctionalProvider<AsyncValue<Tag?>, Tag?, FutureOr<Tag?>>
    with $FutureModifier<Tag?>, $FutureProvider<Tag?> {
  /// Reads one tag from the canonical Realm projection.
  CanonicalTagProvider._({
    required CanonicalTagFamily super.from,
    required skir.ResourceId super.argument,
  }) : super(
         retry: null,
         name: r'canonicalTagProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$canonicalTagHash();

  @override
  String toString() {
    return r'canonicalTagProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Tag?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Tag?> create(Ref ref) {
    final argument = this.argument as skir.ResourceId;
    return canonicalTag(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CanonicalTagProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$canonicalTagHash() => r'fd7b645707b870e3bdcb847e04da6071ce38e867';

/// Reads one tag from the canonical Realm projection.

final class CanonicalTagFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Tag?>, skir.ResourceId> {
  CanonicalTagFamily._()
    : super(
        retry: null,
        name: r'canonicalTagProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Reads one tag from the canonical Realm projection.

  CanonicalTagProvider call(skir.ResourceId tagId) =>
      CanonicalTagProvider._(argument: tagId, from: this);

  @override
  String toString() => r'canonicalTagProvider';
}

/// Combines canonical tags with local editor values for UI consumers.
///
/// Canonical state remains the authority. A local value is only a temporary
/// projection keyed by organization, realm, and tag identity, and disappears
/// when the shared editor owner releases it or canonical state catches up.

@ProviderFor(projectedTags)
final projectedTagsProvider = ProjectedTagsProvider._();

/// Combines canonical tags with local editor values for UI consumers.
///
/// Canonical state remains the authority. A local value is only a temporary
/// projection keyed by organization, realm, and tag identity, and disappears
/// when the shared editor owner releases it or canonical state catches up.

final class ProjectedTagsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Tag>>,
          AsyncValue<List<Tag>>,
          AsyncValue<List<Tag>>
        >
    with $Provider<AsyncValue<List<Tag>>> {
  /// Combines canonical tags with local editor values for UI consumers.
  ///
  /// Canonical state remains the authority. A local value is only a temporary
  /// projection keyed by organization, realm, and tag identity, and disappears
  /// when the shared editor owner releases it or canonical state catches up.
  ProjectedTagsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectedTagsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectedTagsHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<Tag>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<Tag>> create(Ref ref) {
    return projectedTags(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<Tag>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<Tag>>>(value),
    );
  }
}

String _$projectedTagsHash() => r'3e3386aecdcda929315fde5b5243dd490a935c3c';

/// Projects one tag for graph nodes that rebuild independently.

@ProviderFor(projectedTag)
final projectedTagProvider = ProjectedTagFamily._();

/// Projects one tag for graph nodes that rebuild independently.

final class ProjectedTagProvider
    extends
        $FunctionalProvider<
          AsyncValue<Tag?>,
          AsyncValue<Tag?>,
          AsyncValue<Tag?>
        >
    with $Provider<AsyncValue<Tag?>> {
  /// Projects one tag for graph nodes that rebuild independently.
  ProjectedTagProvider._({
    required ProjectedTagFamily super.from,
    required skir.ResourceId super.argument,
  }) : super(
         retry: null,
         name: r'projectedTagProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$projectedTagHash();

  @override
  String toString() {
    return r'projectedTagProvider'
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
    return projectedTag(ref, argument);
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
    return other is ProjectedTagProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$projectedTagHash() => r'49e6666eff5dcd958fddcc2d1107dcd42d4c7a21';

/// Projects one tag for graph nodes that rebuild independently.

final class ProjectedTagFamily extends $Family
    with $FunctionalFamilyOverride<AsyncValue<Tag?>, skir.ResourceId> {
  ProjectedTagFamily._()
    : super(
        retry: null,
        name: r'projectedTagProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Projects one tag for graph nodes that rebuild independently.

  ProjectedTagProvider call(skir.ResourceId tagId) =>
      ProjectedTagProvider._(argument: tagId, from: this);

  @override
  String toString() => r'projectedTagProvider';
}
