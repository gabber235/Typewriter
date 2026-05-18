import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter/l10n/l10n_provider.dart";
import "package:typewriter/models/writers.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/utils/icons.dart";
import "package:typewriter/utils/passing_reference.dart";
import "package:typewriter/widgets/components/app/writers.dart";
import "package:typewriter/widgets/components/general/formatted_text_field.dart";
import "package:typewriter/widgets/inspector/current_editing_field.dart";
import "package:typewriter/widgets/inspector/editors.dart";
import "package:typewriter/widgets/inspector/inspector.dart";
import "package:typewriter/widgets/inspector/section_title.dart";

class NameField extends HookConsumerWidget {
  const NameField({super.key}) : super();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final focus = useFocusNode();
    useFocusedBasedCurrentEditingField(focus, ref.passing, "name");
    final name = ref.watch(fieldValueProvider("name"));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: l10n.name),
        const SizedBox(height: 1),
        WritersIndicator(
          provider: fieldWritersProvider("name"),
          shift: (_) => const Offset(15, 0),
          child: FormattedTextField(
            focus: focus,
            text: name,
            onChanged: (value) {
              ref
                  .read(inspectingEntryDefinitionProvider)
                  ?.updateField(ref.passing, "name", value);
            },
            inputFormatters: [
              snakeCaseFormatter(),
              FilteringTextInputFormatter.allow(RegExp("[a-z0-9_.]")),
            ],
            hintText: l10n.nameHint,
            icon: TWIcons.signature,
          ),
        ),
      ],
    );
  }
}
