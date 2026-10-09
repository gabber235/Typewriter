import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  final graphValue = skir.DataValue.createRecord(
    fields: [
      _integerField("x", 1),
      _integerField("y", 2),
      _integerField("width", 3),
      _integerField("height", 4),
    ],
  );

  test("placement variants are selected by declared type identity", () {
    final placement = decodePlacement(
      skir.DataValue.createNamed(
        actualType: skir.NamedTypeUse(
          definition: placementTypeRefs.graph,
          arguments: const [],
        ),
        payload: graphValue,
      ),
    );

    expect(placement, GraphPlacement(x: 1, y: 2, width: 3, height: 4));
  });

  test("placement decoding rejects an unknown type with a familiar shape", () {
    final unknown = skir.TypeDefinitionId(
      typeId: skir.TypeId.createDeclared(
        value: "b3af85bf5a024f2b8806fb3d5c4f15ec",
      ),
      revision: 1,
    );

    expect(
      () => decodePlacement(
        skir.DataValue.createNamed(
          actualType: skir.NamedTypeUse(
            definition: unknown,
            arguments: const [],
          ),
          payload: graphValue,
        ),
      ),
      throwsArgumentError,
    );
  });
}

skir.FieldValue _integerField(String name, int value) => skir.FieldValue(
  name: name,
  value: skir.DataValue.wrapInteger(value.toString()),
);
