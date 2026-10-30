import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  for (final value in [
    skir.DataValue.wrapStringValue("ga"),
    skir.DataValue.unfilled,
  ]) {
    test(
      value == skir.DataValue.unfilled
          ? "unfinished Tag name saves and survives authoritative refresh"
          : "Tag name outside service identifier rules saves and survives refresh",
      () async {
        final tag = Tag(
          tagId: skir.ResourceId(value: "tag:save_policy"),
          name: "Main Quest",
          color: Colors.blue,
          parentIds: const [],
          placement: GraphPlacement(x: 0, y: 0, width: 4, height: 1),
        );
        final world = testWorld([
          signedIn(ada, organization: acme),
          realm(tags: [tag]),
          heldSaves,
        ]);
        final realmDouble = world.requireRealm;
        final workspace = await world.openRealmEditing();
        final location = skir.ValueLocation(
          resource: tag.tagId,
          path: editorRootPath.field("name"),
        );
        final result = workspace.edit(
          label: "Edit Tag name",
          policy: EditorCommitPolicy.applyResource,
          apply: (edit) => edit.set(location, value),
        );
        expect(result, isA<EditStaged>());
        expect(
          (workspace.document.read(
            location,
          ) as PortablePathValue<skir.DataValue>).value,
          value,
        );
        expect(
          const RealmEditModel().validateCommit(workspace.document),
          isEmpty,
        );
        final saving = workspace.save((result as EditStaged).group);
        await Future<void>.delayed(Duration.zero);
        expect(realmDouble.saves, hasLength(1));
        realmDouble.saves.single.confirm();
        await saving;
        await workspace.refreshConfirmed();
        expect(workspace.hasPendingWork, isFalse);
        expect(
          (workspace.document.read(
            location,
          ) as PortablePathValue<skir.DataValue>).value,
          value,
        );
        expect(
          (realmDouble.document.read(
            location,
          ) as PortablePathValue<skir.DataValue>).value,
          value,
        );
      },
    );
  }
}
