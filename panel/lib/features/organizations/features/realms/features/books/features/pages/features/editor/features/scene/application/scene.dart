import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "scene.freezed.dart";

/// A decoded timeline element backed by a page authoring element.
///
/// Segments occupy an inclusive frame range and expose outward links for
/// nested cues. Keyframes occupy one frame and have no timeline children in
/// this projection. Both variants retain decoded value data and incoming
/// links for the inspector and surrounding editor views. Instances are read
/// model values; placement and value persistence remain with the page element
/// coordinator.
@freezed
abstract class Cue with _$Cue {
  @Assert("id != \"\"", "ID must not be empty.")
  @Assert("startFrame >= 0", "Start frame must not be negative.")
  @Assert("endFrame >= startFrame", "End frame must not precede start frame.")
  const factory Cue.segment({
    required String id,
    required int startFrame,
    required int endFrame,
    required ElementDefinition elementDefinition,
    required RecordValue data,
    required List<ElementLink> inwardLinks,
    required List<ElementLink> outwardLinks,
  }) = Segment;

  @Assert("id != \"\"", "ID must not be empty.")
  @Assert("frame >= 0", "Frame must not be negative.")
  const factory Cue.keyframe({
    required String id,
    required int frame,
    required ElementDefinition elementDefinition,
    required RecordValue data,
    required List<ElementLink> inwardLinks,
  }) = Keyframe;
}

/// Stable selection identity for a cue on a specific page.
///
/// The page is part of identity because element IDs are resolved in page
/// context here. Resolving this identifier reads the projected page, then
/// creates the same authoring target used by entry editing. The target carries
/// the projection revision so the shared editor can reconcile changes without
/// treating the scene projection as persistence authority.
class CueIdentifier extends SelectableIdentifier {
  const CueIdentifier({required this.pageId, required this.id});

  final String pageId;

  @override
  final String id;

  @override
  Object get resourceId => skir.ResourceId(value: id);

  /// Resolves the current projected cue into an editable inspector selection.
  ///
  /// Loading and catalog failures are returned as [AsyncValue] states. A cue
  /// absent from the selected page becomes [SelectableNotFoundException].
  /// Missing organization or realm context is a bad request rather than a
  /// lookup against an ambient default.
  @override
  AsyncValue<Selectable<CueIdentifier>> create(Ref ref) {
    final organizationId = ref.watch(organizationIdProvider);
    final realmId = ref.watch(realmIdProvider);
    if (organizationId == null || realmId == null) {
      return AsyncValue.error(
        ApiException.badRequest("No realm selected"),
        StackTrace.current,
      );
    }
    final state = ref.watch(authoringSessionProvider(organizationId, realmId));
    final repository = ref
        .watch(resourceRepositoriesProvider)
        .authoring(organizationId, realmId);
    final asyncElements = ref.watch(
      projectedPageElementValuesProvider(organizationId, realmId, pageId),
    );

    if (asyncElements.mapUnready<Selectable<CueIdentifier>>()
        case final value?) {
      return value;
    }
    final indexed = asyncElements.requireValue;
    final elements = indexed.value;

    Cue? cue;
    for (final element in elements) {
      if (element case PageElementCue(cue: final candidate)
          when candidate.id == id) {
        cue = candidate;
        break;
      }
    }

    if (cue == null) {
      return AsyncError(SelectableNotFoundException(this), StackTrace.current);
    }

    final resolvedCue = cue;
    final catalogState = ref.watch(
      realmEditorCatalogForTypeProvider(resolvedCue.elementDefinition.rootType),
    );
    return catalogState.resolveElement(
      resolvedCue.elementDefinition,
      (catalog, presentations) => CueSelection(
        target: state.authoringResourceTarget(
          repository: repository,
          identity: this,
          label: resolvedCue.elementDefinition.name,
          typeCatalog: catalog,
        ),
        id: this,
        cue: resolvedCue,
        typeCatalog: catalog,
        presentations: presentations,
      ),
    );
  }

  @override
  int get hashCode => Object.hash(pageId, id);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is CueIdentifier && other.pageId == pageId && other.id == id);
  }

  @override
  String toString() => "CueIdentifier($pageId, $id)";
}

/// Selection adapter that exposes a cue through the shared editor pipeline.
///
/// [target] owns the mutation route and editor snapshot. This adapter supplies
/// the cue identity, catalog, presentation choices, and inspector header; it
/// does not copy or independently persist cue data.
class CueSelection extends EditableSelectable<CueIdentifier> {
  const CueSelection({
    required this.target,
    required this.id,
    required this.cue,
    required this.typeCatalog,
    required this.presentations,
  });

  final EditorTarget target;

  @override
  final CueIdentifier id;

  final Cue cue;

  @override
  final TypeCatalog typeCatalog;
  @override
  final List<PresentationDefinition> presentations;

  @override
  String get name => cue.elementDefinition.name;

  @override
  EditorDocument get document => target.document;

  @override
  DataPath get presentationPath => elementValuePath;

  @override
  ResolvedTypeRef get rootType => cue.elementDefinition.rootType;

  @override
  List<SelectionCapability> get capabilities => const [];

  @override
  Widget? buildInspectorHeader(EditOwner owner) {
    return CueHeader(id: id.id, name: name, color: cue.elementDefinition.color);
  }

  @override
  EditableResource get resource => target.resource;
  @override
  EditorSnapshot get snapshot => target.snapshot;

  @override
  String toString() => "CueSelection($id)";
}

/// Compact inspector header showing a cue name, identifier, and color.
class CueHeader extends StatelessWidget {
  const CueHeader({
    required this.id,
    required this.name,
    required this.color,
    super.key,
  });

  final String id;
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: textTheme.headlineSmall),
              Text(id, style: textTheme.bodyMedium),
            ],
          ),
        ),
        CircleAvatar(backgroundColor: color, radius: 12),
      ],
    );
  }
}
