import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

extension TagCommands on AuthoringSession {
  Future<skir.ApplyAuthoringBatchResponse> deleteTag(skir.ResourceId id) =>
      apply([skir.AuthoringOperation.createDelete(id: id)]);
}
