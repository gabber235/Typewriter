import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/application/element_blueprint.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/application/page_elements.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/application/selectable.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/domain/data_blueprint.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/domain/dynamic_data.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/domain/selection.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/operations.dart";

part "scene.freezed.dart";
part "scene.g.dart";

@freezed
abstract class Cue with _$Cue {
  @Assert("id != \"\"", "ID must not be empty.")
  @Assert("startFrame >= 0", "Start frame must not be negative.")
  @Assert("endFrame >= startFrame", "End frame must not precede start frame.")
  const factory Cue.segment({
    required String id,
    required int startFrame,
    required int endFrame,
    required ElementBlueprint blueprint,
    required DynamicData data,
    required List<ElementLink> inwardLinks,
    required List<ElementLink> outwardLinks,
  }) = Segment;

  @Assert("id != \"\"", "ID must not be empty.")
  @Assert("frame >= 0", "Frame must not be negative.")
  const factory Cue.keyframe({
    required String id,
    required int frame,
    required ElementBlueprint blueprint,
    required DynamicData data,
    required List<ElementLink> inwardLinks,
  }) = Keyframe;

  factory Cue.fromJson(Map<String, dynamic> json) => _$CueFromJson(json);
}

class CueIdentifier extends SelectableIdentifier {
  const CueIdentifier({required this.pageId, required this.id});

  final String pageId;

  @override
  final String id;

  @override
  AsyncValue<Selectable<CueIdentifier>> create(Ref ref) {
    final asyncElements = ref.watch(pageElementsProvider(pageId));
    return asyncElements.whenData((elements) {
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

      return CueSelection(ref: ref, id: this, cue: cue);
    });
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

class CueSelection extends Selectable<CueIdentifier> {
  const CueSelection({required this.ref, required this.id, required this.cue});

  final Ref ref;

  @override
  final CueIdentifier id;

  final Cue cue;

  @override
  String get name => cue.blueprint.name;

  @override
  ObjectBlueprint get objectBlueprint => cue.blueprint.dataBlueprint;

  @override
  List<SelectableOperation> get operations => const [];

  @override
  Widget? header() {
    return CueHeader(id: id.id, name: name, color: cue.blueprint.color);
  }

  @override
  dynamic fieldValue(String path) => cue.data.get(path);

  @override
  void setFieldValue(String path, dynamic value) {
    ref
        .read(pageElementsProvider(id.pageId).notifier)
        .updateCueFieldValue(id.id, path, value);
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
