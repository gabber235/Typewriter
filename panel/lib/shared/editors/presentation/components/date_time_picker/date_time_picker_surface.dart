import "package:typewriter_panel/typewriter_panel.dart";

/// Groups calendar and clock controls for [DateTimePickerField].
///
/// The field remains the value owner. Calendar and time controls emit complete
/// [DateTime] values through [onChanged], preserving the unedited component so
/// callers can treat date only and time only inputs as one binding. The surface
/// does not commit or cancel an interaction; its parent decides that lifecycle.
class DateTimePickerSurface extends StatelessWidget {
  const DateTimePickerSurface({
    required this.value,
    required this.includeDate,
    required this.includeTime,
    required this.enabled,
    required this.onChanged,
    this.replacing = false,
    super.key,
  });

  final DateTime value;
  final bool includeDate;
  final bool includeTime;
  final bool enabled;
  final ValueChanged<DateTime> onChanged;
  final bool replacing;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      color: Theme.of(context).colorScheme.surface,
      borderRadius: context.shapes.mediumBorderRadius,
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: "Date and time picker",
        child: Padding(
          padding: EdgeInsets.all(context.spacing.space2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (replacing)
                Padding(
                  padding: EdgeInsets.all(context.spacing.space2),
                  child: const Text("Choose one replacement value."),
                ),
              if (includeDate)
                DateTimeCalendar(
                  value: value,
                  enabled: enabled,
                  autofocus: true,
                  onChanged: (date) => onChanged(replaceDatePart(value, date)),
                ),
              if (includeDate && includeTime)
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: context.spacing.space2,
                  ),
                  child: const Divider(height: 1),
                ),
              if (includeTime)
                DateTimeFields(
                  value: value,
                  enabled: enabled,
                  autofocus: !includeDate,
                  onChanged: onChanged,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
