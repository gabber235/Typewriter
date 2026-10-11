import "package:typewriter_panel/typewriter_panel.dart";

/// Displays one selectable day in the calendar grid.
///
/// [inMonth] controls the subdued styling of overflow days. The caller owns
/// selection and focus state and receives the represented date through
/// [onPressed].
class DateTimeDayCell extends StatelessWidget {
  const DateTimeDayCell({
    required this.date,
    required this.selected,
    required this.focused,
    required this.inMonth,
    required this.enabled,
    required this.onPressed,
    super.key,
  });

  final DateTime date;
  final bool selected;
  final bool focused;
  final bool inMonth;
  final bool enabled;
  final ValueChanged<DateTime> onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: date.semanticCalendarLabel,
      onTap: enabled ? () => onPressed(date) : null,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: enabled ? () => onPressed(date) : null,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? colors.primary : null,
              border: focused && !selected
                  ? Border.all(color: colors.primary)
                  : null,
            ),
            child: Text(
              "${date.day}",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: selected
                    ? colors.onPrimary
                    : inMonth
                    ? colors.onSurface
                    : colors.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
