// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pages.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Retains and exposes canonical pages belonging to one book.
///
/// The realm authoring session owns the data and server sequence. This provider
/// leases the book scope for its lifetime, refreshes on sequenced session
/// observations, and does not include local editor drafts.

@ProviderFor(CanonicalBookPages)
final canonicalBookPagesProvider = CanonicalBookPagesFamily._();

/// Retains and exposes canonical pages belonging to one book.
///
/// The realm authoring session owns the data and server sequence. This provider
/// leases the book scope for its lifetime, refreshes on sequenced session
/// observations, and does not include local editor drafts.
final class CanonicalBookPagesProvider
    extends $AsyncNotifierProvider<CanonicalBookPages, List<Page>> {
  /// Retains and exposes canonical pages belonging to one book.
  ///
  /// The realm authoring session owns the data and server sequence. This provider
  /// leases the book scope for its lifetime, refreshes on sequenced session
  /// observations, and does not include local editor drafts.
  CanonicalBookPagesProvider._({
    required CanonicalBookPagesFamily super.from,
    required skir.ResourceId super.argument,
  }) : super(
         retry: null,
         name: r'canonicalBookPagesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$canonicalBookPagesHash();

  @override
  String toString() {
    return r'canonicalBookPagesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CanonicalBookPages create() => CanonicalBookPages();

  @override
  bool operator ==(Object other) {
    return other is CanonicalBookPagesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$canonicalBookPagesHash() =>
    r'060f0ee8130a123f49c09a15b018439f8dc3ec22';

/// Retains and exposes canonical pages belonging to one book.
///
/// The realm authoring session owns the data and server sequence. This provider
/// leases the book scope for its lifetime, refreshes on sequenced session
/// observations, and does not include local editor drafts.

final class CanonicalBookPagesFamily extends $Family
    with
        $ClassFamilyOverride<
          CanonicalBookPages,
          AsyncValue<List<Page>>,
          List<Page>,
          FutureOr<List<Page>>,
          skir.ResourceId
        > {
  CanonicalBookPagesFamily._()
    : super(
        retry: null,
        name: r'canonicalBookPagesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Retains and exposes canonical pages belonging to one book.
  ///
  /// The realm authoring session owns the data and server sequence. This provider
  /// leases the book scope for its lifetime, refreshes on sequenced session
  /// observations, and does not include local editor drafts.

  CanonicalBookPagesProvider call(skir.ResourceId bookId) =>
      CanonicalBookPagesProvider._(argument: bookId, from: this);

  @override
  String toString() => r'canonicalBookPagesProvider';
}

/// Retains and exposes canonical pages belonging to one book.
///
/// The realm authoring session owns the data and server sequence. This provider
/// leases the book scope for its lifetime, refreshes on sequenced session
/// observations, and does not include local editor drafts.

abstract class _$CanonicalBookPages extends $AsyncNotifier<List<Page>> {
  late final _$args = ref.$arg as skir.ResourceId;
  skir.ResourceId get bookId => _$args;

  FutureOr<List<Page>> build(skir.ResourceId bookId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Page>>, List<Page>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Page>>, List<Page>>,
              AsyncValue<List<Page>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Retains one canonical page through a page scope lease.
///
/// Missing pages become a not found outcome after the authoritative snapshot or
/// a later sequenced removal. Draft values are intentionally supplied by
/// [projectedPage], not this provider.

@ProviderFor(CanonicalPage)
final canonicalPageProvider = CanonicalPageFamily._();

/// Retains one canonical page through a page scope lease.
///
/// Missing pages become a not found outcome after the authoritative snapshot or
/// a later sequenced removal. Draft values are intentionally supplied by
/// [projectedPage], not this provider.
final class CanonicalPageProvider
    extends $AsyncNotifierProvider<CanonicalPage, Page> {
  /// Retains one canonical page through a page scope lease.
  ///
  /// Missing pages become a not found outcome after the authoritative snapshot or
  /// a later sequenced removal. Draft values are intentionally supplied by
  /// [projectedPage], not this provider.
  CanonicalPageProvider._({
    required CanonicalPageFamily super.from,
    required skir.ResourceId super.argument,
  }) : super(
         retry: null,
         name: r'canonicalPageProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$canonicalPageHash();

  @override
  String toString() {
    return r'canonicalPageProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CanonicalPage create() => CanonicalPage();

  @override
  bool operator ==(Object other) {
    return other is CanonicalPageProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$canonicalPageHash() => r'0ba1cbb08766b74f6f63a0582141723a52c99810';

/// Retains one canonical page through a page scope lease.
///
/// Missing pages become a not found outcome after the authoritative snapshot or
/// a later sequenced removal. Draft values are intentionally supplied by
/// [projectedPage], not this provider.

final class CanonicalPageFamily extends $Family
    with
        $ClassFamilyOverride<
          CanonicalPage,
          AsyncValue<Page>,
          Page,
          FutureOr<Page>,
          skir.ResourceId
        > {
  CanonicalPageFamily._()
    : super(
        retry: null,
        name: r'canonicalPageProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Retains one canonical page through a page scope lease.
  ///
  /// Missing pages become a not found outcome after the authoritative snapshot or
  /// a later sequenced removal. Draft values are intentionally supplied by
  /// [projectedPage], not this provider.

  CanonicalPageProvider call(skir.ResourceId pageId) =>
      CanonicalPageProvider._(argument: pageId, from: this);

  @override
  String toString() => r'canonicalPageProvider';
}

/// Retains one canonical page through a page scope lease.
///
/// Missing pages become a not found outcome after the authoritative snapshot or
/// a later sequenced removal. Draft values are intentionally supplied by
/// [projectedPage], not this provider.

abstract class _$CanonicalPage extends $AsyncNotifier<Page> {
  late final _$args = ref.$arg as skir.ResourceId;
  skir.ResourceId get pageId => _$args;

  FutureOr<Page> build(skir.ResourceId pageId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Page>, Page>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Page>, Page>,
              AsyncValue<Page>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Produces the book page list visible to the library sidebar.
///
/// Canonical pages are overlaid with current local drafts, then filtered by
/// page name or chapter. Missing organization or realm context falls back to
/// canonical data because no scoped local projection can be selected.

@ProviderFor(projectedBookPages)
final projectedBookPagesProvider = ProjectedBookPagesFamily._();

/// Produces the book page list visible to the library sidebar.
///
/// Canonical pages are overlaid with current local drafts, then filtered by
/// page name or chapter. Missing organization or realm context falls back to
/// canonical data because no scoped local projection can be selected.

final class ProjectedBookPagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Page>>,
          AsyncValue<List<Page>>,
          AsyncValue<List<Page>>
        >
    with $Provider<AsyncValue<List<Page>>> {
  /// Produces the book page list visible to the library sidebar.
  ///
  /// Canonical pages are overlaid with current local drafts, then filtered by
  /// page name or chapter. Missing organization or realm context falls back to
  /// canonical data because no scoped local projection can be selected.
  ProjectedBookPagesProvider._({
    required ProjectedBookPagesFamily super.from,
    required (skir.ResourceId, String) super.argument,
  }) : super(
         retry: null,
         name: r'projectedBookPagesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$projectedBookPagesHash();

  @override
  String toString() {
    return r'projectedBookPagesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<List<Page>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<Page>> create(Ref ref) {
    final argument = this.argument as (skir.ResourceId, String);
    return projectedBookPages(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<Page>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<Page>>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProjectedBookPagesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$projectedBookPagesHash() =>
    r'6a33308159b0dcfa293cc098ff02d75cf043534e';

/// Produces the book page list visible to the library sidebar.
///
/// Canonical pages are overlaid with current local drafts, then filtered by
/// page name or chapter. Missing organization or realm context falls back to
/// canonical data because no scoped local projection can be selected.

final class ProjectedBookPagesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AsyncValue<List<Page>>,
          (skir.ResourceId, String)
        > {
  ProjectedBookPagesFamily._()
    : super(
        retry: null,
        name: r'projectedBookPagesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Produces the book page list visible to the library sidebar.
  ///
  /// Canonical pages are overlaid with current local drafts, then filtered by
  /// page name or chapter. Missing organization or realm context falls back to
  /// canonical data because no scoped local projection can be selected.

  ProjectedBookPagesProvider call(skir.ResourceId bookId, String search) =>
      ProjectedBookPagesProvider._(argument: (bookId, search), from: this);

  @override
  String toString() => r'projectedBookPagesProvider';
}

/// Produces all projected pages in the active realm.

@ProviderFor(projectedPages)
final projectedPagesProvider = ProjectedPagesProvider._();

/// Produces all projected pages in the active realm.

final class ProjectedPagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Page>>,
          AsyncValue<List<Page>>,
          AsyncValue<List<Page>>
        >
    with $Provider<AsyncValue<List<Page>>> {
  /// Produces all projected pages in the active realm.
  ProjectedPagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectedPagesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectedPagesHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<Page>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<Page>> create(Ref ref) {
    return projectedPages(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<Page>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<Page>>>(value),
    );
  }
}

String _$projectedPagesHash() => r'604fff2de859faac6cfed763a74dd8d8acd61256';

/// Produces one page with its current local metadata projection.
///
/// Canonical loading and errors pass through. An invalid draft projection is
/// ignored by [Page.projected], preserving the last valid visible metadata.

@ProviderFor(projectedPage)
final projectedPageProvider = ProjectedPageFamily._();

/// Produces one page with its current local metadata projection.
///
/// Canonical loading and errors pass through. An invalid draft projection is
/// ignored by [Page.projected], preserving the last valid visible metadata.

final class ProjectedPageProvider
    extends
        $FunctionalProvider<
          AsyncValue<Page>,
          AsyncValue<Page>,
          AsyncValue<Page>
        >
    with $Provider<AsyncValue<Page>> {
  /// Produces one page with its current local metadata projection.
  ///
  /// Canonical loading and errors pass through. An invalid draft projection is
  /// ignored by [Page.projected], preserving the last valid visible metadata.
  ProjectedPageProvider._({
    required ProjectedPageFamily super.from,
    required skir.ResourceId super.argument,
  }) : super(
         retry: null,
         name: r'projectedPageProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$projectedPageHash();

  @override
  String toString() {
    return r'projectedPageProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<Page>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AsyncValue<Page> create(Ref ref) {
    final argument = this.argument as skir.ResourceId;
    return projectedPage(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<Page> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<Page>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProjectedPageProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$projectedPageHash() => r'c016ba20844afb63f2a9dc30ca7d1a2146794212';

/// Produces one page with its current local metadata projection.
///
/// Canonical loading and errors pass through. An invalid draft projection is
/// ignored by [Page.projected], preserving the last valid visible metadata.

final class ProjectedPageFamily extends $Family
    with $FunctionalFamilyOverride<AsyncValue<Page>, skir.ResourceId> {
  ProjectedPageFamily._()
    : super(
        retry: null,
        name: r'projectedPageProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Produces one page with its current local metadata projection.
  ///
  /// Canonical loading and errors pass through. An invalid draft projection is
  /// ignored by [Page.projected], preserving the last valid visible metadata.

  ProjectedPageProvider call(skir.ResourceId pageId) =>
      ProjectedPageProvider._(argument: pageId, from: this);

  @override
  String toString() => r'projectedPageProvider';
}

/// Resolves the route's string parameter to the typed page record identity.

@ProviderFor(pageId)
final pageIdProvider = PageIdProvider._();

/// Resolves the route's string parameter to the typed page record identity.

final class PageIdProvider
    extends
        $FunctionalProvider<
          skir.ResourceId?,
          skir.ResourceId?,
          skir.ResourceId?
        >
    with $Provider<skir.ResourceId?> {
  /// Resolves the route's string parameter to the typed page record identity.
  PageIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pageIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pageIdHash();

  @$internal
  @override
  $ProviderElement<skir.ResourceId?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  skir.ResourceId? create(Ref ref) {
    return pageId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(skir.ResourceId? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<skir.ResourceId?>(value),
    );
  }
}

String _$pageIdHash() => r'fb91dcb92fa878f2ab501d2e2f8431b1c500b34c';
