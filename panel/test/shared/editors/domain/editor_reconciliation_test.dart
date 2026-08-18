import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  const reconciler = EditorReconciler();
  final title = DataPath.root.field("title");
  final tags = DataPath.root.field("tags");

  test("rebases local and remote changes on different fields", () {
    final result = reconciler.reconcile(
      base: _record(title: "Old", color: "Red"),
      local: _record(title: "New", color: "Red"),
      remote: _record(title: "Old", color: "Blue"),
      remoteRevision: 5,
      dirtyPaths: {title},
      mergePolicies: const {},
    );

    expect(result.draft, _record(title: "New", color: "Blue"));
    expect(result.dirtyPaths, {title});
    expect(result.conflicts, isEmpty);
  });

  test("conflicts when both editors change the same atomic field", () {
    final result = reconciler.reconcile(
      base: _record(title: "Old", color: "Red"),
      local: _record(title: "Yours", color: "Red"),
      remote: _record(title: "Theirs", color: "Red"),
      remoteRevision: 5,
      dirtyPaths: {title},
      mergePolicies: const {},
    );

    expect(result.draft, _record(title: "Yours", color: "Red"));
    expect(result.conflicts[title]?.remote, const StringValue("Theirs"));
  });

  test("matching remote values confirm local changes", () {
    final result = reconciler.reconcile(
      base: _record(title: "Old", color: "Red"),
      local: _record(title: "New", color: "Red"),
      remote: _record(title: "New", color: "Red"),
      remoteRevision: 5,
      dirtyPaths: {title},
      mergePolicies: const {},
    );

    expect(result.dirtyPaths, isEmpty);
    expect(result.confirmedPaths, {title});
  });

  test("merges configured list fields as ordered sets", () {
    final result = reconciler.reconcile(
      base: _tagRecord(["Story"]),
      local: _tagRecord(["Story", "Combat"]),
      remote: _tagRecord(["Story", "Quest"]),
      remoteRevision: 5,
      dirtyPaths: {tags},
      mergePolicies: {tags: EditorMergePolicy.set},
    );

    expect(
      tags.read(result.draft).valueOrNull,
      const ListValue([
        StringValue("Story"),
        StringValue("Combat"),
        StringValue("Quest"),
      ]),
    );
    expect(result.conflicts, isEmpty);
  });

  test("recursively reconciles nested records", () {
    final details = DataPath.root.field("details");
    final base = RecordValue({
      "details": RecordValue({
        "title": const StringValue("Old"),
        "color": const StringValue("Red"),
      }),
    });
    final local = RecordValue({
      "details": RecordValue({
        "title": const StringValue("New"),
        "color": const StringValue("Red"),
      }),
    });
    final remote = RecordValue({
      "details": RecordValue({
        "title": const StringValue("Old"),
        "color": const StringValue("Blue"),
      }),
    });

    final result = reconciler.reconcile(
      base: base,
      local: local,
      remote: remote,
      remoteRevision: 2,
      dirtyPaths: {details},
      mergePolicies: const {},
    );

    expect(
      result.draft,
      RecordValue({
        "details": RecordValue({
          "title": const StringValue("New"),
          "color": const StringValue("Blue"),
        }),
      }),
    );
    expect(result.conflicts, isEmpty);
  });
}

RecordValue _record({required String title, required String color}) =>
    RecordValue({"title": StringValue(title), "color": StringValue(color)});

RecordValue _tagRecord(List<String> tags) =>
    RecordValue({"tags": ListValue(tags.map(StringValue.new).toList())});
