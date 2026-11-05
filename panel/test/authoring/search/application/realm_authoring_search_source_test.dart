import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  test("an empty query issues one Realm search and becomes ready", () async {
    final (:controller, :requests) = await startedEmptyRealmSearch();

    expect(controller.snapshot.status, SearchSourceStatus.ready);
    expect(requests.map((request) => request.query), [""]);
  });

  test(
    "a changed query issues exactly one fresh Realm search for it",
    () async {
      final (:controller, :requests) = await startedEmptyRealmSearch();

      controller.updateQuery("example");
      await pumpEventQueue();

      expect(requests.map((request) => request.query), ["", "example"]);
      expect(controller.snapshot.status, SearchSourceStatus.ready);
    },
  );

  test(
    "remote membership keeps working labels and hides local deletions",
    () async {
      final hit = tag("Saved name");
      final id = hit.tagId;
      final created = skir.ResourceId(value: "tag:new");
      final context = skir.PortableValue(
        actualType: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
        payload: skir.DataValue.wrapStringValue("confirmed command context"),
      );
      final world = testWorld([
        signedIn(ada, organization: acme),
        realm(tags: [hit]),
      ]);
      final seeded = world.requireRealm;
      final document = seeded.document;
      seeded.answerSearch = (_) async =>
          skir.SearchAuthoringResponse.createSuccess(
            generation: document.generation,
            hits: [
              skir.AuthoringSearchHit(
                resource: id,
                subject: skir.PresentationSubject(
                  resource: id,
                  content: document.resource(id)!,
                ),
                context: context,
              ),
            ],
            diagnostics: const [],
          );
      final workspace = await world.openRealmEditing();
      final controller = world.realmSearch();
      await pumpEventQueue();
      workspace
          .form(id)
          .setText(
            "Rename hit",
            authoredFieldLocation(id, ["name"]),
            "Working name",
          );
      await pumpEventQueue();
      final result =
          (controller.snapshot.nodes.single as SearchResultNode).result;
      expect(result.title, "Working name");
      expect((result.payload as AuthoringSearchResultPayload).context, context);

      workspace.edit(
        label: "Create unrelated tag",
        policy: EditorCommitPolicy.applyResource,
        apply: (edit) => edit.create(created, document.resource(id)!),
      );
      await pumpEventQueue();
      expect(controller.snapshot.nodes, hasLength(1));

      seeded.holdSaves = true;
      workspace.edit(
        label: "Delete hit",
        policy: EditorCommitPolicy.applyResource,
        apply: (edit) => edit.delete(id),
      );
      await pumpEventQueue();
      expect(controller.snapshot.nodes, isEmpty);
      // The deletion is still local work; the Realm still holds the hit.
      expect(seeded.document.entry(id), isNotNull);
    },
  );
}
