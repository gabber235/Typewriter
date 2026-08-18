import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/shared/editors/presentation/typed_editor/typed_editor.stories.dart";

@widgetbook.UseCase(name: "List", type: TypedEditor)
Widget listEditorUseCase(BuildContext context) {
  return EditorStory(
    rootType: RecordType(
      fields: {
        "items": TypeField(
          name: "items",
          type: ListType(element: StringType()),
        ),
        "numbers": TypeField(
          name: "numbers",
          type: ListType(element: IntegerType(width: IntegerWidth.signed32)),
        ),
        "nested": TypeField(
          name: "nested",
          type: ListType(
            element: RecordType(
              fields: {
                "name": TypeField(name: "name", type: StringType()),
                "value": TypeField(
                  name: "value",
                  type: IntegerType(width: IntegerWidth.signed32),
                ),
              },
            ),
          ),
        ),
      },
    ),
    initialValue: RecordValue({
      "items": ListValue([
        const StringValue("Hey there"),
        const StringValue("How is it going?"),
      ]),
      "numbers": ListValue([IntegerValue(BigInt.one)]),
      "nested": ListValue([
        RecordValue({
          "name": const StringValue("Item 1"),
          "value": IntegerValue(BigInt.one),
        }),
        RecordValue({
          "name": const StringValue("Item 2"),
          "value": IntegerValue(BigInt.two),
        }),
      ]),
    }),
  );
}
