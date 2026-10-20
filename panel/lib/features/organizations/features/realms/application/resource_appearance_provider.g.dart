// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resource_appearance_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Name, accent and icon of one resource from its most specific declared
/// display, in the working observation of [scope].
///
/// Selects only the resource record and the catalog, so edits to other
/// resources do not recompute it. A missing resource has no appearance;
/// callers render their own missing state instead of a raw id.

@ProviderFor(resourceAppearance)
final resourceAppearanceProvider = ResourceAppearanceFamily._();

/// Name, accent and icon of one resource from its most specific declared
/// display, in the working observation of [scope].
///
/// Selects only the resource record and the catalog, so edits to other
/// resources do not recompute it. A missing resource has no appearance;
/// callers render their own missing state instead of a raw id.

final class ResourceAppearanceProvider
    extends
        $FunctionalProvider<
          ResourceAppearance?,
          ResourceAppearance?,
          ResourceAppearance?
        >
    with $Provider<ResourceAppearance?> {
  /// Name, accent and icon of one resource from its most specific declared
  /// display, in the working observation of [scope].
  ///
  /// Selects only the resource record and the catalog, so edits to other
  /// resources do not recompute it. A missing resource has no appearance;
  /// callers render their own missing state instead of a raw id.
  ResourceAppearanceProvider._({
    required ResourceAppearanceFamily super.from,
    required (AuthoringScope, skir.ResourceId) super.argument,
  }) : super(
         retry: null,
         name: r'resourceAppearanceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$resourceAppearanceHash();

  @override
  String toString() {
    return r'resourceAppearanceProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<ResourceAppearance?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ResourceAppearance? create(Ref ref) {
    final argument = this.argument as (AuthoringScope, skir.ResourceId);
    return resourceAppearance(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ResourceAppearance? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ResourceAppearance?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ResourceAppearanceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$resourceAppearanceHash() =>
    r'dd30cf6b260f588cfb13fcf7f493da36282f9553';

/// Name, accent and icon of one resource from its most specific declared
/// display, in the working observation of [scope].
///
/// Selects only the resource record and the catalog, so edits to other
/// resources do not recompute it. A missing resource has no appearance;
/// callers render their own missing state instead of a raw id.

final class ResourceAppearanceFamily extends $Family
    with
        $FunctionalFamilyOverride<
          ResourceAppearance?,
          (AuthoringScope, skir.ResourceId)
        > {
  ResourceAppearanceFamily._()
    : super(
        retry: null,
        name: r'resourceAppearanceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Name, accent and icon of one resource from its most specific declared
  /// display, in the working observation of [scope].
  ///
  /// Selects only the resource record and the catalog, so edits to other
  /// resources do not recompute it. A missing resource has no appearance;
  /// callers render their own missing state instead of a raw id.

  ResourceAppearanceProvider call(AuthoringScope scope, skir.ResourceId id) =>
      ResourceAppearanceProvider._(argument: (scope, id), from: this);

  @override
  String toString() => r'resourceAppearanceProvider';
}
