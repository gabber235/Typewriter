// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pages.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// All pages in the working document, including resources without a book yet.

@ProviderFor(workingPages)
final workingPagesProvider = WorkingPagesProvider._();

/// All pages in the working document, including resources without a book yet.

final class WorkingPagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Page>>,
          AsyncValue<List<Page>>,
          AsyncValue<List<Page>>
        >
    with $Provider<AsyncValue<List<Page>>> {
  /// All pages in the working document, including resources without a book yet.
  WorkingPagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workingPagesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workingPagesHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<Page>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<Page>> create(Ref ref) {
    return workingPages(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<Page>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<Page>>>(value),
    );
  }
}

String _$workingPagesHash() => r'06ed22c601558b83a567733de5605ec307a6d3ce';

@ProviderFor(workingBookPages)
final workingBookPagesProvider = WorkingBookPagesFamily._();

final class WorkingBookPagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Page>>,
          AsyncValue<List<Page>>,
          AsyncValue<List<Page>>
        >
    with $Provider<AsyncValue<List<Page>>> {
  WorkingBookPagesProvider._({
    required WorkingBookPagesFamily super.from,
    required (skir.ResourceId, String) super.argument,
  }) : super(
         retry: null,
         name: r'workingBookPagesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workingBookPagesHash();

  @override
  String toString() {
    return r'workingBookPagesProvider'
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
    return workingBookPages(ref, argument.$1, argument.$2);
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
    return other is WorkingBookPagesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workingBookPagesHash() => r'fe65d45ad71fafb68e003a39649b808599955bc9';

final class WorkingBookPagesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AsyncValue<List<Page>>,
          (skir.ResourceId, String)
        > {
  WorkingBookPagesFamily._()
    : super(
        retry: null,
        name: r'workingBookPagesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkingBookPagesProvider call(skir.ResourceId bookId, String search) =>
      WorkingBookPagesProvider._(argument: (bookId, search), from: this);

  @override
  String toString() => r'workingBookPagesProvider';
}

@ProviderFor(workingPage)
final workingPageProvider = WorkingPageFamily._();

final class WorkingPageProvider
    extends
        $FunctionalProvider<
          AsyncValue<Page>,
          AsyncValue<Page>,
          AsyncValue<Page>
        >
    with $Provider<AsyncValue<Page>> {
  WorkingPageProvider._({
    required WorkingPageFamily super.from,
    required skir.ResourceId super.argument,
  }) : super(
         retry: null,
         name: r'workingPageProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workingPageHash();

  @override
  String toString() {
    return r'workingPageProvider'
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
    return workingPage(ref, argument);
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
    return other is WorkingPageProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workingPageHash() => r'5a0d72cb70bc5583548a08417438f9c39a9f0ce5';

final class WorkingPageFamily extends $Family
    with $FunctionalFamilyOverride<AsyncValue<Page>, skir.ResourceId> {
  WorkingPageFamily._()
    : super(
        retry: null,
        name: r'workingPageProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkingPageProvider call(skir.ResourceId pageId) =>
      WorkingPageProvider._(argument: pageId, from: this);

  @override
  String toString() => r'workingPageProvider';
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
