import "package:flutter/material.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/typewriter_panel.dart";

enum DateTimeCalendarView { days, months, years }

class DateTimeCalendarHeader extends StatelessWidget {
  const DateTimeCalendarHeader({
    required this.visibleMonth,
    required this.view,
    required this.onPrevious,
    required this.onNext,
    required this.onMonthPickerRequested,
    required this.onYearPickerRequested,
    super.key,
  });

  final DateTime visibleMonth;
  final DateTimeCalendarView view;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onMonthPickerRequested;
  final VoidCallback onYearPickerRequested;

  String get _previousTooltip => switch (view) {
    DateTimeCalendarView.days => "Previous month",
    DateTimeCalendarView.months => "Previous year",
    DateTimeCalendarView.years => "Previous group of years",
  };

  String get _nextTooltip => switch (view) {
    DateTimeCalendarView.days => "Next month",
    DateTimeCalendarView.months => "Next year",
    DateTimeCalendarView.years => "Next group of years",
  };

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: "Calendar month and year",
    child: Row(
      children: [
        _StepButton(
          tooltip: _previousTooltip,
          icon: MaterialSymbols.chevron_left_rounded,
          onPressed: onPrevious,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: _PickerButton(
                  key: const ValueKey("date_time_month_picker"),
                  label: calendarMonthNames[visibleMonth.month - 1],
                  selected: view == DateTimeCalendarView.months,
                  onPressed: onMonthPickerRequested,
                ),
              ),
              const SizedBox(width: 4),
              _PickerButton(
                key: const ValueKey("date_time_year_picker"),
                label: "${visibleMonth.year}",
                selected: view == DateTimeCalendarView.years,
                onPressed: onYearPickerRequested,
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        _StepButton(
          tooltip: _nextTooltip,
          icon: MaterialSymbols.chevron_right_rounded,
          onPressed: onNext,
        ),
      ],
    ),
  );
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.label,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    style: TextButton.styleFrom(
      minimumSize: const Size(0, 36),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      backgroundColor: selected
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
    ),
    onPressed: onPressed,
    iconAlignment: IconAlignment.end,
    icon: const Icones(MaterialSymbols.arrow_drop_down_rounded, size: 16),
    label: Text(label, overflow: TextOverflow.ellipsis),
  );
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final String icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    constraints: const BoxConstraints.tightFor(width: 32, height: 36),
    padding: EdgeInsets.zero,
    onPressed: onPressed,
    icon: Icones(icon, size: 18),
  );
}
