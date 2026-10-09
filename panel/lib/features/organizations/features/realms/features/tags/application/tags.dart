import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "tags.freezed.dart";
part "tags.g.dart";
part "tag_model.dart";

const tagGraphCellSize = 50.0;

/// Typed tag views of the shared working document.
@riverpod
AsyncValue<List<Tag>> workingTags(Ref ref) {
  final source = ref.watch(selectedWorkingAuthoringDocumentProvider);
  if (source.mapUnready<List<Tag>>() case final pending?) return pending;
  return AsyncData(
    source.requireValue.entries.values
        .where((entry) => entry.definition == coreTagResourceDefinition)
        .map(Tag.fromAuthoring)
        .toList(growable: false),
  );
}

@riverpod
AsyncValue<Tag?> workingTag(Ref ref, skir.ResourceId tagId) {
  final source = ref.watch(workingTagsProvider);
  if (source.mapUnready<Tag?>() case final pending?) return pending;
  return AsyncData(
    source.requireValue.firstWhereOrNull((tag) => tag.tagId == tagId),
  );
}
