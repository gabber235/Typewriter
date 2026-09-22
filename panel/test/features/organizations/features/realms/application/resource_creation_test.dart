import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("reference path creation binds a host without a caller partial", () {
    final host = skir.ResourceId(value: "host");
    final slot = RealmAuthoringCreationSlot(
      id: const AuthoringCreationSlotId("example.page.create"),
      label: "Page",
      creates: const ResourceDefinitionId("example.page"),
      context: RealmAuthoringCreationContext.referencePath(
        hosts: const RealmCreationHostFilter(),
        cardinality: RealmCreationHostCardinality.exactlyOne,
        path: DataPath.root.field("owner"),
      ),
      concreteRoots: [
        ResolvedTypeRef(
          id: DeclaredTypeId("0123456789abcdef0123456789abcdef"),
          revision: 1,
        ),
      ],
    );

    expect(
      slot.bindHostReferences(null, [host]),
      RecordValue({"owner": ReferenceValue(host)}),
    );
  });

  test("reference path creation binds a host inside initialized structure", () {
    final host = skir.ResourceId(value: "host");
    final slot = RealmAuthoringCreationSlot(
      id: const AuthoringCreationSlotId("example.page.create"),
      label: "Page",
      creates: const ResourceDefinitionId("example.page"),
      context: RealmAuthoringCreationContext.referencePath(
        hosts: const RealmCreationHostFilter(),
        cardinality: RealmCreationHostCardinality.exactlyOne,
        path: DataPath.root.field("metadata").field("owner"),
      ),
      concreteRoots: [
        ResolvedTypeRef(
          id: DeclaredTypeId("0123456789abcdef0123456789abcdef"),
          revision: 1,
        ),
      ],
    );

    expect(
      slot.bindHostReferences(RecordValue({"metadata": RecordValue({})}), [
        host,
      ]),
      RecordValue({
        "metadata": RecordValue({"owner": ReferenceValue(host)}),
      }),
    );
  });
}
