import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  final graphValue = RecordValue({
    "x": 1.asValue,
    "y": 2.asValue,
    "width": 3.asValue,
    "height": 4.asValue,
  });

  test("placement variants are selected by declared type identity", () {
    final placement = decodePlacement(
      PolymorphicValue(
        concreteType: placementTypeRefs.graph,
        value: graphValue,
      ),
    );

    expect(placement, GraphPlacement(x: 1, y: 2, width: 3, height: 4));
  });

  test("placement decoding rejects an unknown type with a familiar shape", () {
    final unknown = ResolvedTypeRef(
      id: TypeId.declared("b3af85bf5a024f2b8806fb3d5c4f15ec"),
      revision: 1,
    );

    expect(
      () => decodePlacement(
        PolymorphicValue(concreteType: unknown, value: graphValue),
      ),
      throwsArgumentError,
    );
  });
}
