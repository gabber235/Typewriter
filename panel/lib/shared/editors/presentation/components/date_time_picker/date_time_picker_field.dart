import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class DateTimePickerField extends HookConsumerWidget {
  const DateTimePickerField({
    required this.value,
    required this.includeDate,
    required this.includeTime,
    required this.onChanged,
    this.enabled = true,
    this.readOnly = false,
    super.key,
  });

  final DateTime value;
  final bool includeDate;
  final bool includeTime;
  final ValueChanged<DateTime> onChanged;
  final bool enabled;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = useState(false);
    final pickerFocus = useFocusNode(debugLabel: "Open date and time picker");
    final pickerScope = useMemoized(
      () => FocusScopeNode(
        debugLabel: "Date and time picker",
        traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
      ),
    );
    useEffect(() => pickerScope.dispose, [pickerScope]);
    final tapGroup = useMemoized(Object.new);
    final editable = enabled && !readOnly;
    final format = dateTimeEditorFormat(
      includeDate: includeDate,
      includeTime: includeTime,
    );

    void close() {
      if (!open.value) return;
      open.value = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (pickerFocus.canRequestFocus) pickerFocus.requestFocus();
      });
    }

    void toggle() {
      if (!enabled) return;
      if (open.value) {
        close();
        return;
      }
      open.value = true;
    }

    Future<void> copyValue() => Clipboard.setData(
      ClipboardData(
        text: formatDateTimeEditorValue(
          value,
          includeDate: includeDate,
          includeTime: includeTime,
        ),
      ),
    );

    return TapRegion(
      groupId: tapGroup,
      onTapOutside: (_) => close(),
      child: AnchoredOverlayPortal(
        visible: open.value,
        config: const AnchoredOverlayConfig(
          preferredSide: AnchoredOverlaySide.bottom,
          spacing: 6,
          sharedAxisConstraintMode: SharedAxisConstraintMode.none,
          maxWidth: 372,
          maxHeight: 610,
        ),
        overlayBuilder: (context, anchorSize) => TapRegion(
          groupId: tapGroup,
          child: Actions(
            actions: {
              DismissIntent: CallbackAction<DismissIntent>(
                onInvoke: (intent) {
                  close();
                  return null;
                },
              ),
            },
            child: CallbackShortcuts(
              bindings: {
                AdaptiveSingleActivator(LogicalKeyboardKey.keyP): toggle,
              },
              child: FocusScope(
                node: pickerScope,
                child: SizedBox(
                  width: 372,
                  child: DateTimePickerSurface(
                    value: value,
                    includeDate: includeDate,
                    includeTime: includeTime,
                    enabled: editable,
                    onChanged: onChanged,
                  ),
                ),
              ),
            ),
          ),
        ),
        child: ValidatedTextField<DateTime>(
          value: value,
          name: includeDate && includeTime
              ? "date and time"
              : includeDate
              ? "date"
              : "time",
          icon: includeDate
              ? MaterialSymbols.calendar_month_rounded
              : MaterialSymbols.schedule_rounded,
          readOnly: !editable,
          deserialize: (value) => formatDateTimeEditorValue(
            value,
            includeDate: includeDate,
            includeTime: includeTime,
          ),
          serialize: (draft) => parseDateTimeEditorValue(
            draft,
            current: value,
            includeDate: includeDate,
            includeTime: includeTime,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp("[0-9: -]")),
            LengthLimitingTextInputFormatter(format.length),
          ],
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
          onChanged: onChanged,
          surroundingActions: [
            if (enabled)
              ActionShortcut(
                id: "date_time_copy",
                label: "Copy Value",
                description: "Copy the visible date and time value",
                activators: [
                  AdaptiveSingleActivator(
                    LogicalKeyboardKey.keyC,
                    control: true,
                  ),
                ],
                priority: 1000,
                onInvoke: (_) => copyValue(),
              ),
            if (enabled)
              ActionShortcut(
                id: "date_time_toggle_picker",
                label: open.value ? "Close Picker" : "Open Picker",
                description: open.value
                    ? "Close the date and time picker"
                    : "Open the date and time picker",
                activators: [AdaptiveSingleActivator(LogicalKeyboardKey.keyP)],
                priority: 1001,
                onInvoke: (_) => toggle(),
              ),
          ],
          decoration: InputDecoration(
            hintText: format,
            suffixIcon: readOnly
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        focusNode: pickerFocus,
                        tooltip: open.value ? "Close picker" : "Open picker",
                        constraints: const BoxConstraints.tightFor(
                          width: 30,
                          height: 36,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: enabled ? toggle : null,
                        icon: Icones(
                          includeDate
                              ? MaterialSymbols.calendar_month_rounded
                              : MaterialSymbols.schedule_rounded,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
