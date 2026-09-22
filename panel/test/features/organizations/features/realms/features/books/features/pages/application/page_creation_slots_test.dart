import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("graph slot accepts only its published concrete roots", () {
    final root = _type("GraphEntry");
    final other = _type("OtherEntry");
    final slot = _slot("page/test/1/graph", [root]);

    expect(slot.pagePlacement, RealmPageCreationPlacement.graph);
    expect(slot.acceptsRoot(root), isTrue);
    expect(slot.acceptsRoot(other), isFalse);
  });

  test("timeline slot exposes timeline placement through slot metadata", () {
    final slot = _slot("page/test/1/timeline", [_type("Track")]);

    expect(slot.pagePlacement, RealmPageCreationPlacement.timelineTrack);
  });
}

RealmAuthoringCreationSlot _slot(
  String id,
  List<ResolvedTypeRef> concreteRoots,
) => RealmAuthoringCreationSlot(
  id: AuthoringCreationSlotId(id),
  label: "Test slot",
  creates: CoreResourceDefinitionIds.element,
  context: const RealmStandaloneCreationContext(),
  concreteRoots: concreteRoots,
);

ResolvedTypeRef _type(String name) => ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "test", name: name),
  revision: 1,
);
