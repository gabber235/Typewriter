import "package:collection/collection.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "presentation_model.freezed.dart";

/// Owns the collection sources available to one composed presentation.
///
/// Sources are indexed once at model construction so renderers can resolve a
/// collection by identifier without accepting duplicate definitions. The
/// resulting map is immutable and remains owned by this value object.
@immutable
final class PresentationCollections {
  factory PresentationCollections(
    Iterable<PresentationCollectionSource> sources,
  ) {
    final byId =
        <PresentationCollectionSourceId, PresentationCollectionSource>{};
    for (final source in sources) {
      if (byId.containsKey(source.id)) {
        throw ArgumentError.value(
          source.id,
          "sources",
          "Collection identifiers must be unique",
        );
      }
      byId[source.id] = source;
    }
    return PresentationCollections._(Map.unmodifiable(byId));
  }

  const PresentationCollections.empty() : _byId = const {};

  const PresentationCollections._(this._byId);

  final Map<PresentationCollectionSourceId, PresentationCollectionSource> _byId;

  /// Exposes the immutable source index used by presentation evaluation.
  Map<PresentationCollectionSourceId, PresentationCollectionSource> get byId =>
      _byId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationCollections &&
          const MapEquality<
                PresentationCollectionSourceId,
                PresentationCollectionSource
              >()
              .equals(_byId, other._byId);

  @override
  int get hashCode =>
      const MapEquality<
            PresentationCollectionSourceId,
            PresentationCollectionSource
          >()
          .hash(_byId);
}

/// Connects one presentation binding to either data or an edit owner.
///
/// Value inputs are read only observations. Edit inputs retain the owner and
/// relative path needed to route mutations back to the owner that controls the
/// draft. Keeping that distinction in the model lets a composed presentation
/// expose read and write capability without owning editor state.
@freezed
sealed class PresentationInput with _$PresentationInput {
  const factory PresentationInput.value({
    required TypeExpression type,
    required EditorValue value,
  }) = PresentationValueInput;
  const factory PresentationInput.edit(
    EditOwner owner, {
    @Default(DataPath.root) DataPath path,
  }) = PresentationEditInput;
}

/// Describes one composed editor presentation and its input bindings.
///
/// The model owns presentation structure, type metadata, collection sources,
/// and diagnostics. It references, but does not own, [EditOwner] instances.
/// [value] creates a read only binding. [editor] creates a binding that routes
/// edits through the supplied owner at [path]. The presentation session consumes
/// this immutable model and owns any derived binding sources or lifecycle.
@freezed
abstract class PresentationModel with _$PresentationModel {
  const factory PresentationModel({
    required TypeCatalog catalog,
    required Map<BindingId, PresentationInput> inputs,
    required PresentationNode root,
    @Default({}) Map<EditOwner, String> ownerLabels,
    @Default([]) List<PresentationDefinition> presentations,
    @Default(PresentationCollections.empty())
    PresentationCollections collections,
    @Default([]) List<TypeDiagnostic> diagnostics,
  }) = _PresentationModel;

  const PresentationModel._();

  /// Builds a presentation rooted in one immutable value observation.
  factory PresentationModel.value({
    required TypeExpression type,
    required DataValue value,
    required TypeCatalog catalog,
    PresentationNode? presentation,
    List<PresentationDefinition> presentations = const [],
    List<PresentationCollectionSource> collections = const [],
    List<TypeDiagnostic> diagnostics = const [],
  }) => PresentationModel(
    catalog: catalog,
    inputs: {
      const BindingId(0): PresentationInput.value(
        type: type,
        value: EditorValue.ready(value),
      ),
    },
    root: presentation ?? _singlePresentationRoot(type, catalog, presentations),
    presentations: presentations,
    collections: PresentationCollections(collections),
    diagnostics: diagnostics,
  );

  /// Builds a presentation whose root binding delegates edits to [owner].
  factory PresentationModel.editor({
    required EditOwner owner,
    DataPath path = DataPath.root,
    PresentationNode? presentation,
    List<PresentationDefinition> presentations = const [],
    List<PresentationCollectionSource> collections = const [],
    List<TypeDiagnostic> diagnostics = const [],
  }) {
    return PresentationModel(
      catalog: owner.typeCatalog,
      inputs: {const BindingId(0): PresentationInput.edit(owner, path: path)},
      root:
          presentation ??
          _singlePresentationRoot(
            owner.rootType
                    .resolvePath(
                      path,
                      registry: TypeRegistry(owner.typeCatalog),
                    )
                    .valueOrNull ??
                owner.rootType,
            owner.typeCatalog,
            presentations,
          ),
      presentations: presentations,
      collections: PresentationCollections(collections),
      diagnostics: diagnostics,
    );
  }

  /// Declares root lexical access independently of current write availability.
  Map<BindingId, PresentationInputAccess> get inputAccess => {
    for (final entry in inputs.entries)
      entry.key: switch (entry.value) {
        PresentationValueInput() => PresentationInputAccess.read,
        PresentationEditInput() => PresentationInputAccess.edit,
      },
  };

  /// Identifies root transaction origins. Value inputs have no edit owner.
  Map<BindingId, BindingReference?> get ownerBindings => {
    for (final entry in inputs.entries)
      entry.key: switch (entry.value) {
        PresentationValueInput() => null,
        PresentationEditInput() => BindingReference(bindingId: entry.key),
      },
  };
}

PresentationNode _singlePresentationRoot(
  TypeExpression declared,
  TypeCatalog catalog,
  List<PresentationDefinition> presentations,
) {
  final registry = TypeRegistry(catalog);
  final resolved = declared is NamedType
      ? registry.resolve(declared).valueOrNull?.representation ?? declared
      : declared;
  final selected = declared is NamedType
      ? registry.definition(declared.reference)?.defaultPresentationId
      : null;
  final definition = presentations
      .where(
        (definition) =>
            definition.id == selected && definition.inputs.length == 1,
      )
      .firstOrNull;
  if (definition == null) {
    final generated =
        declared is NamedType &&
            registry.resolve(declared).valueOrNull?.isConcrete == false
        ? declared
        : resolved;
    return generated.generateDefaultPresentation(registry: registry);
  }
  return PresentationNode(
    id: "editor",
    element: PresentationInvocationElement(
      presentationId: definition.id,
      arguments: {
        definition.inputs.single.id: const BindingReference(
          bindingId: BindingId(0),
        ),
      },
    ),
  );
}
