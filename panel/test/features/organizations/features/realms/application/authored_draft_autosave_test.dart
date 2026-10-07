import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test(
    "a failed refresh does not turn a known rejection into an uncertain save",
    () async {
      var requests = 0;
      final autosave = AuthoredDraftAutosave(
        resource: _resource,
        baseline: _draft("Quest"),
        policy: EditorCommitPolicy.applyResource,
        commit: (_) async {
          requests++;
          return skir.CommitPreparedEditResponse.wrapResult(
            skir.CommitResult.wrapConflict(const []),
          );
        },
        fetchCurrent: () async => throw StateError("Unavailable"),
        reload: () async => throw StateError("Unavailable"),
        onSettled: () {},
      );
      try {
        autosave.stage(
          autosave.draft.fork()
            ..set(_title, skir.DataValue.wrapStringValue("Story")),
        );
        await autosave.flush();
        expect(autosave.status, contains("changed before this edit was saved"));
        expect(autosave.status, isNot(contains("unknown")));
        expect(autosave.canRetry, isFalse);
        await autosave.retry();
        expect(requests, 1);
        expect(autosave.dirty, isTrue);
      } finally {
        autosave.close();
      }
    },
  );

  test("a later current state fetch recovers a confirmed prefix and retains the edit tail", () async {
    final committed = Completer<skir.CommitPreparedEditResponse>();
    var requests = 0;
    final autosave = AuthoredDraftAutosave(
      resource: _resource,
      baseline: _draft("Quest"),
      policy: EditorCommitPolicy.applyResource,
      commit: (_) {
        requests++;
        return committed.future;
      },
      fetchCurrent: () async => throw StateError("Unavailable"),
      reload: () async {},
      onSettled: () {},
    );
    try {
      autosave.stage(
        autosave.draft.fork()
          ..set(_title, skir.DataValue.wrapStringValue("Story")),
      );
      final saving = autosave.flush();
      autosave.stage(
        autosave.draft.fork()
          ..set(_title, skir.DataValue.wrapStringValue("Saga")),
      );
      committed.complete(
        skir.CommitPreparedEditResponse.wrapResult(skir.CommitResult.committed),
      );
      await saving;
      expect(autosave.status, contains("edit was saved"));
      expect(autosave.blocked, isTrue);
      autosave.acceptBaseline(_draft("Story"));
      expect(autosave.blocked, isFalse);
      expect(autosave.draft.intents, hasLength(1));
      expect(
        autosave.draft.resource(_resource)?.fields.single.value,
        skir.DataValue.wrapStringValue("Saga"),
      );
      final expected = autosave.draft.expectations
          .whereType<skir.EditExpectation_valueWrapper>()
          .single;
      expect(expected.value.expected, skir.DataValue.wrapStringValue("Story"));
      expect(requests, 1);
    } finally {
      autosave.close();
    }
  });
}

final _resource = skir.ResourceId(value: "resource:quest");
final _title = skir.ValueLocation(
  resource: _resource,
  path: skir.ValuePath(segments: [skir.PathSegment.createField(name: "title")]),
);
AuthoredDraft _draft(String title) => AuthoredDraft(
  generation: skir.CatalogGeneration(value: "catalog"),
  resources: [
    skir.AuthoringResource(
      id: _resource,
      definition: skir.ResourceDefinitionId(value: "quest"),
      content: skir.AuthoringRecord(
        configuration: skir.TypeSelection.wrapComplete(
          skir.NamedTypeUse(
            definition: skir.TypeDefinitionId(
              typeId: skir.TypeId.createQualified(
                namespace: "test",
                name: "quest",
              ),
              revision: 1,
            ),
            arguments: const [],
          ),
        ),
        fields: [
          skir.FieldValue(
            name: "title",
            value: skir.DataValue.wrapStringValue(title),
          ),
        ],
      ),
    ),
  ],
  links: const [],
);
