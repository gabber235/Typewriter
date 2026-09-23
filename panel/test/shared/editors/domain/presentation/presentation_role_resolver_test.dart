import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  const role = PresentationRole.referenceSummary;
  const inherited = PresentationId(namespace: "test", name: "inherited");

  test("resolves the nearest role through instantiated generic parents", () {
    final base = _definition(
      "Base",
      parameters: const [TypeParameter(name: "T")],
      roles: const {role: inherited},
    );
    final middle = _definition(
      "Middle",
      parameters: const [TypeParameter(name: "U")],
      parents: [
        base.id.withArguments(const [ParameterType("U")]),
      ],
    );
    final leaf = _definition(
      "Leaf",
      parents: [
        middle.id.withArguments(const [StringType()]),
      ],
    );
    final registry = TypeRegistry(TypeCatalog([base, middle, leaf]));

    expect(
      registry.resolvePresentationRole(leaf.id, role).valueOrNull,
      inherited,
    );
  });

  test("prefers an exact association over an inherited association", () {
    const exact = PresentationId(namespace: "test", name: "exact");
    final base = _definition("Base", roles: const {role: inherited});
    final leaf = _definition(
      "Leaf",
      parents: [base.id],
      roles: const {role: exact},
    );
    final registry = TypeRegistry(TypeCatalog([base, leaf]));

    expect(registry.resolvePresentationRole(leaf.id, role).valueOrNull, exact);
  });

  test("diagnoses distinct associations at equal distance", () {
    final left = _definition(
      "Left",
      roles: const {role: PresentationId(namespace: "test", name: "left")},
    );
    final right = _definition(
      "Right",
      roles: const {role: PresentationId(namespace: "test", name: "right")},
    );
    final leaf = _definition("Leaf", parents: [left.id, right.id]);
    final registry = TypeRegistry(TypeCatalog([left, right, leaf]));

    final result = registry.resolvePresentationRole(leaf.id, role);

    expect(result, isA<TypeFailure<PresentationId>>());
    expect(
      (result as TypeFailure<PresentationId>).diagnostics.single.message,
      contains("ambiguous"),
    );
  });

  test("does not treat an unavailable sibling ancestor as role absence", () {
    final known = _definition("Known", roles: const {role: inherited});
    final leaf = _definition(
      "Leaf",
      parents: [known.id, _reference("Missing")],
    );
    final registry = TypeRegistry(TypeCatalog([known, leaf]));

    final result = registry.resolvePresentationRole(leaf.id, role);

    expect(result, isA<TypeFailure<PresentationId>>());
    expect(
      (result as TypeFailure<PresentationId>).diagnostics.single.code,
      TypeDiagnosticCode.unknownType,
    );
  });

  test("optional creation role falls back only when no association exists", () {
    final base = _definition("Base");
    final leaf = _definition("Leaf", parents: [base.id]);
    final registry = TypeRegistry(TypeCatalog([base, leaf]));

    expect(
      registry.resolveOptionalPresentationRole(
        leaf.id,
        PresentationRole.creation,
      ),
      isA<TypeSuccess<PresentationId?>>(),
    );
    expect(
      registry
          .resolveOptionalPresentationRole(leaf.id, PresentationRole.creation)
          .valueOrNull,
      isNull,
    );
  });

  test("creation editor invokes its role presentation and otherwise uses the default", () {
    const defaultId = PresentationId(namespace: "test", name: "default");
    const creationId = PresentationId(namespace: "test", name: "creation");
    final reference = _reference("Resource");
    final presentations = [
      for (final id in [defaultId, creationId])
        PresentationDefinition.single(
          id: id,
          target: NamedType(reference),
          root: const PresentationNode(id: "root", element: DividerElement()),
        ),
    ];

    PresentationId selected(Map<PresentationRole, PresentationId> roles) {
      final registry = TypeRegistry(
        TypeCatalog([
          TypeDefinition(
            id: reference,
            kind: NominalTypeKind.concrete,
            representation: const StringType(),
            defaultPresentationId: defaultId,
            rolePresentations: roles,
          ),
        ]),
      );
      final draft = CreationDraft(
        rootType: NamedType(reference),
        registry: registry,
      );
      try {
        final model = PresentationModel.editor(
          owner: draft,
          presentations: presentations,
          preferredRole: PresentationRole.creation,
        );
        return (model.root.element as PresentationInvocationElement)
            .presentationId;
      } finally {
        draft.dispose();
      }
    }

    expect(selected(const {PresentationRole.creation: creationId}), creationId);
    expect(selected(const {}), defaultId);
  });
}

TypeDefinition _definition(
  String name, {
  List<TypeParameter> parameters = const [],
  List<ResolvedTypeRef> parents = const [],
  Map<PresentationRole, PresentationId> roles = const {},
}) => TypeDefinition(
  id: _reference(name),
  kind: NominalTypeKind.openAbstract,
  parameters: parameters,
  parents: parents,
  rolePresentations: roles,
);

ResolvedTypeRef _reference(String name) => ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "test", name: name),
  revision: 1,
);
