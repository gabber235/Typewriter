import "package:duration/duration.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:iconify_flutter_plus/icons/bi.dart";
import "package:typewriter_panel/app/presentation/shortcuts/action_shortcuts.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/presentation/preset_chip.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/presentation/validated_text_field.dart";
import "package:typewriter_panel/shared/utilities/context.dart";

class DurationInput extends HookWidget {
  const DurationInput({
    required this.duration,
    required this.onDurationChanged,
    super.key,
  });

  final Duration duration;
  final ValueChanged<Duration> onDurationChanged;

  static const _presetDurations = [
    Duration(hours: 1),
    Duration(days: 1),
    Duration(days: 7),
    Duration(days: 30),
  ];

  Widget _presets() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final duration in _presetDurations)
          PresetChip(
            label: prettify(duration),
            isSelected: duration == this.duration,
            onTap: () => onDurationChanged(duration),
          ),
      ],
    );
  }

  String prettify(Duration duration) {
    return prettyDuration(
      duration,
      abbreviated: true,
      delimiter: " ",
      spacer: "",
      tersity: DurationTersity.hour,
      upperTersity: DurationTersity.day,
    );
  }

  @override
  Widget build(BuildContext context) {
    final inlinePresets = context.responsive(mobile: false, tablet: true);

    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!inlinePresets) _presets(),
        ValidatedTextField<Duration>(
          value: duration,
          name: "Expiration period",
          icon: Bi.stopwatch_fill,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r"[\dwdhminsu ]")),
          ],
          decoration: InputDecoration(
            suffix: inlinePresets ? _presets() : null,
          ),
          surroundingActions: [
            for (final (index, duration) in _presetDurations.indexed)
              ActionShortcut(
                id: "preset-duration-$index",
                label: "Preset ${prettify(duration)}",
                description: "Set experation to ${prettify(duration)}",
                activators: [
                  SingleActivator(
                    LogicalKeyboardKey(LogicalKeyboardKey.digit1.keyId + index),
                  ),
                  SingleActivator(
                    LogicalKeyboardKey(
                      LogicalKeyboardKey.numpad1.keyId + index,
                    ),
                  ),
                ],
                onInvoke: (_) => onDurationChanged(duration),
                priority: 10,
              ),
          ],
          deserialize: prettify,
          serialize: (value) => parseDuration(value, separator: " "),
          formatted: (value) {
            final formatted = prettyDuration(
              value,
              abbreviated: false,
              tersity: DurationTersity.millisecond,
              upperTersity: DurationTersity.day,
            );
            return "Valid Duration: $formatted";
          },
          validator: (value) {
            if (value.isNegative) {
              return "Duration must be positive";
            }
            if (value.inMinutes < 60) {
              return "Duration must be at least 1 hour";
            }
            return null;
          },
          onChanged: onDurationChanged,
        ),
      ],
    );
  }
}
