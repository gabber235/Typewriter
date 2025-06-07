import "package:flutter/material.dart";
import "package:typewriter_panel/widgets/generic/components/page_heading.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "PageHeading", type: PageHeading)
Widget pageHeadingUseCase(BuildContext context) {
  final title = context.knobs.string(label: "Title", initialValue: "Library");
  final subtext = context.knobs.string(
    label: "Subtext",
    initialValue: "A collection of all your books, organized and searchable.",
  );
  return Center(
    child: SizedBox(
      width: 500,
      child: PageHeading(title: title, subtext: subtext),
    ),
  );
}
