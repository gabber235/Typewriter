import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("definition updates refresh the existing source", () async {
    final definitions = ValueNotifier<AsyncValue<List<ElementDefinition>>>(
      const AsyncLoading(),
    );
    addTearDown(definitions.dispose);
    final source = ElementTypeSearchSource(definitions: definitions);
    final controller = SourceController(
      source: source,
      baseSelectors: const [],
    );
    addTearDown(controller.dispose);
    await pumpEventQueue();

    expect(controller.snapshot.status, SearchSourceStatus.loading);

    definitions.value = AsyncData([_definition]);
    await pumpEventQueue();

    expect(controller.snapshot.status, SearchSourceStatus.ready);
    expect(controller.snapshot.nodes, hasLength(1));
  });

  test("query updates filter the existing source", () async {
    final definitions = ValueNotifier<AsyncValue<List<ElementDefinition>>>(
      AsyncData([_definition]),
    );
    addTearDown(definitions.dispose);
    final controller = SourceController(
      source: ElementTypeSearchSource(definitions: definitions),
      baseSelectors: const [],
    );
    addTearDown(controller.dispose);
    await pumpEventQueue();

    expect(controller.snapshot.nodes, hasLength(1));

    controller.updateQuery("missing");
    await pumpEventQueue();

    expect(controller.snapshot.nodes, isEmpty);
  });
}

final _definition = ElementDefinition(
  rootType: _rootType,
  name: "Example",
  description: "Typed entry",
  color: Colors.blue,
  icon: const IconValue.iconify("fa-solid:star"),
);

final _rootType = ResolvedTypeRef(
  id: DeclaredTypeId("0123456789abcdef0123456789abcdef"),
  revision: 1,
);
