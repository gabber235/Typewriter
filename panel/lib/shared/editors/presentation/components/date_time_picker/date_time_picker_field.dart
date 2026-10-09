import "package:typewriter_panel/typewriter_panel.dart";

/// Edits one date, one time, or one date and time value.
///
/// The parent owns [value] and receives valid updates through [onChanged].
/// This field owns picker visibility and delegates interaction boundaries to
/// the surrounding editor. Opening starts an interaction, ordinary dismissal
/// commits it. The picker uses the current value, or a stable day seed,
/// while [mixed] communicates that the first selection replaces several
/// differing values. Supply [onCleared] to allow empty text to remove the value.
class DateTimePickerField extends HookConsumerWidget {
  const DateTimePickerField({
    required this.value,
    required this.includeDate,
    required this.includeTime,
    required this.onChanged,
    this.onCleared,
    this.onInteractionStart,
    this.onInteractionCommit,
    this.enabled = true,
    this.readOnly = false,
    super.key,
  }) : mixed = false;

  const DateTimePickerField.mixed({
    required this.includeDate,
    required this.includeTime,
    required this.onChanged,
    this.onCleared,
    this.onInteractionStart,
    this.onInteractionCommit,
    this.enabled = true,
    this.readOnly = false,
    super.key,
  }) : value = null,
       mixed = true;

  final DateTime? value;

  /// Whether selected owners disagree, independently of an empty timestamp.
  final bool mixed;
  final bool includeDate;
  final bool includeTime;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback? onCleared;
  final VoidCallback? onInteractionStart;
  final VoidCallback? onInteractionCommit;
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
    final replacementSeed = useMemoized(() {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day);
    });

    final editable = enabled && !readOnly;
    final currentValue = value;
    final pickerValue = currentValue ?? replacementSeed;
    final format = dateTimeEditorFormat(
      includeDate: includeDate,
      includeTime: includeTime,
    );

    void close() {
      if (!open.value) return;
      open.value = false;
      onInteractionCommit?.call();
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
      onInteractionStart?.call();
      open.value = true;
    }

    Future<void> copyValue() {
      if (currentValue == null) return Future.value();
      return Clipboard.setData(
        ClipboardData(
          text: currentValue.toEditorText(
            includeDate: includeDate,
            includeTime: includeTime,
          ),
        ),
      );
    }

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
              CancelIntent: CallbackAction<CancelIntent>(
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
                    value: pickerValue,
                    includeDate: includeDate,
                    includeTime: includeTime,
                    enabled: editable,
                    replacing: mixed,
                    onChanged: onChanged,
                  ),
                ),
              ),
            ),
          ),
        ),
        child: ValidatedTextField<DateTime>(
          value: currentValue,
          mixed: mixed,
          name: includeDate && includeTime
              ? "date and time"
              : includeDate
              ? "date"
              : "time",
          icon: includeDate
              ? MaterialSymbols.calendar_month_rounded
              : MaterialSymbols.schedule_rounded,
          readOnly: !editable,
          deserialize: (value) => value.toEditorText(
            includeDate: includeDate,
            includeTime: includeTime,
          ),
          serialize: (draft) => draft.parseEditorDateTime(
            current: pickerValue,
            includeDate: includeDate,
            includeTime: includeTime,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp("[0-9: -]")),
            LengthLimitingTextInputFormatter(format.length),
          ],
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
          onChanged: onChanged,
          onCleared: onCleared,
          onInputFocus: onInteractionStart,
          onInputBlur: onInteractionCommit,
          surroundingActions: [
            if (enabled && currentValue != null)
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
            hintText: mixed ? "Multiple values" : format,
            helperText: !mixed && currentValue == null
                ? "This value is Unfilled"
                : null,
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
