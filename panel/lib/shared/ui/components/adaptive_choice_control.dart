import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class AdaptiveChoiceControl<T extends Object> extends StatelessWidget {
  const AdaptiveChoiceControl({
    required this.choices,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
    super.key,
  });

  final Map<T, String> choices;
  final T? selected;
  final ValueChanged<T?> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (choices.isEmpty) {
      return Semantics(
        enabled: false,
        child: InputDecorator(
          decoration: const InputDecoration(enabled: false),
          child: Text(
            "No options available",
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: context.colors.contentSecondary,
            ),
          ),
        ),
      );
    }
    final selected = choices.containsKey(this.selected) ? this.selected : null;
    if (choices.length < 2 || choices.length > 3) {
      return Dropdown<T>(
        selected: selected,
        dropdownMenuEntries: [
          for (final MapEntry(key: value, value: label) in choices.entries)
            DropdownMenuEntry(value: value, label: label),
        ],
        enabled: enabled,
        onSelected: onSelected,
      );
    }

    return CupertinoSlidingSegmentedControl<T>(
      groupValue: selected,
      backgroundColor:
          Theme.of(context).inputDecorationTheme.fillColor ??
          context.colors.surfaceContainer,
      thumbColor: context.colors.selectionContainer,
      disabledChildren: enabled ? const {} : choices.keys.toSet(),
      children: {
        for (final MapEntry(key: value, value: label) in choices.entries)
          value: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing.space2,
              vertical: context.spacing.space1,
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: value == selected
                    ? context.colors.onSelectionContainer
                    : context.colors.contentSecondary,
              ),
            ),
          ),
      },
      onValueChanged: onSelected,
    );
  }
}
