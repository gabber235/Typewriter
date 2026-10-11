import "package:typewriter_panel/typewriter_panel.dart";

/// Chooses a compact selection control based on the number of available choices.
///
/// One choice or more than three choices use [Dropdown], while two or three
/// choices use a segmented control. Selection initialization remains delegated
/// to [SelectionInitialization], and the caller owns the selected value.
class AdaptiveChoiceControl<T extends Object> extends StatelessWidget {
  const AdaptiveChoiceControl({
    required this.choices,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
    this.defaultValue,
    this.initialization = SelectionInitializationPolicy.automatic,
    super.key,
  });

  final Map<T, String> choices;
  final T? selected;
  final ValueChanged<T?> onSelected;
  final bool enabled;
  final T? defaultValue;
  final SelectionInitializationPolicy initialization;

  @override
  Widget build(BuildContext context) {
    if (choices.isEmpty) {
      return Semantics(
        enabled: false,
        child: InputDecorator(
          decoration: const InputDecoration(enabled: false),
          child: Text(
            "No options available",
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: context.colors.contentSecondary),
          ),
        ),
      );
    }
    final selected = choices.containsKey(this.selected) ? this.selected : null;
    if (choices.length < 2 || choices.length > 3) {
      return Dropdown<T>(
        selected: this.selected,
        defaultValue: defaultValue,
        dropdownMenuEntries: [
          for (final MapEntry(key: value, value: label) in choices.entries)
            DropdownMenuEntry(value: value, label: label),
        ],
        enabled: enabled,
        initialization: initialization,
        onSelected: onSelected,
      );
    }

    return SelectionInitialization<T>(
      selected: this.selected,
      defaultValue: defaultValue,
      choices: choices.keys,
      enabled: enabled,
      policy: initialization,
      onSelected: onSelected,
      child: CupertinoSlidingSegmentedControl<T>(
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
      ),
    );
  }
}
