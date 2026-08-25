// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_element_type_policy.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(pageElementTypes)
final pageElementTypesProvider = PageElementTypesFamily._();

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

  PageElementTypesProvider call(PageKindRef pageKind) =>
      PageElementTypesProvider._(argument: pageKind, from: this);

  @override
  String toString() => r'pageElementTypesProvider';
}
