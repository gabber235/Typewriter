import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

final _name = editorRootPath.field("name");
final _tags = editorRootPath.field("tags");
final _steps = editorRootPath.field("steps");

void main() {
  final gate = recordEditorValue({
    "name": textValue("Gate"),
    "tags": textSet(["a", "b"]),
    "steps": textList(["open", "close"]),
  });

  test("the remote value becomes the base at the remote revision", () {
    final remote = recordWithFields(gate, {"name": textValue("Remote")});

    final result = const EditorReconciler().reconcile(
      base: gate,
      local: recordWithFields(gate, {"name": textValue("Local")}),
      remote: remote,
      remoteRevision: 2,
      dirtyPaths: {_name},
      mergePolicies: {_tags: EditorMergePolicy.set},
    );

    expect(result.base, remote);
    expect(result.revision, 2);
  });

  test("a local edit survives a remote change elsewhere and stays dirty", () {
    final result = const EditorReconciler().reconcile(
      base: gate,
      local: recordWithFields(gate, {"name": textValue("Local")}),
      remote: recordWithFields(gate, {
        "steps": textList(["open", "close", "lock"]),
      }),
      remoteRevision: 2,
      dirtyPaths: {_name},
      mergePolicies: {_tags: EditorMergePolicy.set},
    );

    expect(
      result.draft,
      recordWithFields(gate, {
        "name": textValue("Local"),
        "steps": textList(["open", "close", "lock"]),
      }),
    );
    expect(result.dirtyPaths, {_name});
    expect(result.confirmedPaths, isEmpty);
    expect(result.conflicts, isEmpty);
  });

  test("a remote value equal to the local edit confirms it", () {
    final result = const EditorReconciler().reconcile(
      base: gate,
      local: recordWithFields(gate, {"name": textValue("Same")}),
      remote: recordWithFields(gate, {"name": textValue("Same")}),
      remoteRevision: 2,
      dirtyPaths: {_name},
      mergePolicies: {_tags: EditorMergePolicy.set},
    );

    expect(result.draft, recordWithFields(gate, {"name": textValue("Same")}));
    expect(result.confirmedPaths, {_name});
    expect(result.dirtyPaths, isEmpty);
    expect(result.conflicts, isEmpty);
  });

  final conflicting = {
    "an atomic value": (
      path: _name,
      local: recordWithFields(gate, {"name": textValue("Local")}),
      remote: recordWithFields(gate, {"name": textValue("Remote")}),
    ),
    "an ordered list": (
      path: _steps,
      local: recordWithFields(gate, {
        "steps": textList(["close", "open"]),
      }),
      remote: recordWithFields(gate, {
        "steps": textList(["open", "close", "lock"]),
      }),
    ),
  };
  for (final MapEntry(key: kind, value: change) in conflicting.entries) {
    test("both sides changing $kind keeps the local value as a conflict", () {
      final result = const EditorReconciler().reconcile(
        base: gate,
        local: change.local,
        remote: change.remote,
        remoteRevision: 2,
        dirtyPaths: {change.path},
        mergePolicies: {_tags: EditorMergePolicy.set},
      );

      final local = change.local.editorValueAt(change.path)!;
      final remote = change.remote.editorValueAt(change.path)!;
      expect(result.draft.editorValueAt(change.path), local);
      expect(result.dirtyPaths, {change.path});
      expect(result.conflicts, {
        change.path: EditorPathConflict(
          base: gate.editorValueAt(change.path)!,
          local: local,
          remote: remote,
        ),
      });
    });
  }

  final memberships = {
    "a local addition and a remote removal both apply": (
      local: ["a", "b", "c"],
      remote: ["a"],
      merged: ["a", "c"],
    ),
    "a local removal and a remote addition both apply": (
      local: ["a"],
      remote: ["a", "b", "d"],
      merged: ["a", "d"],
    ),
  };
  for (final MapEntry(key: name, value: sets) in memberships.entries) {
    test("set membership merges: $name", () {
      final result = const EditorReconciler().reconcile(
        base: gate,
        local: recordWithFields(gate, {"tags": textSet(sets.local)}),
        remote: recordWithFields(gate, {"tags": textSet(sets.remote)}),
        remoteRevision: 2,
        dirtyPaths: {_tags},
        mergePolicies: {_tags: EditorMergePolicy.set},
      );

      final merged = result.draft.editorValueAt(_tags)!.authoredItems!;
      expect(
        [for (final item in merged) item.value],
        [for (final value in sets.merged) textValue(value)],
      );
      expect(result.dirtyPaths, {_tags});
      expect(result.conflicts, isEmpty);
    });
  }

  test("a path the remote value no longer has becomes a diagnostic", () {
    final remote = recordEditorValue({"name": textValue("Gate")});

    final result = const EditorReconciler().reconcile(
      base: gate,
      local: recordWithFields(gate, {
        "tags": textSet(["a"]),
      }),
      remote: remote,
      remoteRevision: 2,
      dirtyPaths: {_tags},
      mergePolicies: {_tags: EditorMergePolicy.set},
    );

    expect(result.draft, remote);
    expect(result.dirtyPaths, isEmpty);
    expect(result.conflicts, isEmpty);
    expect(result.diagnostics, hasLength(1));
    expect(result.diagnostics.single.code, EditorDiagnosticCode.invalidPath);
    expect(result.diagnostics.single.path, _tags);
  });
}
