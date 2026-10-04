import "package:flutter/foundation.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/action.dart"
    as action;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/binding.dart"
    as binding;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/catalog.dart"
    as catalog_wire;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/expression.dart"
    as expression;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/presentation.dart"
    as presentation;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/search.dart"
    as search;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;
import "package:typewriter_panel/typewriter_panel.dart";

part "portable_presentation_host.freezed.dart";

/// One value exposed to a portable presentation.
///
/// The binding carries its exact checked type and current value. An editable
/// binding delegates every mutation to [PortablePresentationHost], which keeps
/// the persistence owner outside the presentation document.
@freezed
sealed class PortablePresentationBindingSchema
    with _$PortablePresentationBindingSchema {
  const factory PortablePresentationBindingSchema.complete(types.TypeUse use) =
      CompletePortablePresentationBinding;

  const factory PortablePresentationBindingSchema.partial(
    types.TypeSelection selection,
  ) = PartialPortablePresentationBinding;
}

@freezed
abstract class PortablePresentationBinding with _$PortablePresentationBinding {
  const factory PortablePresentationBinding({
    required PortablePresentationBindingSchema schema,
    required types.DataValue value,
    @Default(false) bool editable,
    types.ValueLocation? location,
  }) = _PortablePresentationBinding;
}

/// An immutable presentation observation interpreted by one checked catalog.
///
/// Local service documents and Realm documents use the same generated values,
/// expressions, and presentation tree. Persistence and optional capabilities
/// remain on the host that produced this observation.
@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class PortablePresentationDocument
    with _$PortablePresentationDocument {
  factory PortablePresentationDocument({
    required CheckedEditorCatalog catalog,
    required presentation.PresentationNode root,
    required Map<types.ExpressionBindingId, PortablePresentationBinding>
    bindings,
    required expression.EvaluationBudget budget,
    catalog_wire.PresentationRole? role,
    catalog_wire.PresentationMaterial? material,
    Set<types.PresentationId> activePresentations = const {},
    Map<String, presentation.PresentationNode> slots = const {},
  }) {
    for (final value in bindings.values) {
      if (value.schema case PartialPortablePresentationBinding(:final selection)
          when selection is! types.TypeSelection_pendingWrapper) {
        throw ArgumentError.value(
          selection,
          "bindings",
          "Partial bindings require an unfinished type selection",
        );
      }
    }
    return PortablePresentationDocument._value(
      catalog: catalog,
      root: root,
      bindings: Map.unmodifiable(bindings),
      budget: budget,
      role: role,
      material: material,
      activePresentations: Set.unmodifiable(activePresentations),
      slots: Map.unmodifiable(slots),
    );
  }

  const PortablePresentationDocument._();

  const factory PortablePresentationDocument._value({
    required CheckedEditorCatalog catalog,
    required presentation.PresentationNode root,
    required Map<types.ExpressionBindingId, PortablePresentationBinding>
    bindings,
    required expression.EvaluationBudget budget,
    required catalog_wire.PresentationRole? role,
    required catalog_wire.PresentationMaterial? material,
    required Set<types.PresentationId> activePresentations,
    required Map<String, presentation.PresentationNode> slots,
  }) = _PortablePresentationDocument;
}

/// Optional operations supplied by hosts that support more than local writes.
///
/// A service or topology editor normally leaves these callbacks absent. A
/// Realm host can attach its existing search, initialization, navigation, and
/// command operations without changing the portable document.
@freezed
abstract class PortablePresentationCapabilities
    with _$PortablePresentationCapabilities {
  const factory PortablePresentationCapabilities({
    Future<void> Function(
      types.CapabilityId capabilityId,
      types.DataValue payload,
    )?
    invokeCommand,
    Stream<search.RealmPresentationSearchUpdate> Function(
      search.RealmPresentationSearchRequest request,
    )?
    watchSearch,
    Future<void> Function()? reload,
    Future<void> Function()? commit,
    ValueChanged<types.ResourceId>? openResource,
    Future<catalog_wire.PreparedCreation> Function(
      catalog_wire.InitializationRequest request,
    )?
    prepareCreation,
  }) = _PortablePresentationCapabilities;
}

@freezed
sealed class PortablePresentationWriteResult
    with _$PortablePresentationWriteResult {
  const factory PortablePresentationWriteResult.applied() =
      PortablePresentationWriteApplied;

  const factory PortablePresentationWriteResult.rejected(String message) =
      PortablePresentationWriteRejected;
}

/// Owns one portable presentation document and its mutation boundary.
///
/// Implementations notify listeners after their document changes. Reads stay
/// synchronous so one render observes one coherent document. Writes and
/// actions may suspend while their owning persistence boundary prepares work.
abstract interface class PortablePresentationHost implements Listenable {
  PortablePresentationDocument get document;

  bool get enabled;

  bool get readOnly;

  PortablePresentationCapabilities get capabilities;

  types.DataValue? read(binding.BindingRef reference);

  types.ValueLocation? location(binding.BindingRef reference);

  types.TypeUse? expectedType(binding.BindingRef reference);

  Future<PortablePresentationWriteResult> write(
    binding.BindingRef reference,
    types.DataValue value,
  );

  Future<PortablePresentationWriteResult> execute(
    action.EditorAction editorAction,
  );

  void dispose();
}

/// Supplies the portable presentation used to review one retained draft.
///
/// The target owns the feature specific schema and binding codecs. The local
/// work session owns the live [EditorSource], so constructing this host keeps
/// presentation metadata separate from draft persistence and conflict policy.
abstract interface class PortablePresentationTarget {
  PortablePresentationHost? buildPortablePresentationHost(EditorSource source);
}

typedef PortablePresentationHostBuilder = PortablePresentationHost Function(
  EditorSource source,
);
