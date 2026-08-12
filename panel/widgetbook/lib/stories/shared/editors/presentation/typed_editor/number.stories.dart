import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/shared/editors/presentation/typed_editor/typed_editor.stories.dart";

@widgetbook.UseCase(name: "Number", type: TypedEditor)
Widget numberEditorUseCase(BuildContext context) {
  return EditorStory(
    rootType: RecordType(
      fields: {
        "count": const TypeField(
          name: "count",
          type: IntegerType(width: IntegerWidth.signed32),
        ),
        "level": TypeField(
          name: "level",
          type: IntegerType(
            width: IntegerWidth.unsigned8,
            minimum: BigInt.one,
            maximum: BigInt.from(100),
          ),
        ),
        "price": const TypeField(
          name: "price",
          type: DecimalType(minimum: "-1000.0", maximum: "1000.0"),
        ),
      },
    ),
    initialValue: RecordValue({
      "count": IntegerValue(BigInt.from(42)),
      "level": IntegerValue(BigInt.one),
      "price": DecimalValue("12.50"),
    }),
  );
}
