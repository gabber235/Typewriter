// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resource_drop.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetched once when a drag starts, so hovering is a local lookup. Retries a
/// stale observation once, as [resourceOperations] does.

@ProviderFor(dropCandidates)
final dropCandidatesProvider = DropCandidatesFamily._();

/// Fetched once when a drag starts, so hovering is a local lookup. Retries a
/// stale observation once, as [resourceOperations] does.

final class DropCandidatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<DropCandidateIndex>,
          DropCandidateIndex,
          FutureOr<DropCandidateIndex>
        >
    with
        $FutureModifier<DropCandidateIndex>,
        $FutureProvider<DropCandidateIndex> {
  /// Fetched once when a drag starts, so hovering is a local lookup. Retries a
  /// stale observation once, as [resourceOperations] does.
  DropCandidatesProvider._({
    required DropCandidatesFamily super.from,
    required ResourceDrag super.argument,
  }) : super(
         retry: null,
         name: r'dropCandidatesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dropCandidatesHash();

  @override
  String toString() {
    return r'dropCandidatesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<DropCandidateIndex> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DropCandidateIndex> create(Ref ref) {
    final argument = this.argument as ResourceDrag;
    return dropCandidates(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DropCandidatesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dropCandidatesHash() => r'6729641b83a2465c21ef7d0df7878b8c69fa9023';

/// Fetched once when a drag starts, so hovering is a local lookup. Retries a
/// stale observation once, as [resourceOperations] does.

final class DropCandidatesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<DropCandidateIndex>, ResourceDrag> {
  DropCandidatesFamily._()
    : super(
        retry: null,
        name: r'dropCandidatesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetched once when a drag starts, so hovering is a local lookup. Retries a
  /// stale observation once, as [resourceOperations] does.

  DropCandidatesProvider call(ResourceDrag drag) =>
      DropCandidatesProvider._(argument: drag, from: this);

  @override
  String toString() => r'dropCandidatesProvider';
}
