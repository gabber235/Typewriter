import "package:flutter/material.dart";
import "package:typewriter_panel/widgets/generic/components/type_link.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Default", type: TypeLink)
Widget typeLinkDefaultUseCase(BuildContext context) {
  final text = context.knobs.string(label: "Text", initialValue: "Engine");

  final url = context.knobs.string(
    label: "URL (optional)",
    initialValue: "https://docs.typewritermc.com/develop",
  );

  final lightColor = context.knobs.color(
    label: "Light Color",
    initialValue: Colors.blue,
  );

  final darkColor =
      context.knobs.boolean(label: "Custom Dark Color?", initialValue: false)
          ? context.knobs.color(
            label: "Dark Color",
            initialValue: Colors.lightBlueAccent,
          )
          : null;

  return Center(
    child: TypeLink(
      text: text,
      url: url.isEmpty ? null : url,
      lightColor: lightColor,
      darkColor: darkColor,
    ),
  );
}
