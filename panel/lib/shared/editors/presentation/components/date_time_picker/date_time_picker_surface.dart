import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class DateTimePickerSurface extends StatelessWidget {
  const DateTimePickerSurface({
    required this.value,
    required this.includeDate,
    required this.includeTime,
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  final DateTime value;
  final bool includeDate;
  final bool includeTime;
  final bool enabled;
  final ValueChanged<DateTime> onChanged;

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
