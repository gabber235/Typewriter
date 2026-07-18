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
        "Browse and search all your books. Discover, organize, and manage your collection with ease.",
  );
  return FakeApp(
    child: Align(
      alignment: Alignment.topLeft,
      child: PageHeading(title: title, subtext: subtext),
    ),
  );
}

@widgetbook.UseCase(name: "Without Subtext", type: PageHeading)
Widget pageHeadingWithoutSubtextUseCase(BuildContext context) {
  final title = context.knobs.string(label: "Title", initialValue: "Members");
  return FakeApp(
    child: Align(
      alignment: Alignment.topLeft,
      child: PageHeading(title: title),
    ),
  );
}
