import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

const abstract = ResolvedTypeRef(
  id: TypeId.qualified(namespace: "selection", name: "Icon"),
  revision: 1,
);
const iconify = ResolvedTypeRef(
  id: TypeId.qualified(namespace: "selection", name: "Iconify"),
  revision: 1,
);
const svg = ResolvedTypeRef(
  id: TypeId.qualified(namespace: "selection", name: "Svg"),
  revision: 1,
);

final catalog = TypeCatalog(const [
  TypeDefinition(id: abstract, kind: NominalTypeKind.openAbstract),
  TypeDefinition(
    id: iconify,
    kind: NominalTypeKind.concrete,
    parents: [abstract],
    representation: RecordType(
      fields: {"value": TypeField(name: "value", type: StringType())},
    ),
  ),
  TypeDefinition(
    id: svg,
    kind: NominalTypeKind.concrete,
    parents: [abstract],
    representation: RecordType(
      fields: {"source": TypeField(name: "source", type: StringType())},
    ),
  ),
]);

final initial = PolymorphicValue(
  concreteType: iconify,
  value: RecordValue({"value": const StringValue("mdi:old")}),
);

ConcreteTypeInitialized initialized(ResolvedTypeRef type, String value) =>
    ConcreteTypeInitialized(
      TypedValueEnvelope(
        rootType: type,
        rootValue: RecordValue({
          type == svg ? "source" : "value": StringValue(value),
        }),
      ),
    );

void main() {
  test(
    "creation draft discards old fields and initializes each new type",
    () async {
      final draft = CreationDraft.fromMaterialized(
        rootType: const NamedType(abstract),
        value: initial,
        registry: TypeRegistry(catalog),
        concreteTypeInitializer: ({required type, required supplied}) async {
          expect(supplied, isNull);
          return initialized(type, type == svg ? "<svg/>" : "mdi:fresh");
        },
      );
      addTearDown(draft.dispose);

      expect(
        await draft.selectConcreteTypeAsync(DataPath.root, svg),
        isA<AppliedEditorMutation>(),
      );
      expect(
        await draft.selectConcreteTypeAsync(DataPath.root, iconify),
        isA<AppliedEditorMutation>(),
      );
      expect(
        draft.finalize().valueOrNull,
        PolymorphicValue(
          concreteType: iconify,
          value: RecordValue({"value": const StringValue("mdi:fresh")}),
        ),
      );
    },
  );

  test(
    "local editor discards old fields and preserves a same-type selection",
    () async {
      var calls = 0;
      final editor = LocalEditor(
        rootType: const NamedType(abstract),
        typeCatalog: catalog,
        value: initial,
        concreteTypeInitializer: ({required type, required supplied}) async {
          expect(supplied, isNull);
          calls++;
          return initialized(type, "<svg/>");
        },
      );
      addTearDown(editor.dispose);

      expect(
        await editor.selectConcreteTypeAsync(DataPath.root, iconify),
        isA<AppliedEditorMutation>(),
      );
      expect(calls, 0);
      expect(editor.value(DataPath.root).valueOrNull, initial);
      expect(
        await editor.selectConcreteTypeAsync(DataPath.root, svg),
        isA<AppliedEditorMutation>(),
      );
      expect(
        editor.value(DataPath.root).valueOrNull,
        PolymorphicValue(
          concreteType: svg,
          value: RecordValue({"source": const StringValue("<svg/>")}),
        ),
      );
    },
  );

  test(
    "later local selection supersedes an earlier initializer response",
    () async {
      final first = Completer<ConcreteTypeInitializationResult>();
      final editor = LocalEditor(
        rootType: const NamedType(abstract),
        typeCatalog: catalog,
        value: initial,
        concreteTypeInitializer: ({required type, required supplied}) =>
            type == svg
            ? first.future
            : Future.value(initialized(type, "mdi:new")),
      );
      addTearDown(editor.dispose);

      final older = editor.selectConcreteTypeAsync(DataPath.root, svg);
      final newer = editor.selectConcreteTypeAsync(DataPath.root, iconify);
      expect(await newer, isA<AppliedEditorMutation>());
      first.complete(initialized(svg, "<svg/>"));
      expect(await older, isA<ConflictingEditorMutation>());
      expect(editor.value(DataPath.root).valueOrNull, initial);
    },
  );

  test(
    "later draft selection supersedes an earlier initializer response",
    () async {
      final first = Completer<ConcreteTypeInitializationResult>();
      final draft = CreationDraft.fromMaterialized(
        rootType: const NamedType(abstract),
        value: initial,
        registry: TypeRegistry(catalog),
        concreteTypeInitializer: ({required type, required supplied}) =>
            type == svg
            ? first.future
            : Future.value(initialized(type, "mdi:new")),
      );
      addTearDown(draft.dispose);

      final older = draft.selectConcreteTypeAsync(DataPath.root, svg);
      expect(
        await draft.selectConcreteTypeAsync(DataPath.root, iconify),
        isA<AppliedEditorMutation>(),
      );
      first.complete(initialized(svg, "<svg/>"));
      expect(await older, isA<ConflictingEditorMutation>());
      expect(draft.finalize().valueOrNull, initial);
    },
  );

  test("initializer exceptions become invalid results", () async {
    final editor = LocalEditor(
      rootType: const NamedType(abstract),
      typeCatalog: catalog,
      value: initial,
      concreteTypeInitializer: ({required type, required supplied}) =>
          throw StateError("unavailable"),
    );
    addTearDown(editor.dispose);

    final result = await editor.selectConcreteTypeAsync(DataPath.root, svg);
    expect(result, isA<InvalidEditorMutation>());
    expect(
      (result as InvalidEditorMutation).diagnostics.single.message,
      contains("unavailable"),
    );

    final draft = CreationDraft.fromMaterialized(
      rootType: const NamedType(abstract),
      value: initial,
      registry: TypeRegistry(catalog),
      concreteTypeInitializer: ({required type, required supplied}) =>
          throw StateError("unavailable"),
    );
    addTearDown(draft.dispose);
    final draftResult = await draft.selectConcreteTypeAsync(DataPath.root, svg);
    expect(draftResult, isA<InvalidEditorMutation>());
    expect(
      (draftResult as InvalidEditorMutation).diagnostics.single.message,
      contains("unavailable"),
    );
  });
}
