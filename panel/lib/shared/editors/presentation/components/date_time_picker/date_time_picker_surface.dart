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
    this.minimum,
    this.maximum,
    this.timeIncrementMilliseconds,
    this.popupPadding,
    this.popupColor,
    this.popupShape,
    super.key,
  });

  final DateTime? minimum;
  final DateTime? maximum;
  final int? timeIncrementMilliseconds;
  final EdgeInsetsGeometry? popupPadding;
  final Color? popupColor;
  final ShapeBorder? popupShape;
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
      color: popupColor ?? Theme.of(context).colorScheme.surface,
      shape: popupShape,
      borderRadius: popupShape == null
          ? context.shapes.mediumBorderRadius
          : null,
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: "Date and time picker",
        child: Padding(
          padding: popupPadding ?? EdgeInsets.all(context.spacing.space2),
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
                  selectableDate: (date) {
                    final candidate = value.withDate(date);
                    return (minimum == null || !candidate.isBefore(minimum!)) &&
                        (maximum == null || !candidate.isAfter(maximum!));
                  },
                  enabled: enabled,
                  autofocus: true,
                  onChanged: (date) => onChanged(value.withDate(date)),
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
                  onChanged: (candidate) {
                    if ((minimum == null || !candidate.isBefore(minimum!)) &&
                        (maximum == null || !candidate.isAfter(maximum!))) {
                      onChanged(candidate);
                    }
                  },
                ),
              if (includeTime && timeIncrementMilliseconds != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final direction in [-1, 1])
                      IconButton(
                        tooltip: direction < 0
                            ? "Decrease time"
                            : "Increase time",
                        onPressed: enabled
                            ? () {
                                final milliseconds =
                                    BigInt.from(value.millisecondsSinceEpoch) +
                                    BigInt.from(timeIncrementMilliseconds!) *
                                        BigInt.from(direction);
                                final limit = BigInt.from(8640000000000000);
                                if (milliseconds < -limit ||
                                    milliseconds > limit) {
                                  return;
                                }
                                final candidate =
                                    DateTime.fromMillisecondsSinceEpoch(
                                      milliseconds.toInt(),
                                      isUtc: value.isUtc,
                                    );
                                if ((minimum == null ||
                                        !candidate.isBefore(minimum!)) &&
                                    (maximum == null ||
                                        !candidate.isAfter(maximum!))) {
                                  onChanged(candidate);
                                }
                              }
                            : null,
                        icon: Icon(direction < 0 ? Icons.remove : Icons.add),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
