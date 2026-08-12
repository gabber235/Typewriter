// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_element_type_policy.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(pageElementTypePolicy)
final pageElementTypePolicyProvider = PageElementTypePolicyProvider._();

final class PageElementTypePolicyProvider
    extends
        $FunctionalProvider<
          PageElementTypePolicy,
          PageElementTypePolicy,
          PageElementTypePolicy
        >
    with $Provider<PageElementTypePolicy> {
  PageElementTypePolicyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pageElementTypePolicyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pageElementTypePolicyHash();

  @$internal
  @override
  $ProviderElement<PageElementTypePolicy> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PageElementTypePolicy create(Ref ref) {
    return pageElementTypePolicy(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PageElementTypePolicy value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PageElementTypePolicy>(value),
    );
  }
}

String _$pageElementTypePolicyHash() =>
    r'5882b46dc04d375dfe1c49aadf2d99ad46d22bc6';

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
    required PageType super.argument,
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
    final argument = this.argument as PageType;
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

String _$pageElementTypesHash() => r'c8ac18e538f90296ca697901982c3c34d7a037de';

final class PageElementTypesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<PageElementTypesState>, PageType> {
  PageElementTypesFamily._()
    : super(
        retry: null,
        name: r'pageElementTypesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PageElementTypesProvider call(PageType pageType) =>
      PageElementTypesProvider._(argument: pageType, from: this);

  @override
  String toString() => r'pageElementTypesProvider';
}
