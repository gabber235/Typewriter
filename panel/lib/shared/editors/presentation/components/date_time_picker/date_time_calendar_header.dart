import "package:flutter/material.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class DateTimeCalendarHeader extends StatelessWidget {
  const DateTimeCalendarHeader({
    required this.visibleMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onMonthSelected,
    required this.onYearSelected,
    super.key,
  });

  static const months = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ];

  final DateTime visibleMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<int> onMonthSelected;
  final ValueChanged<int> onYearSelected;

  @override
  Widget build(BuildContext context) {
    final startYear = (visibleMonth.year - 100).clamp(1, 9999);
    final endYear = (visibleMonth.year + 100).clamp(1, 9999);
    final decoration = InputDecorationTheme(
      filled: true,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      constraints: const BoxConstraints.tightFor(height: 36),
      border: OutlineInputBorder(
        borderRadius: context.shapes.smallBorderRadius,
        borderSide: BorderSide.none,
      ),
    );

    return Semantics(
      container: true,
      label: "Calendar month and year",
      child: Row(
        children: [
          _MonthStepButton(
            tooltip: "Previous month",
            icon: MaterialSymbols.chevron_left_rounded,
            onPressed: onPreviousMonth,
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 3,
            child: Dropdown<int>(
              key: const ValueKey("date_time_month_picker"),
              selected: visibleMonth.month,
              dropdownMenuEntries: [
                for (var index = 0; index < months.length; index++)
                  DropdownMenuEntry(value: index + 1, label: months[index]),
              ],
              inputDecorationTheme: decoration,
              menuStyle: const MenuStyle(
                maximumSize: WidgetStatePropertyAll(Size.fromHeight(320)),
              ),
              onSelected: (month) {
                if (month != null) onMonthSelected(month);
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: Dropdown<int>(
              key: const ValueKey("date_time_year_picker"),
              selected: visibleMonth.year,
              dropdownMenuEntries: [
                for (var year = startYear; year <= endYear; year++)
                  DropdownMenuEntry(value: year, label: "$year"),
              ],
              inputDecorationTheme: decoration,
              menuStyle: const MenuStyle(
                maximumSize: WidgetStatePropertyAll(Size.fromHeight(320)),
              ),
              onSelected: (year) {
                if (year != null) onYearSelected(year);
              },
            ),
          ),
          const SizedBox(width: 4),
          _MonthStepButton(
            tooltip: "Next month",
            icon: MaterialSymbols.chevron_right_rounded,
            onPressed: onNextMonth,
          ),
        ],
      ),
    );
  }
}

class _MonthStepButton extends StatelessWidget {
  const _MonthStepButton({
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
