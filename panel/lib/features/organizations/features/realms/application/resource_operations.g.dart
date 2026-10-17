// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resource_operations.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Resolves one complete operation set against a coherent working observation.

@ProviderFor(resourceOperations)
final resourceOperationsProvider = ResourceOperationsFamily._();

/// Resolves one complete operation set against a coherent working observation.

final class ResourceOperationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<skir.ResolvedResourceOperations>,
          skir.ResolvedResourceOperations,
          FutureOr<skir.ResolvedResourceOperations>
        >
    with
        $FutureModifier<skir.ResolvedResourceOperations>,
        $FutureProvider<skir.ResolvedResourceOperations> {
  /// Resolves one complete operation set against a coherent working observation.
  ResourceOperationsProvider._({
    required ResourceOperationsFamily super.from,
    required (AuthoringScope, skir.OperationInvocation) super.argument,
  }) : super(
         retry: null,
         name: r'resourceOperationsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$resourceOperationsHash();

  @override
  String toString() {
    return r'resourceOperationsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<skir.ResolvedResourceOperations> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<skir.ResolvedResourceOperations> create(Ref ref) {
    final argument =
        this.argument as (AuthoringScope, skir.OperationInvocation);
    return resourceOperations(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is ResourceOperationsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$resourceOperationsHash() =>
    r'922713453e17075a0a5df641f9fa42778ec0a477';

/// Resolves one complete operation set against a coherent working observation.

final class ResourceOperationsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<skir.ResolvedResourceOperations>,
          (AuthoringScope, skir.OperationInvocation)
        > {
  ResourceOperationsFamily._()
    : super(
        retry: null,
        name: r'resourceOperationsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Resolves one complete operation set against a coherent working observation.

  ResourceOperationsProvider call(
    AuthoringScope scope,
    skir.OperationInvocation invocation,
  ) => ResourceOperationsProvider._(argument: (scope, invocation), from: this);

  @override
  String toString() => r'resourceOperationsProvider';
}

/// Hover checks share preparation with activation and never stage their result.

@ProviderFor(resourceDropAvailable)
final resourceDropAvailableProvider = ResourceDropAvailableFamily._();

/// Hover checks share preparation with activation and never stage their result.

final class ResourceDropAvailableProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Hover checks share preparation with activation and never stage their result.
  ResourceDropAvailableProvider._({
    required ResourceDropAvailableFamily super.from,
    required (AuthoringScope, skir.OperationInvocation, String, skir.DataValue)
    super.argument,
  }) : super(
         retry: null,
         name: r'resourceDropAvailableProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$resourceDropAvailableHash();

  @override
  String toString() {
    return r'resourceDropAvailableProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument =
        this.argument
            as (
              AuthoringScope,
              skir.OperationInvocation,
              String,
              skir.DataValue,
            );
    return resourceDropAvailable(
      ref,
      argument.$1,
      argument.$2,
      argument.$3,
      argument.$4,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ResourceDropAvailableProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$resourceDropAvailableHash() =>
    r'8434e09a288392c5e48807938124bd75bc89540a';

/// Hover checks share preparation with activation and never stage their result.

final class ResourceDropAvailableFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<bool>,
          (AuthoringScope, skir.OperationInvocation, String, skir.DataValue)
        > {
  ResourceDropAvailableFamily._()
    : super(
        retry: null,
        name: r'resourceDropAvailableProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Hover checks share preparation with activation and never stage their result.

  ResourceDropAvailableProvider call(
    AuthoringScope scope,
    skir.OperationInvocation invocation,
    String operationLocalId,
    skir.DataValue supplied,
  ) => ResourceDropAvailableProvider._(
    argument: (scope, invocation, operationLocalId, supplied),
    from: this,
  );

  @override
  String toString() => r'resourceDropAvailableProvider';
}
