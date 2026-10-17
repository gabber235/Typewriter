import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test(
    "shared duration range and arithmetic boundaries are admitted exactly",
    () async {
      final source = await File(
        "../skir-src/editor/v1/fixtures/portable_duration_conformance.json",
      ).readAsString();
      final fixture = jsonDecode(source) as Map<String, Object?>;
      expect(
        fixture["maximumMilliseconds"],
        PortableDurationMilliseconds.maximum.toString(),
      );
      for (final item
          in (fixture["cases"]! as List).cast<Map<String, Object?>>()) {
        final milliseconds = int.parse(item["milliseconds"]! as String);
        final value = skir.Duration(milliseconds: milliseconds);
        final decoded = skir.Duration.serializer.fromBytes(
          skir.Duration.serializer.toBytes(value),
        );
        expect(
          decoded.milliseconds,
          milliseconds,
          reason: item["id"]! as String,
        );
        final payload = skir.DataValue.createDuration(value: value);
        final payloadDecoded = skir.DataValue.serializer.fromBytes(
          skir.DataValue.serializer.toBytes(payload),
        ) as skir.DataValue_durationWrapper;
        expect(
          payloadDecoded.value.value.milliseconds,
          milliseconds,
          reason: item["id"]! as String,
        );
        expect(
          value.isPortable,
          item["admitted"],
          reason: item["id"]! as String,
        );
        expect(
          admitsPortableScalarValue(
            skir.ScalarKind.duration,
            skir.DataValue.createDuration(value: value),
          ),
          item["admitted"],
          reason: item["id"]! as String,
        );
      }
      for (final item
          in (fixture["steps"]! as List).cast<Map<String, Object?>>()) {
        final value = int.parse(item["value"]! as String);
        final increment = int.parse(item["increment"]! as String);
        expect(
          (value + increment).isPortableDurationMilliseconds,
          item["admitted"],
          reason: item["id"]! as String,
        );
      }
    },
  );
  test("duration formatter rejects raw values outside shared admission", () {
    final expression = skir.ExpressionNode.createCall(
      operation: skir.OperationId(value: "typewriter.duration.format"),
      arguments: [
        skir.ExpressionNode.wrapLiteral(
          skir.DataValue.createDuration(
            value: skir.Duration(
              milliseconds: PortableDurationMilliseconds.maximum + 1,
            ),
          ),
        ),
        skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapStringValue("MinutesAndSeconds"),
        ),
        skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapInteger("3")),
      ],
    );
    final result = PortableExpressionEvaluator(
      const {},
      budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
    ).evaluate(expression);
    expect(result, isA<PortableExpressionFailed>());
    expect((result as PortableExpressionFailed).code, "duration_range");
  });
}
