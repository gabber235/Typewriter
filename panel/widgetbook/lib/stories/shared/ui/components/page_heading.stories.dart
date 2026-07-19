import "package:flutter/material.dart";
import "package:typewriter_panel/shared/ui/components/page_heading.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Default", type: PageHeading)
Widget pageHeadingDefaultUseCase(BuildContext context) {
  final title = context.knobs.string(label: "Title", initialValue: "Library");
  final subtext = context.knobs.string(
    label: "Subtext",
    initialValue:
        "Browse books containing your quests, dialogues, and cinematics. Search by title or tag, organize related content, then open a book to continue editing its pages.",
  );
  return FakeApp(
    child: Align(
      alignment: Alignment.topLeft,
      child: PageHeading(title: title, subtext: subtext),
    ),
  );
}
