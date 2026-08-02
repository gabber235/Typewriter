// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pages.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BookPages)
final bookPagesProvider = BookPagesFamily._();

final class BookPagesProvider
    extends $AsyncNotifierProvider<BookPages, List<Page>> {
  BookPagesProvider._({
    required BookPagesFamily super.from,
    required (skir.RecordId, String) super.argument,
  }) : super(
         retry: null,
         name: r'bookPagesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$bookPagesHash();

  @override
  String toString() {
    return r'bookPagesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  BookPages create() => BookPages();

  @override
  bool operator ==(Object other) {
    return other is BookPagesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$bookPagesHash() => r'352687bac2e3e87abdcf57cf90bdeb0d9c41ad29';

final class BookPagesFamily extends $Family
    with
        $ClassFamilyOverride<
          BookPages,
          AsyncValue<List<Page>>,
          List<Page>,
          FutureOr<List<Page>>,
          (skir.RecordId, String)
        > {
  BookPagesFamily._()
    : super(
        retry: null,
        name: r'bookPagesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BookPagesProvider call(skir.RecordId bookId, String search) =>
      BookPagesProvider._(argument: (bookId, search), from: this);

  @override
  String toString() => r'bookPagesProvider';
}

abstract class _$BookPages extends $AsyncNotifier<List<Page>> {
  late final _$args = ref.$arg as (skir.RecordId, String);
  skir.RecordId get bookId => _$args.$1;
  String get search => _$args.$2;

  FutureOr<List<Page>> build(skir.RecordId bookId, String search);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Page>>, List<Page>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Page>>, List<Page>>,
              AsyncValue<List<Page>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}

@ProviderFor(Pages)
final pagesProvider = PagesFamily._();

final class PagesProvider extends $StreamNotifierProvider<Pages, Page> {
  PagesProvider._({
    required PagesFamily super.from,
    required skir.RecordId super.argument,
  }) : super(
         retry: null,
         name: r'pagesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pagesHash();

  @override
  String toString() {
    return r'pagesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  Pages create() => Pages();

  @override
  bool operator ==(Object other) {
    return other is PagesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pagesHash() => r'98b51043aee9c9bdf6b6ed20fa19e78406786b0f';

final class PagesFamily extends $Family
    with
        $ClassFamilyOverride<
          Pages,
          AsyncValue<Page>,
          Page,
          Stream<Page>,
          skir.RecordId
        > {
  PagesFamily._()
    : super(
        retry: null,
        name: r'pagesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PagesProvider call(skir.RecordId pageId) =>
      PagesProvider._(argument: pageId, from: this);

  @override
  String toString() => r'pagesProvider';
}

abstract class _$Pages extends $StreamNotifier<Page> {
  late final _$args = ref.$arg as skir.RecordId;
  skir.RecordId get pageId => _$args;

  Stream<Page> build(skir.RecordId pageId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Page>, Page>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Page>, Page>,
              AsyncValue<Page>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(pageId)
final pageIdProvider = PageIdProvider._();

final class PageIdProvider
    extends $FunctionalProvider<skir.RecordId?, skir.RecordId?, skir.RecordId?>
    with $Provider<skir.RecordId?> {
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
  $ProviderElement<skir.RecordId?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  skir.RecordId? create(Ref ref) {
    return pageId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(skir.RecordId? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<skir.RecordId?>(value),
    );
  }
}

String _$pageIdHash() => r'e84de71cb1dea33c615fa06593cb8408a692b5d9';
