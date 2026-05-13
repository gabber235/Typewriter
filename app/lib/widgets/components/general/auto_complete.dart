import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/utils/passing_reference.dart";
import "package:typewriter/widgets/components/general/formatted_text_field.dart";
import "package:typewriter/widgets/inspector/current_editing_field.dart";

class AutoCompleteField extends StatelessWidget {
  const AutoCompleteField({
    required this.text,
    required this.onQuery,
    required this.onChanged,
    this.icon,
    this.hintText,
    this.inputFormatters,
    this.path,
    super.key,
  });

  final String text;
  final String? hintText;
  final String? icon;

  final Iterable<String> Function(String) onQuery;
  final Function(String) onChanged;
  final List<TextInputFormatter>? inputFormatters;

  /// If this Field is used as a Entry field. We want to be able to sync which writers are looking at what.
  /// Thus we need this field also to sync hence we need the path.
  final String? path;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: text),
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
        return _TextField(
          controller: textEditingController,
          focusNode: focusNode,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
          icon: icon,
          text: text,
          hintText: hintText ?? l10n.enterAValueEmpty,
          path: path,
        );
      },
      onSelected: onChanged,
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.trim().isEmpty) return const Iterable.empty();
        return onQuery(textEditingValue.text)
            .where((value) => value.contains(textEditingValue.text))
            .toSet();
      },
    );
  }
}

class _TextField extends HookConsumerWidget {
  const _TextField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.inputFormatters,
    required this.icon,
    required this.text,
    required this.hintText,
    required this.path,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  final Function(String value) onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final String? icon;
  final String text;
  final String hintText;

  final String? path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (path != null) {
      useFocusedBasedCurrentEditingField(focusNode, ref.passing, path!);
    }

    return FormattedTextField(
      controller: controller,
      focus: focusNode,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      singleLine: true,
      icon: icon,
      text: text,
      hintText: hintText,
    );
  }
}
