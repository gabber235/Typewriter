// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inspection.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Adapts the global selectable selection to resources supported by the
/// inspector.
///
/// [selectedProvider] remains the source of truth for identifiers and focus is
/// not consulted. A selection containing an unsupported selectable produces an
/// empty inspection rather than a partial editor.

@ProviderFor(inspectedSelection)
final inspectedSelectionProvider = InspectedSelectionProvider._();

/// Adapts the global selectable selection to resources supported by the
/// inspector.
///
/// [selectedProvider] remains the source of truth for identifiers and focus is
/// not consulted. A selection containing an unsupported selectable produces an
/// empty inspection rather than a partial editor.

final class InspectedSelectionProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<InspectableSelectable<SelectableIdentifier>>>,
          AsyncValue<List<InspectableSelectable<SelectableIdentifier>>>,
          AsyncValue<List<InspectableSelectable<SelectableIdentifier>>>
        >
    with
        $Provider<
          AsyncValue<List<InspectableSelectable<SelectableIdentifier>>>
        > {
  /// Adapts the global selectable selection to resources supported by the
  /// inspector.
  ///
  /// [selectedProvider] remains the source of truth for identifiers and focus is
  /// not consulted. A selection containing an unsupported selectable produces an
  /// empty inspection rather than a partial editor.
  InspectedSelectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inspectedSelectionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inspectedSelectionHash();

  @$internal
  @override
  $ProviderElement<
    AsyncValue<List<InspectableSelectable<SelectableIdentifier>>>
  >
  $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  AsyncValue<List<InspectableSelectable<SelectableIdentifier>>> create(
    Ref ref,
  ) {
    return inspectedSelection(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    AsyncValue<List<InspectableSelectable<SelectableIdentifier>>> value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<
            AsyncValue<List<InspectableSelectable<SelectableIdentifier>>>
          >(value),
    );
  }
}

String _$inspectedSelectionHash() =>
    r'fdba8a3d317c067c0afab2040f701d5c23ebca8d';

/// Whether the inspector should occupy space for the current selection.
///
/// Loading and error states intentionally remain visible. The session replaces
/// the graph with an unavailable state while selected resources refresh.

@ProviderFor(hasInspectableSelection)
final hasInspectableSelectionProvider = HasInspectableSelectionProvider._();

/// Whether the inspector should occupy space for the current selection.
///
/// Loading and error states intentionally remain visible. The session replaces
/// the graph with an unavailable state while selected resources refresh.

final class HasInspectableSelectionProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the inspector should occupy space for the current selection.
  ///
  /// Loading and error states intentionally remain visible. The session replaces
  /// the graph with an unavailable state while selected resources refresh.
  HasInspectableSelectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hasInspectableSelectionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hasInspectableSelectionHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return hasInspectableSelection(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$hasInspectableSelectionHash() =>
    r'7cbf8deaf3235756f3140f855bf5bd9bf7d40ccb';

/// Owns the inspection graph and its temporary composite editor lifetime.
///
/// The provider is scoped to local work, because resource owners and drafts are
/// scoped to the same workspace session.

@ProviderFor(inspectionSession)
final inspectionSessionProvider = InspectionSessionProvider._();

/// Owns the inspection graph and its temporary composite editor lifetime.
///
/// The provider is scoped to local work, because resource owners and drafts are
/// scoped to the same workspace session.

final class InspectionSessionProvider
    extends
        $FunctionalProvider<
          InspectionSession,
          InspectionSession,
          InspectionSession
        >
    with $Provider<InspectionSession> {
  /// Owns the inspection graph and its temporary composite editor lifetime.
  ///
  /// The provider is scoped to local work, because resource owners and drafts are
  /// scoped to the same workspace session.
  InspectionSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inspectionSessionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inspectionSessionHash();

  @$internal
  @override
  $ProviderElement<InspectionSession> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InspectionSession create(Ref ref) {
    return inspectionSession(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InspectionSession value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InspectionSession>(value),
    );
  }
}

String _$inspectionSessionHash() => r'14f2a059ff1e398bb511ef4551ed1a6076bcf77f';
