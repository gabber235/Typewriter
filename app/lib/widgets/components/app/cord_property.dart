import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter/hooks/select_on_focus.dart";
import "package:typewriter/models/writers.dart";
import "package:typewriter/utils/passing_reference.dart";
import "package:typewriter/widgets/components/app/writers.dart";
import "package:typewriter/widgets/components/general/decorated_text_field.dart";
import "package:typewriter/widgets/inspector/current_editing_field.dart";
import "package:typewriter/widgets/inspector/editors.dart";
import "package:typewriter/widgets/inspector/inspector.dart";

class CordPropertyEditor extends HookConsumerWidget {
  const CordPropertyEditor({
    required this.path,
    required this.label,
    required this.color,
    super.key,
  });
  final String path;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(fieldValueProvider(path, 0.0));
    final controller = useTextEditingController(text: value.toString());
    final focus = useFocusNode();

    useSelectOnFocus(focus, controller);

    useFocusedBasedCurrentEditingField(focus, ref.passing, path);

    return Flexible(
      child: WritersIndicator(
        provider: fieldWritersProvider(path, exact: true),
        shift: (_) => const Offset(15, 0),
        child: DecoratedTextField(
          controller: controller,
          focus: focus,
          text: value.toString(),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r"^\-?\d*\.?\d*")),
          ],
          onChanged: (value) {
            final number = double.tryParse(value);
            if (number == null) return;
            ref
                .read(inspectingEntryDefinitionProvider)
                ?.updateField(ref.passing, path, number);
          },
          decoration: InputDecoration(
            prefixText: "$label: ",
            prefixStyle: TextStyle(color: color),
          ),
        ),
      ),
    );
  }
}
