import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter/utils/icons.dart";
import "package:typewriter/utils/passing_reference.dart";
import "package:typewriter/widgets/components/general/validated_text_field.dart";
import "package:typewriter/widgets/inspector/current_editing_field.dart";
import "package:typewriter/widgets/inspector/editors.dart";
import "package:typewriter/widgets/inspector/inspector.dart";

class ValidatedInspectorTextField<T> extends HookConsumerWidget {
  const ValidatedInspectorTextField({
    required this.path,
    required this.defaultValue,
    required this.deserialize,
    required this.serialize,
    this.formatted,
    this.validator,
    this.icon = TWIcons.textFields,
    this.keyboardType = TextInputType.text,
    this.inputFormatters = const [],
    this.keepValidVisibleWhileFocused = false,
    super.key,
  });
  final String path;
  final T defaultValue;
  final String Function(T) deserialize;
  final T Function(String) serialize;
  final String Function(T)? formatted;
  final String? Function(T)? validator;
  final String icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final bool keepValidVisibleWhileFocused;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focus = useFocusNode();
    useFocusedBasedCurrentEditingField(focus, ref.passing, path);

    final value = ref.watch(fieldValueProvider(path, defaultValue));
    final name = ref.watch(pathDisplayNameProvider(path));

    return ValidatedTextField<T>(
      value: value,
      deserialize: deserialize,
      serialize: serialize,
      formatted: formatted,
      validator: validator,
      focusNode: focus,
      name: name,
      icon: icon,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      keepValidVisibleWhileFocused: keepValidVisibleWhileFocused,
      onChanged: (value) => ref
          .read(inspectingEntryDefinitionProvider)
          ?.updateField(ref.passing, path, value),
    );
  }
}
