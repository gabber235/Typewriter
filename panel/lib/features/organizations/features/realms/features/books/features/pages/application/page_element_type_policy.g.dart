// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_element_type_policy.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Resolves the concrete element types allowed by [pageKind].
///
/// Page catalog definitions provide graph node types or timeline track,
/// segment, and keyframe roots. The realm catalog lease supplies subtype
/// results, and abstract matches are removed before the ready state is emitted.
/// Catalog failure remains visible so editor consumers can disable creation and
/// show diagnostics instead of treating incomplete data as permission.

@ProviderFor(pageElementTypes)
final pageElementTypesProvider = PageElementTypesFamily._();

/// Resolves the concrete element types allowed by [pageKind].
///
/// Page catalog definitions provide graph node types or timeline track,
/// segment, and keyframe roots. The realm catalog lease supplies subtype
/// results, and abstract matches are removed before the ready state is emitted.
/// Catalog failure remains visible so editor consumers can disable creation and
/// show diagnostics instead of treating incomplete data as permission.

final class PageElementTypesProvider
    extends
        $FunctionalProvider<
          AsyncValue<PageElementTypesState>,
          PageElementTypesState,
          Stream<PageElementTypesState>
        >
    with
        $FutureModifier<PageElementTypesState>,
        $StreamProvider<PageElementTypesState> {
  /// Resolves the concrete element types allowed by [pageKind].
  ///
  /// Page catalog definitions provide graph node types or timeline track,
  /// segment, and keyframe roots. The realm catalog lease supplies subtype
  /// results, and abstract matches are removed before the ready state is emitted.
  /// Catalog failure remains visible so editor consumers can disable creation and
  /// show diagnostics instead of treating incomplete data as permission.
  PageElementTypesProvider._({
    required PageElementTypesFamily super.from,
    required PageKindRef super.argument,
  }) : super(
         retry: null,
         name: r'pageElementTypesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pageElementTypesHash();

  @override
  String toString() {
    return r'pageElementTypesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<PageElementTypesState> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<PageElementTypesState> create(Ref ref) {
    final argument = this.argument as PageKindRef;
    return pageElementTypes(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PageElementTypesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pageElementTypesHash() => r'230b3bfb0ffe56eb05d03452e8fe8ae903490f1f';

/// Resolves the concrete element types allowed by [pageKind].
///
/// Page catalog definitions provide graph node types or timeline track,
/// segment, and keyframe roots. The realm catalog lease supplies subtype
/// results, and abstract matches are removed before the ready state is emitted.
/// Catalog failure remains visible so editor consumers can disable creation and
/// show diagnostics instead of treating incomplete data as permission.

final class PageElementTypesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<PageElementTypesState>, PageKindRef> {
  PageElementTypesFamily._()
    : super(
        retry: null,
        name: r'pageElementTypesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Resolves the concrete element types allowed by [pageKind].
  ///
  /// Page catalog definitions provide graph node types or timeline track,
  /// segment, and keyframe roots. The realm catalog lease supplies subtype
  /// results, and abstract matches are removed before the ready state is emitted.
  /// Catalog failure remains visible so editor consumers can disable creation and
  /// show diagnostics instead of treating incomplete data as permission.

  PageElementTypesProvider call(PageKindRef pageKind) =>
      PageElementTypesProvider._(argument: pageKind, from: this);

  @override
  String toString() => r'pageElementTypesProvider';
}

/// Resolves the concrete types that can be created directly on [pageKind].
///
/// Timeline segment and keyframe types are deliberately excluded. They need a
/// parent timeline entry and therefore cannot be created from page selection
/// alone.

@ProviderFor(pageEntryCreationPolicy)
final pageEntryCreationPolicyProvider = PageEntryCreationPolicyFamily._();

/// Resolves the concrete types that can be created directly on [pageKind].
///
/// Timeline segment and keyframe types are deliberately excluded. They need a
/// parent timeline entry and therefore cannot be created from page selection
/// alone.

final class PageEntryCreationPolicyProvider
    extends
        $FunctionalProvider<
          AsyncValue<PageEntryCreationPolicy>,
          AsyncValue<PageEntryCreationPolicy>,
          AsyncValue<PageEntryCreationPolicy>
        >
    with $Provider<AsyncValue<PageEntryCreationPolicy>> {
  /// Resolves the concrete types that can be created directly on [pageKind].
  ///
  /// Timeline segment and keyframe types are deliberately excluded. They need a
  /// parent timeline entry and therefore cannot be created from page selection
  /// alone.
  PageEntryCreationPolicyProvider._({
    required PageEntryCreationPolicyFamily super.from,
    required PageKindRef super.argument,
  }) : super(
         retry: null,
         name: r'pageEntryCreationPolicyProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pageEntryCreationPolicyHash();

  @override
  String toString() {
    return r'pageEntryCreationPolicyProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<PageEntryCreationPolicy>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<PageEntryCreationPolicy> create(Ref ref) {
    final argument = this.argument as PageKindRef;
    return pageEntryCreationPolicy(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<PageEntryCreationPolicy> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<PageEntryCreationPolicy>>(
        value,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PageEntryCreationPolicyProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pageEntryCreationPolicyHash() =>
    r'd0a59e66001910540980fc980c63ff05ad5f591e';

/// Resolves the concrete types that can be created directly on [pageKind].
///
/// Timeline segment and keyframe types are deliberately excluded. They need a
/// parent timeline entry and therefore cannot be created from page selection
/// alone.

final class PageEntryCreationPolicyFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AsyncValue<PageEntryCreationPolicy>,
          PageKindRef
        > {
  PageEntryCreationPolicyFamily._()
    : super(
        retry: null,
        name: r'pageEntryCreationPolicyProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Resolves the concrete types that can be created directly on [pageKind].
  ///
  /// Timeline segment and keyframe types are deliberately excluded. They need a
  /// parent timeline entry and therefore cannot be created from page selection
  /// alone.

  PageEntryCreationPolicyProvider call(PageKindRef pageKind) =>
      PageEntryCreationPolicyProvider._(argument: pageKind, from: this);

  @override
  String toString() => r'pageEntryCreationPolicyProvider';
}

/// Resolves the live entry creation policy for one page identity.
///
/// Page metadata changes may select a different page kind. Keeping that
/// indirection in a provider lets consumers observe policy changes without
/// rebuilding their own lifecycle owner.

@ProviderFor(pageEntryCreationPolicyForPage)
final pageEntryCreationPolicyForPageProvider =
    PageEntryCreationPolicyForPageFamily._();

/// Resolves the live entry creation policy for one page identity.
///
/// Page metadata changes may select a different page kind. Keeping that
/// indirection in a provider lets consumers observe policy changes without
/// rebuilding their own lifecycle owner.

final class PageEntryCreationPolicyForPageProvider
    extends
        $FunctionalProvider<
          AsyncValue<PageEntryCreationPolicy>,
          AsyncValue<PageEntryCreationPolicy>,
          AsyncValue<PageEntryCreationPolicy>
        >
    with $Provider<AsyncValue<PageEntryCreationPolicy>> {
  /// Resolves the live entry creation policy for one page identity.
  ///
  /// Page metadata changes may select a different page kind. Keeping that
  /// indirection in a provider lets consumers observe policy changes without
  /// rebuilding their own lifecycle owner.
  PageEntryCreationPolicyForPageProvider._({
    required PageEntryCreationPolicyForPageFamily super.from,
    required skir.ResourceId super.argument,
  }) : super(
         retry: null,
         name: r'pageEntryCreationPolicyForPageProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pageEntryCreationPolicyForPageHash();

  @override
  String toString() {
    return r'pageEntryCreationPolicyForPageProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<PageEntryCreationPolicy>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<PageEntryCreationPolicy> create(Ref ref) {
    final argument = this.argument as skir.ResourceId;
    return pageEntryCreationPolicyForPage(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<PageEntryCreationPolicy> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<PageEntryCreationPolicy>>(
        value,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PageEntryCreationPolicyForPageProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pageEntryCreationPolicyForPageHash() =>
    r'62af5daf10f23eb8f55dc4c96e0d4bf867d81ebb';

/// Resolves the live entry creation policy for one page identity.
///
/// Page metadata changes may select a different page kind. Keeping that
/// indirection in a provider lets consumers observe policy changes without
/// rebuilding their own lifecycle owner.

final class PageEntryCreationPolicyForPageFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AsyncValue<PageEntryCreationPolicy>,
          skir.ResourceId
        > {
  PageEntryCreationPolicyForPageFamily._()
    : super(
        retry: null,
        name: r'pageEntryCreationPolicyForPageProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Resolves the live entry creation policy for one page identity.
  ///
  /// Page metadata changes may select a different page kind. Keeping that
  /// indirection in a provider lets consumers observe policy changes without
  /// rebuilding their own lifecycle owner.

  PageEntryCreationPolicyForPageProvider call(skir.ResourceId pageId) =>
      PageEntryCreationPolicyForPageProvider._(argument: pageId, from: this);

  @override
  String toString() => r'pageEntryCreationPolicyForPageProvider';
}

/// Maps page kinds that can directly create [elementType] to their policy.

@ProviderFor(compatiblePageEntryKinds)
final compatiblePageEntryKindsProvider = CompatiblePageEntryKindsFamily._();

/// Maps page kinds that can directly create [elementType] to their policy.

final class CompatiblePageEntryKindsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<PageKindRef, PageEntryCreationPolicy>>,
          AsyncValue<Map<PageKindRef, PageEntryCreationPolicy>>,
          AsyncValue<Map<PageKindRef, PageEntryCreationPolicy>>
        >
    with $Provider<AsyncValue<Map<PageKindRef, PageEntryCreationPolicy>>> {
  /// Maps page kinds that can directly create [elementType] to their policy.
  CompatiblePageEntryKindsProvider._({
    required CompatiblePageEntryKindsFamily super.from,
    required ResolvedTypeRef super.argument,
  }) : super(
         retry: null,
         name: r'compatiblePageEntryKindsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$compatiblePageEntryKindsHash();

  @override
  String toString() {
    return r'compatiblePageEntryKindsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<Map<PageKindRef, PageEntryCreationPolicy>>>
  $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  AsyncValue<Map<PageKindRef, PageEntryCreationPolicy>> create(Ref ref) {
    final argument = this.argument as ResolvedTypeRef;
    return compatiblePageEntryKinds(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    AsyncValue<Map<PageKindRef, PageEntryCreationPolicy>> value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<
            AsyncValue<Map<PageKindRef, PageEntryCreationPolicy>>
          >(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CompatiblePageEntryKindsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$compatiblePageEntryKindsHash() =>
    r'99b484e4f8e58879748673d27f89ca8641233fd4';

/// Maps page kinds that can directly create [elementType] to their policy.

final class CompatiblePageEntryKindsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AsyncValue<Map<PageKindRef, PageEntryCreationPolicy>>,
          ResolvedTypeRef
        > {
  CompatiblePageEntryKindsFamily._()
    : super(
        retry: null,
        name: r'compatiblePageEntryKindsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Maps page kinds that can directly create [elementType] to their policy.

  CompatiblePageEntryKindsProvider call(ResolvedTypeRef elementType) =>
      CompatiblePageEntryKindsProvider._(argument: elementType, from: this);

  @override
  String toString() => r'compatiblePageEntryKindsProvider';
}

/// Resolves the live entry creation policy for every available page kind.

@ProviderFor(pageEntryCreationPolicies)
final pageEntryCreationPoliciesProvider = PageEntryCreationPoliciesProvider._();

/// Resolves the live entry creation policy for every available page kind.

final class PageEntryCreationPoliciesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<PageKindRef, PageEntryCreationPolicy>>,
          AsyncValue<Map<PageKindRef, PageEntryCreationPolicy>>,
          AsyncValue<Map<PageKindRef, PageEntryCreationPolicy>>
        >
    with $Provider<AsyncValue<Map<PageKindRef, PageEntryCreationPolicy>>> {
  /// Resolves the live entry creation policy for every available page kind.
  PageEntryCreationPoliciesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pageEntryCreationPoliciesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pageEntryCreationPoliciesHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<Map<PageKindRef, PageEntryCreationPolicy>>>
  $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  AsyncValue<Map<PageKindRef, PageEntryCreationPolicy>> create(Ref ref) {
    return pageEntryCreationPolicies(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    AsyncValue<Map<PageKindRef, PageEntryCreationPolicy>> value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<
            AsyncValue<Map<PageKindRef, PageEntryCreationPolicy>>
          >(value),
    );
  }
}

String _$pageEntryCreationPoliciesHash() =>
    r'de2a982297f554cae35283380a79242d8f348371';
