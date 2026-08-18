import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

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
      label: semanticCalendarDate(date),
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

DateTime dateOnly(DateTime value) =>
    DateTime.utc(value.year, value.month, value.day);

bool sameCalendarDate(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

String semanticCalendarDate(DateTime value) =>
    "${calendarWeekdayNames[value.weekday - 1]}, "
    "${calendarMonthNames[value.month - 1]} ${value.day}, ${value.year}";
