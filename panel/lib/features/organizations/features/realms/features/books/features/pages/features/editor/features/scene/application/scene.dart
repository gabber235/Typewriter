import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "scene.freezed.dart";

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
    @Default(1) int revision,
  }) = Segment;

  @Assert("id != \"\"", "ID must not be empty.")
  @Assert("frame >= 0", "Frame must not be negative.")
  const factory Cue.keyframe({
    required String id,
    required int frame,
    required ElementDefinition elementDefinition,
    required RecordValue data,
    required List<ElementLink> inwardLinks,
    @Default(1) int revision,
  }) = Keyframe;
}

class CueIdentifier extends SelectableIdentifier {
  const CueIdentifier({required this.pageId, required this.id});

  final String pageId;

  @override
  final String id;

  @override
  AsyncValue<Selectable<CueIdentifier>> create(Ref ref) {
    final asyncElements = ref.watch(pageElementsProvider(pageId));
    return asyncElements.when(
      data: (elements) {
        Cue? cue;
        for (final element in elements) {
          if (element case PageElementCue(
            cue: final candidate,
          ) when candidate.id == id) {
            cue = candidate;
            break;
          }
        }

        if (cue == null) {
          throw SelectableNotFoundException(this);
        }

        final catalogState = ref.watch(
          realmEditorCatalogForTypeProvider(cue.elementDefinition.rootType),
        );
        return catalogState.resolveElement(
          cue.elementDefinition,
          (catalog, presentations) => CueSelection(
            ref: ref,
            id: this,
            cue: cue!,
            typeCatalog: catalog,
            presentations: presentations,
          ),
        );
      },
      error: AsyncValue.error,
      loading: AsyncValue.loading,
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

class CueSelection extends InspectableSelectable<CueIdentifier> {
  const CueSelection({
    required this.ref,
    required this.id,
    required this.cue,
    required this.typeCatalog,
    required this.presentations,
  });

  final Ref ref;

  @override
  final CueIdentifier id;

  final Cue cue;

  @override
  final TypeCatalog typeCatalog;
  final List<PresentationDefinition> presentations;

  @override
  String get name => cue.elementDefinition.name;

  @override
  EditorDocument get document => EditorDocument(
    rootType: NamedType(cue.elementDefinition.rootType),
    typeCatalog: typeCatalog,
    presentations: presentations,
    confirmedValue: cue.data,
    revision: cue.revision,
  );

  @override
  List<SelectionCapability> get capabilities => const [];

  @override
  Widget? buildInspectorHeader() {
    return CueHeader(id: id.id, name: name, color: cue.elementDefinition.color);
  }

  @override
  Future<TypedMutationResult> commit(EditorCommit commit) async {
    return ref
        .read(pageElementsProvider(id.pageId).notifier)
        .commitElementValue(id.id, commit);
  }

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) {
    return identical(this, other) || (other is CueSelection && other.id == id);
  }

  @override
  String toString() => "CueSelection($id)";
}

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
