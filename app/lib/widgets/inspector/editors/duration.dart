import "package:duration/duration.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter/l10n/l10n_provider.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/models/writers.dart";
import "package:typewriter/utils/icons.dart";
import "package:typewriter/widgets/components/app/writers.dart";
import "package:typewriter/widgets/inspector/editors.dart";
import "package:typewriter/widgets/inspector/validated_inspector_text_field.dart";

class DurationEditorFilter extends EditorFilter {
  @override
  bool canEdit(DataBlueprint dataBlueprint) =>
      dataBlueprint is CustomBlueprint && dataBlueprint.editor == "duration";
  @override
  Widget build(String path, DataBlueprint dataBlueprint) => DurationEditor(
        path: path,
        customBlueprint: dataBlueprint as CustomBlueprint,
      );
}

class DurationEditor extends HookConsumerWidget {
  const DurationEditor({
    required this.path,
    required this.customBlueprint,
    super.key,
  });
  final String path;
  final CustomBlueprint customBlueprint;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    return WritersIndicator(
      provider: fieldWritersProvider(path),
      shift: (_) => const Offset(15, 0),
      child: ValidatedInspectorTextField<int>(
        path: path,
        defaultValue: customBlueprint.defaultValue(),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r"[\dwdhminsu ]")),
        ],
        icon: TWIcons.stopwatch,
        deserialize: (value) {
          final parsedValue = value.milliseconds;
          return prettyDuration(
            parsedValue,
            abbreviated: true,
            delimiter: " ",
            spacer: "",
            tersity: DurationTersity.millisecond,
          );
        },
        serialize: (value) {
          final parsedValue = parseDuration(value, separator: " ");
          return parsedValue.inMilliseconds;
        },
        formatted: (value) {
          final parsedValue = value.milliseconds;
          final formatted = prettyDuration(
            parsedValue,
            abbreviated: false,
            tersity: DurationTersity.millisecond,
          );
          return l10n.validDuration(formatted);
        },
      ),
    );
  }
}
