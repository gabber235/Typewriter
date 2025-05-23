import "package:flutter/material.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Default", type: TextField)
Widget inputFieldUseCase(BuildContext context) {
  final hint = context.knobs.string(
    label: "Hint",
    initialValue: "Enter text here",
  );
  final isEnabled = context.knobs.boolean(label: "Enabled", initialValue: true);

  return TextField(
    enabled: isEnabled,
    decoration: InputDecoration(hintText: hint),
  );
}

@widgetbook.UseCase(name: "Error", type: TextField)
Widget inputFieldErrorUseCase(BuildContext context) {
  final hint = context.knobs.string(
    label: "Hint",
    initialValue: "Enter text here",
  );
  final errorText = context.knobs.string(
    label: "Error Text",
    initialValue: "This field is required",
  );

  return TextField(
    decoration: InputDecoration(hintText: hint, errorText: errorText),
  );
}

@widgetbook.UseCase(name: "With Prefix Icon", type: TextField)
Widget inputFieldWithPrefixIconUseCase(BuildContext context) {
  final hint = context.knobs.string(
    label: "Hint",
    initialValue: "Enter text here",
  );
  final icon = context.knobs.list(
    label: "Icon",
    options: const [
      Icon(Icons.search),
      Icon(Icons.person),
      Icon(Icons.email),
      Icon(Icons.lock),
    ],
    initialOption: const Icon(Icons.search),
    labelBuilder: (option) => option.icon.toString(),
  );

  return TextField(
    decoration: InputDecoration(hintText: hint, prefixIcon: icon),
  );
}
