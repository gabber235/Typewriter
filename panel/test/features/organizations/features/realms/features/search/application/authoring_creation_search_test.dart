import "package:flutter/foundation.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("creation option identity includes concrete type arguments", () {
    final first = AuthoringCreationOption(
      slot: _standalone,
      root: _root.copyWith(arguments: const [StringType()]),
    );
    final second = AuthoringCreationOption(
      slot: _standalone,
      root: _root.copyWith(arguments: const [BooleanType()]),
    );

    expect(first.id, isNot(second.id));
  });

  test("all creation slots appear without resource family code", () async {
    final catalog = ValueNotifier<AsyncValue<RealmEditorCatalogState>>(
      AsyncData(
        RealmEditorCatalogState.ready(
          RealmEditorCatalogSnapshot(
            catalog: const TypeCatalog([]),
            generation: const CatalogGeneration("1"),
            creationSlots: {_standalone.id: _standalone, _hosted.id: _hosted},
          ),
        ),
      ),
    );
    addTearDown(catalog.dispose);
    final controller = SourceController(
      source: AuthoringCreationSearchSource(catalog),
      baseSelectors: const [],
    );
    addTearDown(controller.dispose);
    await pumpEventQueue();

    expect(controller.snapshot.status, SearchSourceStatus.ready);
    final section = controller.snapshot.nodes.single as SearchSectionNode;
    expect(section.children, hasLength(2));

    controller.updateQuery("missing");
    await pumpEventQueue();

    expect(controller.snapshot.nodes, isEmpty);
  });

  test("hosted creation slots appear for compatible catalog hosts", () async {
    final catalog = ValueNotifier<AsyncValue<RealmEditorCatalogState>>(
      AsyncData(
        RealmEditorCatalogState.ready(
          RealmEditorCatalogSnapshot(
            catalog: const TypeCatalog([]),
            generation: const CatalogGeneration("1"),
            creationSlots: {_standalone.id: _standalone, _hosted.id: _hosted},
          ),
        ),
      ),
    );
    addTearDown(catalog.dispose);
    final controller = SourceController(
      source: AuthoringCreationSearchSource(
        catalog,
        hosts: [
          AuthoringCreationHost(
            id: skir.ResourceId(value: "host"),
            definition: _definition,
            root: _root,
          ),
        ],
      ),
      baseSelectors: const [],
    );
    addTearDown(controller.dispose);
    await pumpEventQueue();

    final section = controller.snapshot.nodes.single as SearchSectionNode;
    final result = (section.children.single as SearchResultNode).result;
    final option = result.payload as AuthoringCreationOption;
    expect(option.slot, _hosted);
    expect(option.hosts, [skir.ResourceId(value: "host")]);
  });
}

final _root = ResolvedTypeRef(
  id: DeclaredTypeId("0123456789abcdef0123456789abcdef"),
  revision: 1,
);
const _definition = ResourceDefinitionId("example.document");
final _standalone = RealmAuthoringCreationSlot(
  id: const AuthoringCreationSlotId("example.document.create"),
  label: "Document",
  creates: _definition,
  context: const RealmAuthoringCreationContext.standalone(),
  concreteRoots: [_root],
);
final _hosted = RealmAuthoringCreationSlot(
  id: const AuthoringCreationSlotId("example.document.child.create"),
  label: "Document Child",
  creates: _definition,
  context: const RealmAuthoringCreationContext.declaredRelation(
    hosts: RealmCreationHostFilter(definitions: {_definition}),
    cardinality: RealmCreationHostCardinality.exactlyOne,
    relation: "example.document.children",
    direction: RealmCreationRelationDirection.outgoing,
  ),
  concreteRoots: [_root],
);
