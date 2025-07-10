import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/widgets/generic/components/decorated_text_field.dart";
import "package:typewriter_panel/widgets/generic/components/icones.dart";

class FormattedTextField extends HookWidget {
  const FormattedTextField({
    required this.focusNode,
    this.controller,
    this.text,
    this.onChanged,
    this.onDone,
    this.onSubmitted,
    this.inputFormatters,
    this.keyboardType = TextInputType.text,
    this.hintText,
    this.icon,
    this.singleLine = true,
    this.readOnly = false,
    super.key,
  }) : super();
  final TextEditingController? controller;
  final FocusNode focusNode;
  final String? text;
  final Function(String)? onChanged;
  final Function(String)? onDone;
  final Function(String)? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType keyboardType;
  final String? hintText;
  final String? icon;
  final bool singleLine;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return DecoratedTextField(
      controller: controller,
      focusNode: focusNode,
      text: text,
      onChanged: onChanged,
      onDone: onDone,
      onSubmitted: onSubmitted,
      maxLines: singleLine ? 1 : null,
      keyboardType: keyboardType,
      readOnly: readOnly,
      inputFormatters: [
        if (singleLine) FilteringTextInputFormatter.singleLineFormatter,
        if (inputFormatters != null) ...inputFormatters!,
      ],
      decoration: InputDecoration(
        prefixIcon: icon != null
            ? Padding(
                padding: const EdgeInsets.all(8),
                child: Icones(icon!, size: 18),
              )
            : null,
        hintText: hintText,
        contentPadding: singleLine
            ? null
            : const EdgeInsets.only(top: 12, bottom: 12, right: 8),
      ),
    );
  }
}
