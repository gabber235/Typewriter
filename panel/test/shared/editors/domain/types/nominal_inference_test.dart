import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("dependent bounds infer and persist an exact backed variable type", () {
    final variableEntry = _ref("VariableEntry");
    final stringEntry = _ref("StringEntry");
    final variable = _ref("Var");
    final constantVariable = _ref("ConstVar");
    final backedVariable = _ref("BackedVar");
    const dataType = IntegerType(width: IntegerWidth.signed32);
    const valueType = StringType();
    final stringEntryType = NamedType(stringEntry);
    final registry = TypeRegistry(
      TypeCatalog([
        TypeDefinition(
          id: variableEntry,
          kind: NominalTypeKind.openAbstract,
          parameters: const [
            TypeParameter(name: "T"),
            TypeParameter(name: "D"),
          ],
        ),
        TypeDefinition(
          id: stringEntry,
          kind: NominalTypeKind.concrete,
          parents: [
            variableEntry.withArguments([valueType, dataType]),
          ],
        ),
        TypeDefinition(
          id: variable,
          kind: NominalTypeKind.openAbstract,
          parameters: const [TypeParameter(name: "T")],
        ),
        TypeDefinition(
          id: constantVariable,
          kind: NominalTypeKind.concrete,
          parameters: const [TypeParameter(name: "T")],
          parents: [
            variable.withArguments(const [ParameterType("T")]),
          ],
          representation: const ParameterType("T"),
        ),
        TypeDefinition(
          id: backedVariable,
          kind: NominalTypeKind.concrete,
          parameters: [
            const TypeParameter(name: "T"),
            TypeParameter(
              name: "V",
              bound: NamedType(
                variableEntry.withArguments(const [
                  ParameterType("T"),
                  ParameterType("D"),
                ]),
              ),
            ),
            const TypeParameter(name: "D"),
          ],
          parents: [
            variable.withArguments(const [ParameterType("T")]),
          ],
          representation: RecordType(
            fields: {
              "entry": TypeField(
                name: "entry",
                type: NamedType(
                  standardTypeRefs.refTo(const ParameterType("V")),
                ),
              ),
              "data": const TypeField(name: "data", type: ParameterType("D")),
            },
          ),
        ),
      ]),
    );

    final inferred = backedVariable.inferFrom(stringEntryType, registry);
    final expected = backedVariable.withArguments([
      valueType,
      stringEntryType,
      dataType,
    ]);

    expect(inferred.valueOrNull, expected);
    expect(registry.resolveExact(expected).diagnostics, isEmpty);
    expect(
      registry
          .resolveExact(constantVariable.withArguments(const [StringType()]))
          .valueOrNull!
          .ancestors,
      contains(variable.withArguments(const [StringType()])),
    );
  });

  test("sealed abstract descendants must retain their owner", () {
    final sealed = _ref("Sealed", namespace: "owner/v1");
    final local = _ref("Local", namespace: "owner/v1");
    final foreign = _ref("Foreign", namespace: "foreign/v1");
    final registry = TypeRegistry(
      TypeCatalog([
        TypeDefinition(id: sealed, kind: NominalTypeKind.sealedAbstract),
        TypeDefinition(
          id: local,
          kind: NominalTypeKind.concrete,
          parents: [sealed],
        ),
        TypeDefinition(
          id: foreign,
          kind: NominalTypeKind.concrete,
          parents: [sealed],
        ),
      ]),
    );

    expect(registry.resolveExact(local).diagnostics, isEmpty);
    expect(
      registry.resolveExact(foreign).diagnostics.single.code,
      TypeDiagnosticCode.invalidConcreteType,
    );
  });
}

ResolvedTypeRef _ref(String name, {String namespace = "variables/v1"}) =>
    ResolvedTypeRef(
      id: QualifiedTypeId(namespace: namespace, name: name),
      revision: 1,
    );
