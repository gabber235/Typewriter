import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
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
  const factory PortablePresentationBindingSchema.complete(skir.TypeUse use) =
      CompletePortablePresentationBinding;

  const factory PortablePresentationBindingSchema.partial(
    skir.TypeSelection selection,
  ) = PartialPortablePresentationBinding;
}

@freezed
abstract class PortablePresentationBinding with _$PortablePresentationBinding {
  const factory PortablePresentationBinding({
    required PortablePresentationBindingSchema schema,
    required skir.DataValue value,
    @Default(false) bool editable,
    skir.ValueLocation? location,
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
    required skir.PresentationNode root,
    required Map<skir.ExpressionBindingId, PortablePresentationBinding>
    bindings,
    required skir.EvaluationBudget budget,
    skir.PresentationRole? role,
    skir.PresentationMaterial? material,
    Set<skir.PresentationId> activePresentations = const {},
    Map<String, skir.PresentationNode> slots = const {},
  }) {
    for (final value in bindings.values) {
      if (value.schema case PartialPortablePresentationBinding(:final selection)
          when selection is! skir.TypeSelection_pendingWrapper) {
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
    required skir.PresentationNode root,
    required Map<skir.ExpressionBindingId, PortablePresentationBinding>
    bindings,
    required skir.EvaluationBudget budget,
    required skir.PresentationRole? role,
    required skir.PresentationMaterial? material,
    required Set<skir.PresentationId> activePresentations,
    required Map<String, skir.PresentationNode> slots,
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
      skir.CapabilityId capabilityId,
      skir.DataValue payload,
    )?
    invokeCommand,
    Stream<skir.RealmPresentationSearchUpdate> Function(
      skir.RealmPresentationSearchRequest request,
    )?
    watchSearch,
    Future<void> Function()? reload,
    Future<void> Function()? commit,
    ValueChanged<skir.ResourceId>? openResource,
    Future<skir.PreparedCreation> Function(skir.InitializationRequest request)?
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

  skir.DataValue? read(skir.BindingRef reference);

  skir.ValueLocation? location(skir.BindingRef reference);

  skir.TypeUse? expectedType(skir.BindingRef reference);

  Future<PortablePresentationWriteResult> write(
    skir.BindingRef reference,
    skir.DataValue value,
  );

  Future<PortablePresentationWriteResult> execute(
    skir.EditorAction editorAction,
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
