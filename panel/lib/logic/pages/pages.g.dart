// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pages.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BookPages)
const bookPagesProvider = BookPagesFamily._();

final class BookPagesProvider
    extends $AsyncNotifierProvider<BookPages, List<Page>> {
  const BookPagesProvider._({
    required BookPagesFamily super.from,
    required (String, String) super.argument,
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

String _$bookPagesHash() => r'422b81d9eef1fda6e63287c6343b301c44da6560';

final class BookPagesFamily extends $Family
    with
        $ClassFamilyOverride<
          BookPages,
          AsyncValue<List<Page>>,
          List<Page>,
          FutureOr<List<Page>>,
          (String, String)
        > {
  const BookPagesFamily._()
    : super(
        retry: null,
        name: r'bookPagesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BookPagesProvider call(String bookId, String search) =>
      BookPagesProvider._(argument: (bookId, search), from: this);

  @override
  String toString() => r'bookPagesProvider';
}

abstract class _$BookPages extends $AsyncNotifier<List<Page>> {
  late final _$args = ref.$arg as (String, String);
  String get bookId => _$args.$1;
  String get search => _$args.$2;

  FutureOr<List<Page>> build(String bookId, String search);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args.$1, _$args.$2);
    final ref = this.ref as $Ref<AsyncValue<List<Page>>, List<Page>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Page>>, List<Page>>,
              AsyncValue<List<Page>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(Pages)
const pagesProvider = PagesFamily._();

final class PagesProvider extends $AsyncNotifierProvider<Pages, Page> {
  const PagesProvider._({
    required PagesFamily super.from,
    required String super.argument,
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

String _$pagesHash() => r'b4b9ff353cfb53b4865fc4593fe71d9c7cfe9288';

final class PagesFamily extends $Family
    with
        $ClassFamilyOverride<
          Pages,
          AsyncValue<Page>,
          Page,
          FutureOr<Page>,
          String
        > {
  const PagesFamily._()
    : super(
        retry: null,
        name: r'pagesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PagesProvider call(String pageId) =>
      PagesProvider._(argument: pageId, from: this);

  @override
  String toString() => r'pagesProvider';
}

abstract class _$Pages extends $AsyncNotifier<Page> {
  late final _$args = ref.$arg as String;
  String get pageId => _$args;

  FutureOr<Page> build(String pageId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<AsyncValue<Page>, Page>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Page>, Page>,
              AsyncValue<Page>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(pageId)
const pageIdProvider = PageIdProvider._();

final class PageIdProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  const PageIdProvider._()
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
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return pageId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$pageIdHash() => r'9d2817f77c652614ac44fa6b2727dd7d17faae87';
