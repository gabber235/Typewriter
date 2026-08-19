import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class DateTimeCalendar extends StatefulWidget {
  const DateTimeCalendar({
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.autofocus = false,
    super.key,
  });

  final DateTime value;
  final bool enabled;
  final ValueChanged<DateTime> onChanged;
  final bool autofocus;

  @override
  State<DateTimeCalendar> createState() => _DateTimeCalendarState();
}

class _DateTimeCalendarState extends State<DateTimeCalendar> {
  static const _weekdays = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"];

  late DateTime _focusedDate;
  late DateTime _visibleMonth;
  DateTimeCalendarView _view = DateTimeCalendarView.days;

  @override
  void initState() {
    super.initState();
    _focusedDate = dateOnly(widget.value);
    _visibleMonth = DateTime.utc(widget.value.year, widget.value.month);
  }

  @override
  void didUpdateWidget(covariant DateTimeCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!sameCalendarDate(oldWidget.value, widget.value)) {
      _focusedDate = dateOnly(widget.value);
      _visibleMonth = DateTime.utc(widget.value.year, widget.value.month);
    }
  }

  void _focus(DateTime next) {
    setState(() {
      _focusedDate = next;
      _visibleMonth = DateTime.utc(next.year, next.month);
    });
  }

  void _moveMonth(int delta) => _focus(moveMonth(_focusedDate, delta));

  void _selectMonth(int month) {
    _focus(
      DateTime.utc(
        _focusedDate.year,
        month,
        _focusedDate.day.clamp(1, daysInMonth(_focusedDate.year, month)),
      ),
    );
  }

  void _selectYear(int year) {
    _focus(
      DateTime.utc(
        year,
        _focusedDate.month,
        _focusedDate.day.clamp(1, daysInMonth(year, _focusedDate.month)),
      ),
    );
  }

  void _toggleMonthPicker() {
    setState(() {
      _view = _view == DateTimeCalendarView.months
          ? DateTimeCalendarView.days
          : DateTimeCalendarView.months;
    });
  }

  void _toggleYearPicker() {
    setState(() {
      _view = _view == DateTimeCalendarView.years
          ? DateTimeCalendarView.days
          : DateTimeCalendarView.years;
    });
  }

  void _stepHeader(int delta) {
    switch (_view) {
      case DateTimeCalendarView.days:
        _moveMonth(delta);
      case DateTimeCalendarView.months:
        _selectYear(_focusedDate.year + delta);
      case DateTimeCalendarView.years:
        _selectYear((_focusedDate.year + delta * 16).clamp(1, 9999));
    }
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft) {
      _focus(_focusedDate.subtract(const Duration(days: 1)));
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _focus(_focusedDate.add(const Duration(days: 1)));
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _focus(_focusedDate.subtract(const Duration(days: 7)));
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _focus(_focusedDate.add(const Duration(days: 7)));
    } else if (key == LogicalKeyboardKey.home) {
      _focus(DateTime.utc(_focusedDate.year, _focusedDate.month));
    } else if (key == LogicalKeyboardKey.end) {
      _focus(
        DateTime.utc(
          _focusedDate.year,
          _focusedDate.month,
          daysInMonth(_focusedDate.year, _focusedDate.month),
        ),
      );
    } else if (key == LogicalKeyboardKey.pageUp) {
      _moveMonth(HardwareKeyboard.instance.isShiftPressed ? -12 : -1);
    } else if (key == LogicalKeyboardKey.pageDown) {
      _moveMonth(HardwareKeyboard.instance.isShiftPressed ? 12 : 1);
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space) {
      if (widget.enabled) widget.onChanged(_focusedDate);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DateTimeCalendarHeader(
          visibleMonth: _visibleMonth,
          view: _view,
          onPrevious: () => _stepHeader(-1),
          onNext: () => _stepHeader(1),
          onMonthPickerRequested: _toggleMonthPicker,
          onYearPickerRequested: _toggleYearPicker,
        ),
        SizedBox(height: context.spacing.space1),
        switch (_view) {
          DateTimeCalendarView.days => _buildDays(context),
          DateTimeCalendarView.months => _buildMonths(),
          DateTimeCalendarView.years => _buildYears(),
        },
      ],
    );
  }

  Widget _buildMonths() => DateTimeCalendarSelectionGrid(
    label: "Choose month",
    items: [
      for (var index = 0; index < calendarMonthNames.length; index++)
        (value: index + 1, label: calendarMonthNames[index]),
    ],
    selectedValue: _visibleMonth.month,
    columns: 3,
    onSelected: (month) {
      _selectMonth(month);
      setState(() => _view = DateTimeCalendarView.days);
    },
  );

  Widget _buildYears() {
    final startYear = ((_visibleMonth.year - 1) ~/ 16) * 16 + 1;
    return DateTimeCalendarSelectionGrid(
      label: "Choose year",
      items: [
        for (var year = startYear; year < startYear + 16; year++)
          (value: year, label: "$year"),
      ],
      selectedValue: _visibleMonth.year,
      columns: 4,
      onSelected: (year) {
        _selectYear(year);
        setState(() => _view = DateTimeCalendarView.days);
      },
    );
  }

  Widget _buildDays(BuildContext context) {
    final first = DateTime.utc(_visibleMonth.year, _visibleMonth.month);
    final gridStart = first.subtract(Duration(days: first.weekday - 1));
    return Column(
      children: [
        Row(
          children: [
            for (final weekday in _weekdays)
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    weekday,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
          ],
        ),
        Focus(
          autofocus: widget.autofocus,
          onKeyEvent: _handleKey,
          child: Builder(
            builder: (context) {
              final focused = Focus.of(context).hasFocus;
              return Semantics(
                focusable: true,
                focused: focused,
                label: "Calendar date",
                value: semanticCalendarDate(_focusedDate),
                hint: widget.enabled
                    ? "Use arrow keys to move and Enter to select"
                    : "Use arrow keys to inspect dates",
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  decoration: BoxDecoration(
                    borderRadius: context.shapes.smallBorderRadius,
                    border: Border.all(
                      color: focused
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Column(
                    children: [
                      for (var week = 0; week < 6; week++)
                        Row(
                          children: [
                            for (var day = 0; day < 7; day++)
                              Expanded(
                                child: DateTimeDayCell(
                                  date: gridStart.add(
                                    Duration(days: week * 7 + day),
                                  ),
                                  selected: sameCalendarDate(
                                    gridStart.add(
                                      Duration(days: week * 7 + day),
                                    ),
                                    widget.value,
                                  ),
                                  focused: sameCalendarDate(
                                    gridStart.add(
                                      Duration(days: week * 7 + day),
                                    ),
                                    _focusedDate,
                                  ),
                                  inMonth:
                                      gridStart
                                          .add(Duration(days: week * 7 + day))
                                          .month ==
                                      _visibleMonth.month,
                                  enabled: widget.enabled,
                                  onPressed: _focusAndSelect,
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _focusAndSelect(DateTime date) {
    _focus(date);
    widget.onChanged(date);
  }
}
