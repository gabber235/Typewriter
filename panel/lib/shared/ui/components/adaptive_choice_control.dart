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
      child: SlidingChoiceControl<T>(
        selected: selected,
        enabled: enabled,
        children: {
          for (final MapEntry(key: value, value: label) in choices.entries)
            value: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: value == selected
                    ? context.colors.onSelectionContainer
                    : context.colors.contentSecondary,
              ),
            ),
        },
        onSelected: onSelected,
      ),
    );
  }
}

/// A sliding choice surface shared by authored and local controls.
///
/// The caller owns selection and child content. Disabled values remain visible
/// and selected values stay representable when their availability changes.
class SlidingChoiceControl<T extends Object> extends StatelessWidget {
  const SlidingChoiceControl({
    required this.children,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
    this.disabled = const {},
    this.padding,
    this.backgroundColor,
    super.key,
  });

  final Map<T, Widget> children;
  final T? selected;
  final ValueChanged<T?> onSelected;
  final bool enabled;
  final Set<T> disabled;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final selected = children.containsKey(this.selected) ? this.selected : null;
    final contentPadding =
        padding ??
        EdgeInsets.symmetric(
          horizontal: context.spacing.space2,
          vertical: context.spacing.space1,
        );
    if (children.length < 2) {
      final entry = children.entries.firstOrNull;
      return TextButton(
        onPressed: entry != null && enabled && !disabled.contains(entry.key)
            ? () => onSelected(entry.key)
            : null,
        child: entry?.value ?? const Text("No options available"),
      );
    }
    return CupertinoSlidingSegmentedControl<T>(
      groupValue: selected,
      backgroundColor:
          backgroundColor ??
          Theme.of(context).inputDecorationTheme.fillColor ??
          context.colors.surfaceContainer,
      thumbColor: context.colors.selectionContainer,
      disabledChildren: enabled ? disabled : children.keys.toSet(),
      children: {
        for (final entry in children.entries)
          entry.key: Padding(padding: contentPadding, child: entry.value),
      },
      onValueChanged: (value) {
        if (enabled && value != null && !disabled.contains(value)) {
          onSelected(value);
        }
      },
    );
  }
}
