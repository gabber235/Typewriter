// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_creation_slots.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Returns the Realm supplied creation slot for one page kind.
///
/// The page catalog only chooses which slot applies to the page editor. The
/// slot itself owns the accepted concrete roots, host relation, and created
/// resource definition.

@ProviderFor(pageCreationSlot)
final pageCreationSlotProvider = PageCreationSlotFamily._();

/// Returns the Realm supplied creation slot for one page kind.
///
/// The page catalog only chooses which slot applies to the page editor. The
/// slot itself owns the accepted concrete roots, host relation, and created
/// resource definition.

final class PageCreationSlotProvider
    extends
        $FunctionalProvider<
          AsyncValue<RealmAuthoringCreationSlot>,
          AsyncValue<RealmAuthoringCreationSlot>,
          AsyncValue<RealmAuthoringCreationSlot>
        >
    with $Provider<AsyncValue<RealmAuthoringCreationSlot>> {
  /// Returns the Realm supplied creation slot for one page kind.
  ///
  /// The page catalog only chooses which slot applies to the page editor. The
  /// slot itself owns the accepted concrete roots, host relation, and created
  /// resource definition.
  PageCreationSlotProvider._({
    required PageCreationSlotFamily super.from,
    required PageKindRef super.argument,
  }) : super(
         retry: null,
         name: r'pageCreationSlotProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pageCreationSlotHash();

  @override
  String toString() {
    return r'pageCreationSlotProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<RealmAuthoringCreationSlot>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<RealmAuthoringCreationSlot> create(Ref ref) {
    final argument = this.argument as PageKindRef;
    return pageCreationSlot(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<RealmAuthoringCreationSlot> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<AsyncValue<RealmAuthoringCreationSlot>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PageCreationSlotProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pageCreationSlotHash() => r'f02811d851a4394498cb2a8091026d3b3748733f';

/// Returns the Realm supplied creation slot for one page kind.
///
/// The page catalog only chooses which slot applies to the page editor. The
/// slot itself owns the accepted concrete roots, host relation, and created
/// resource definition.

final class PageCreationSlotFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AsyncValue<RealmAuthoringCreationSlot>,
          PageKindRef
        > {
  PageCreationSlotFamily._()
    : super(
        retry: null,
        name: r'pageCreationSlotProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Returns the Realm supplied creation slot for one page kind.
  ///
  /// The page catalog only chooses which slot applies to the page editor. The
  /// slot itself owns the accepted concrete roots, host relation, and created
  /// resource definition.

  PageCreationSlotProvider call(PageKindRef pageKind) =>
      PageCreationSlotProvider._(argument: pageKind, from: this);

  @override
  String toString() => r'pageCreationSlotProvider';
}

/// Returns the live creation slot for one projected page.

@ProviderFor(pageCreationSlotForPage)
final pageCreationSlotForPageProvider = PageCreationSlotForPageFamily._();

/// Returns the live creation slot for one projected page.

final class PageCreationSlotForPageProvider
    extends
        $FunctionalProvider<
          AsyncValue<RealmAuthoringCreationSlot>,
          AsyncValue<RealmAuthoringCreationSlot>,
          AsyncValue<RealmAuthoringCreationSlot>
        >
    with $Provider<AsyncValue<RealmAuthoringCreationSlot>> {
  /// Returns the live creation slot for one projected page.
  PageCreationSlotForPageProvider._({
    required PageCreationSlotForPageFamily super.from,
    required skir.ResourceId super.argument,
  }) : super(
         retry: null,
         name: r'pageCreationSlotForPageProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pageCreationSlotForPageHash();

  @override
  String toString() {
    return r'pageCreationSlotForPageProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<RealmAuthoringCreationSlot>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<RealmAuthoringCreationSlot> create(Ref ref) {
    final argument = this.argument as skir.ResourceId;
    return pageCreationSlotForPage(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<RealmAuthoringCreationSlot> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<AsyncValue<RealmAuthoringCreationSlot>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PageCreationSlotForPageProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pageCreationSlotForPageHash() =>
    r'c75a1dae7beef5470b177d2b18aaa026f640b61a';

/// Returns the live creation slot for one projected page.

final class PageCreationSlotForPageFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AsyncValue<RealmAuthoringCreationSlot>,
          skir.ResourceId
        > {
  PageCreationSlotForPageFamily._()
    : super(
        retry: null,
        name: r'pageCreationSlotForPageProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Returns the live creation slot for one projected page.

  PageCreationSlotForPageProvider call(skir.ResourceId pageId) =>
      PageCreationSlotForPageProvider._(argument: pageId, from: this);

  @override
  String toString() => r'pageCreationSlotForPageProvider';
}

/// Returns every page slot that accepts [elementType].

@ProviderFor(compatiblePageCreationSlots)
final compatiblePageCreationSlotsProvider =
    CompatiblePageCreationSlotsFamily._();

/// Returns every page slot that accepts [elementType].

final class CompatiblePageCreationSlotsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<PageKindRef, RealmAuthoringCreationSlot>>,
          AsyncValue<Map<PageKindRef, RealmAuthoringCreationSlot>>,
          AsyncValue<Map<PageKindRef, RealmAuthoringCreationSlot>>
        >
    with $Provider<AsyncValue<Map<PageKindRef, RealmAuthoringCreationSlot>>> {
  /// Returns every page slot that accepts [elementType].
  CompatiblePageCreationSlotsProvider._({
    required CompatiblePageCreationSlotsFamily super.from,
    required ResolvedTypeRef super.argument,
  }) : super(
         retry: null,
         name: r'compatiblePageCreationSlotsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$compatiblePageCreationSlotsHash();

  @override
  String toString() {
    return r'compatiblePageCreationSlotsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<Map<PageKindRef, RealmAuthoringCreationSlot>>>
  $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  AsyncValue<Map<PageKindRef, RealmAuthoringCreationSlot>> create(Ref ref) {
    final argument = this.argument as ResolvedTypeRef;
    return compatiblePageCreationSlots(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    AsyncValue<Map<PageKindRef, RealmAuthoringCreationSlot>> value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<
            AsyncValue<Map<PageKindRef, RealmAuthoringCreationSlot>>
          >(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CompatiblePageCreationSlotsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$compatiblePageCreationSlotsHash() =>
    r'95070ff9fda692d4b441a7615507e253c8e04c42';

/// Returns every page slot that accepts [elementType].

final class CompatiblePageCreationSlotsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AsyncValue<Map<PageKindRef, RealmAuthoringCreationSlot>>,
          ResolvedTypeRef
        > {
  CompatiblePageCreationSlotsFamily._()
    : super(
        retry: null,
        name: r'compatiblePageCreationSlotsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Returns every page slot that accepts [elementType].

  CompatiblePageCreationSlotsProvider call(ResolvedTypeRef elementType) =>
      CompatiblePageCreationSlotsProvider._(argument: elementType, from: this);

  @override
  String toString() => r'compatiblePageCreationSlotsProvider';
}

/// Returns the creation slot selected for every page kind in the catalog.

@ProviderFor(pageCreationSlots)
final pageCreationSlotsProvider = PageCreationSlotsProvider._();

/// Returns the creation slot selected for every page kind in the catalog.

final class PageCreationSlotsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<PageKindRef, RealmAuthoringCreationSlot>>,
          AsyncValue<Map<PageKindRef, RealmAuthoringCreationSlot>>,
          AsyncValue<Map<PageKindRef, RealmAuthoringCreationSlot>>
        >
    with $Provider<AsyncValue<Map<PageKindRef, RealmAuthoringCreationSlot>>> {
  /// Returns the creation slot selected for every page kind in the catalog.
  PageCreationSlotsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pageCreationSlotsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pageCreationSlotsHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<Map<PageKindRef, RealmAuthoringCreationSlot>>>
  $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  AsyncValue<Map<PageKindRef, RealmAuthoringCreationSlot>> create(Ref ref) {
    return pageCreationSlots(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    AsyncValue<Map<PageKindRef, RealmAuthoringCreationSlot>> value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<
            AsyncValue<Map<PageKindRef, RealmAuthoringCreationSlot>>
          >(value),
    );
  }
}

String _$pageCreationSlotsHash() => r'edec9ab87650fa90eb6845d8d6bc68f785dc9a7a';
