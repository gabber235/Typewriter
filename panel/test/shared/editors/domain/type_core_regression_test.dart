import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("registry caches structurally exact generic applications", () {
    final box = _revision("Box");
    final registry = TypeRegistry(
      TypeCatalog([
        TypeDefinition(
          id: box,
          kind: NominalTypeKind.concrete,
          parameters: const [TypeParameter(name: "T")],
          representation: const ParameterType("T"),
        ),
      ]),
    );
    final short = NamedType(
      box.withArguments(const [StringType(minimumLength: 1)]),
    );
    final long = NamedType(
      box.withArguments(const [StringType(minimumLength: 10)]),
    );

    final shortResult = registry.resolve(short).valueOrNull!;
    final longResult = registry.resolve(long).valueOrNull!;

    expect(
      shortResult.representation,
      isA<StringType>().having(
        (type) => type.minimumLength,
        "minimum length",
        1,
      ),
    );
    expect(
      longResult.representation,
      isA<StringType>().having(
        (type) => type.minimumLength,
        "minimum length",
        10,
      ),
    );
    expect(shortResult.reference, short.reference);
    expect(longResult.reference, long.reference);
  });

  test("nominal validation checks exact tags and resolved payloads", () {
    final person = _revision("Person");
    final personRecord = _revision("PersonRecord");
    final other = _revision("Other");
    final registry = TypeRegistry(
      TypeCatalog([
        TypeDefinition(id: person, kind: NominalTypeKind.sealedAbstract),
        TypeDefinition(
          id: personRecord,
          kind: NominalTypeKind.concrete,
          parents: [person],
          representation: RecordType(
            fields: {
              "name": const TypeField(
                name: "name",
                type: StringType(minimumLength: 1),
              ),
            },
          ),
        ),
      ]),
    );
    final type = NamedType(person);

    final wrongTag = PolymorphicValue(
      concreteType: other,
      value: RecordValue({}),
    ).validateAgainst(type, registry: registry);
    final wrongPayload = PolymorphicValue(
      concreteType: personRecord,
      value: RecordValue({}),
    ).validateAgainst(type, registry: registry);
    final mutation = type.validateEditorMutation(
      DataPath.root,
      PolymorphicValue(concreteType: personRecord, value: RecordValue({})),
      registry: registry,
    );
    final missingRegistry = type.validateEditorMutation(
      DataPath.root,
      PolymorphicValue(
        concreteType: personRecord,
        value: RecordValue({"name": const StringValue("Ada")}),
      ),
    );

    expect(wrongTag.single.code, TypeDiagnosticCode.unknownType);
    expect(wrongPayload.single.code, TypeDiagnosticCode.missingField);
    expect(
      mutation,
      isA<InvalidEditorMutation>().having(
        (result) => result.diagnostics.single.code,
        "diagnostic code",
        TypeDiagnosticCode.missingField,
      ),
    );
    expect(
      missingRegistry,
      isA<InvalidEditorMutation>().having(
        (result) => result.diagnostics.single.message,
        "message",
        contains("requires a registry"),
      ),
    );
  });

  test("inheritance conversion graph contains only direct upcasts", () {
    final ancestor = _revision("Ancestor");
    final parent = _revision("Parent");
    final child = _revision("Child");
    final registry = TypeRegistry(
      TypeCatalog([
        TypeDefinition(
          id: ancestor,
          kind: NominalTypeKind.concrete,
          representation: RecordType(fields: {}),
        ),
        TypeDefinition(
          id: parent,
          kind: NominalTypeKind.concrete,
          representation: RecordType(fields: {}),
          parents: [ancestor],
        ),
        TypeDefinition(
          id: child,
          kind: NominalTypeKind.concrete,
          representation: RecordType(fields: {}),
          parents: [parent],
        ),
      ]),
    );
    final graph = ConversionGraph.withInheritance(
      registry: registry,
      applications: [child],
    ).valueOrNull!;

    final path = graph.automaticPath(child, ancestor).valueOrNull!;

    expect(path.map((edge) => edge.target), [parent, ancestor]);
  });

  test("decimal validation enforces exact minimum and maximum", () {
    const type = DecimalType(minimum: "0.01", maximum: "9.99", scale: 2);

    expect(DecimalValue("0.01").validateAgainst(type), isEmpty);
    expect(DecimalValue("9.99").validateAgainst(type), isEmpty);
    expect(DecimalValue("0.001").validateAgainst(type), isNotEmpty);
    expect(DecimalValue("10").validateAgainst(type), isNotEmpty);
  });

  test("constrained scalar types support refinement and intersection", () {
    const decimalParent = DecimalType(minimum: "0", maximum: "10", scale: 2);
    const decimalChild = DecimalType(minimum: "2", maximum: "8", scale: 1);
    final timestampParent = TimestampType(
      minimum: DateTime.utc(2020),
      maximum: DateTime.utc(2030),
    );
    final timestampChild = TimestampType(
      minimum: DateTime.utc(2022),
      maximum: DateTime.utc(2028),
    );
    const durationParent = DurationType(
      minimum: Duration(seconds: 1),
      maximum: Duration(seconds: 10),
    );
    const durationChild = DurationType(
      minimum: Duration(seconds: 2),
      maximum: Duration(seconds: 8),
    );
    const stringParent = StringType();
    const stringChild = StringType(patterns: [r"^[a-z]+$"]);
    final registry = TypeRegistry(TypeCatalog(const []));

    expect(
      decimalChild.isStructurallyAssignableTo(decimalParent, registry),
      isTrue,
    );
    expect(
      timestampChild.isStructurallyAssignableTo(timestampParent, registry),
      isTrue,
    );
    expect(
      durationChild.isStructurallyAssignableTo(durationParent, registry),
      isTrue,
    );
    expect(
      stringChild.isStructurallyAssignableTo(stringParent, registry),
      isTrue,
    );
    expect(
      typeExpressionsEqual(
        intersectTypes(decimalParent, decimalChild).valueOrNull!,
        decimalChild,
      ),
      isTrue,
    );
    expect(
      typeExpressionsEqual(
        intersectTypes(timestampParent, timestampChild).valueOrNull!,
        timestampChild,
      ),
      isTrue,
    );
    expect(
      typeExpressionsEqual(
        intersectTypes(durationParent, durationChild).valueOrNull!,
        durationChild,
      ),
      isTrue,
    );
    expect(
      typeExpressionsEqual(
        intersectTypes(stringParent, stringChild).valueOrNull!,
        stringChild,
      ),
      isTrue,
    );
  });
}

ResolvedTypeRef _revision(String name) => ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "test", name: name),
  revision: 1,
);
