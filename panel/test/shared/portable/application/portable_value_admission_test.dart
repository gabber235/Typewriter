import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  test(
    "inspection locates unfinished fields without admitting missing fields",
    () {
      final page = typeDefinition("Page");
      final named = skir.NamedTypeUse(definition: page, arguments: const []);
      final checked = testCheckedCatalog(
        generation: _admissionGeneration,
        types: [
          declaredRecord(
            page,
            fields: {
              for (final name in ["name", "title"])
                name: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
            },
          ),
        ],
      );
      skir.DataValue value(List<skir.FieldValue> fields) =>
          skir.DataValue.createNamed(
            actualType: named,
            payload: skir.DataValue.createRecord(fields: fields),
          );
      final unfinished = value([
        for (final name in ["name", "title"])
          skir.FieldValue(name: name, value: skir.DataValue.unfilled),
      ]);
      final result = checked.inspectPortableValue(
        skir.TypeUse.wrapNamed(named),
        unfinished,
      );
      expect(result.structuralProblems, isEmpty);
      expect(result.unfinished, [
        for (final name in ["name", "title"])
          skir.ValuePath(segments: [skir.PathSegment.createField(name: name)]),
      ]);
      expect(
        checked.admitsPortableValue(skir.TypeUse.wrapNamed(named), unfinished),
        isTrue,
      );
      final missing = checked.inspectPortableValue(
        skir.TypeUse.wrapNamed(named),
        value([]),
      );
      expect(missing.structuralProblems.map((p) => p.code), [
        "missing_field",
        "missing_field",
      ]);
      expect(missing.unfinished, isEmpty);
      expect(
        checked.admitsPortableValue(skir.TypeUse.wrapNamed(named), value([])),
        isFalse,
      );
    },
  );

  test("named scalar payload keeps its checked identity", () {
    final chapter = typeDefinition("ChapterPath");
    final page = typeDefinition("Page");
    final expected = skir.TypeUse.createNamed(
      definition: chapter,
      arguments: const [],
    );
    final checked = testCheckedCatalog(
      generation: _admissionGeneration,
      types: [
        declaredScalar(chapter, skir.ScalarKind.text),
        declaredRecord(
          page,
          fields: {
            "chapter": skir.TypeTemplate.createNamed(
              definition: chapter,
              arguments: const [],
            ),
          },
        ),
      ],
    );
    final payload = skir.DataValue.wrapStringValue("opening");

    expect(checked.admitsPortableValue(expected, payload), isFalse);
    final admitted = checked.admitPortablePayloadAt(
      selectionOfUse(skir.NamedTypeUse(definition: page, arguments: const [])),
      skir.ValuePath(segments: [skir.PathSegment.createField(name: "chapter")]),
      payload,
    );

    expect(
      admitted,
      skir.DataValue.createNamed(
        actualType: skir.NamedTypeUse(definition: chapter, arguments: const []),
        payload: payload,
      ),
    );
    expect(checked.admitsPortableValue(expected, admitted!), isTrue);
  });

  test("rejects an application whose argument violates its bound", () {
    final marker = typeDefinition("Marker");
    final box = typeDefinition("Box");
    final checked = testCheckedCatalog(
      generation: _admissionGeneration,
      types: [
        declaredRecord(marker),
        declaredRecord(
          box,
          parameters: {
            "T": [marker],
          },
        ),
      ],
    );
    final invalid = skir.NamedTypeUse(
      definition: box,
      arguments: [skir.TypeUse.wrapScalar(skir.ScalarKind.text)],
    );
    final value = namedRecord(invalid);

    expect(
      checked.isReadableAs(
        skir.TypeUse.wrapNamed(invalid),
        skir.TypeUse.wrapNamed(invalid),
      ),
      isTrue,
    );
    expect(checked.isReadyApplication(invalid), isFalse);
    expect(
      checked.admitsPortableValue(skir.TypeUse.wrapNamed(invalid), value),
      isFalse,
    );

    final valid = skir.NamedTypeUse(
      definition: box,
      arguments: [
        skir.TypeUse.createNamed(definition: marker, arguments: const []),
      ],
    );
    expect(checked.isReadyApplication(valid), isTrue);
    expect(
      checked.admitsPortableValue(
        skir.TypeUse.wrapNamed(valid),
        namedRecord(valid),
      ),
      isTrue,
    );
  });

  test("rejects values whose declaration is unavailable", () {
    final unavailable = typeDefinition("Unavailable");
    final checked = testCheckedCatalog(
      generation: _admissionGeneration,
      types: [
        declaredRecord(
          unavailable,
          status: skir.DeclarationStatus.wrapUnavailable(const []),
        ),
      ],
    );
    final use = skir.NamedTypeUse(definition: unavailable, arguments: const []);

    expect(
      checked.isReadableAs(
        skir.TypeUse.wrapNamed(use),
        skir.TypeUse.wrapNamed(use),
      ),
      isTrue,
    );
    expect(checked.isReadyApplication(use), isFalse);
    expect(
      checked.admitsPortableValue(
        skir.TypeUse.wrapNamed(use),
        namedRecord(use),
      ),
      isFalse,
    );
  });

  test("rejects unknown scalar kinds inside named applications", () {
    final box = typeDefinition("Box");
    final checked = testCheckedCatalog(
      generation: _admissionGeneration,
      types: [
        declaredRecord(box, parameters: {"T": []}),
      ],
    );
    final applications = [
      skir.NamedTypeUse(
        definition: box,
        arguments: [skir.TypeUse.wrapScalar(skir.ScalarKind.unknown)],
      ),
      skir.NamedTypeUse(
        definition: box,
        arguments: [
          skir.TypeUse.wrapScalar(
            skir.ScalarKind.createInteger(width: skir.IntegerWidth.unknown),
          ),
        ],
      ),
      skir.NamedTypeUse(
        definition: box,
        arguments: [
          skir.TypeUse.wrapScalar(
            skir.ScalarKind.createFloat(width: skir.FloatWidth.unknown),
          ),
        ],
      ),
    ];

    for (final application in applications) {
      expect(checked.isReadyApplication(application), isFalse);
      expect(
        checked.admitsPortableValue(
          skir.TypeUse.wrapNamed(application),
          namedRecord(application),
        ),
        isFalse,
      );
    }
  });

  test("a value under a content type gets no local refusal", () {
    final reward = contentTypeDefinition("reward", "k1");
    final checked = testCheckedCatalog(
      generation: _admissionGeneration,
      types: const [],
    );
    final use = skir.NamedTypeUse(definition: reward, arguments: const []);

    expect(
      checked.admitsPortableValue(
        skir.TypeUse.wrapNamed(use),
        skir.DataValue.createNamed(
          actualType: use,
          payload: skir.DataValue.createRecord(
            fields: [
              skir.FieldValue(
                name: "gold",
                value: skir.DataValue.wrapInteger("70"),
              ),
            ],
          ),
        ),
      ),
      isTrue,
    );
  });
}

/// A record representation without declared fields; effective fields alone
/// describe what a value holds.

final _admissionGeneration = skir.CatalogGeneration(value: "catalog:admission");
