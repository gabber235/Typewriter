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
    this.showPicker = true,
    this.minimum,
    this.maximum,
    this.timeIncrementMilliseconds,
    this.popupPadding,
    this.popupColor,
    this.popupShape,
    this.decoration,
    this.style,
    this.textAlign = TextAlign.start,
    this.selectAllOnFocus = false,
    this.showDefaultIcon = true,
    this.statesController,
    this.onCommittedDone,
    this.onPickerCommitted,
    this.display,
    this.validator,
    this.overlayConfig,
    this.popupConstraints,
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
    this.showPicker = true,
    this.minimum,
    this.maximum,
    this.timeIncrementMilliseconds,
    this.popupPadding,
    this.popupColor,
    this.popupShape,
    this.decoration,
    this.style,
    this.textAlign = TextAlign.start,
    this.selectAllOnFocus = false,
    this.showDefaultIcon = true,
    this.statesController,
    this.onCommittedDone,
    this.onPickerCommitted,
    this.display,
    this.validator,
    this.overlayConfig,
    this.popupConstraints,
    this.enabled = true,
    this.readOnly = false,
    super.key,
  }) : value = null,
       mixed = true;

  final bool showPicker;
  final DateTime? minimum;
  final DateTime? maximum;
  final int? timeIncrementMilliseconds;
  final EdgeInsetsGeometry? popupPadding;
  final Color? popupColor;
  final ShapeBorder? popupShape;
  final InputDecoration? decoration;
  final TextStyle? style;
  final TextAlign textAlign;
  final bool selectAllOnFocus;
  final bool showDefaultIcon;
  final WidgetStatesController? statesController;
  final ValueChanged<TextEditingValue>? onCommittedDone;
  final ValueChanged<DateTime>? onPickerCommitted;
  final String Function(DateTime)? display;
  final String? Function(DateTime)? validator;
  final AnchoredOverlayConfig? overlayConfig;
  final BoxConstraints? popupConstraints;
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
    final pickerCandidate = useRef(value);
    void updatePicker(DateTime next) {
      pickerCandidate.value = next;
      onChanged(next);
    }

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
      final candidate = pickerCandidate.value;
      if (candidate != null) onPickerCommitted?.call(candidate);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (pickerFocus.canRequestFocus) pickerFocus.requestFocus();
      });
    }

    void toggle() {
      if (!enabled || !showPicker) return;
      if (open.value) {
        close();
        return;
      }
      pickerCandidate.value = value;
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
        config:
            overlayConfig ??
            const AnchoredOverlayConfig(
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
                  width: popupConstraints?.constrainWidth(372) ?? 372,
                  child: DateTimePickerSurface(
                    value: pickerValue,
                    minimum: minimum,
                    maximum: maximum,
                    timeIncrementMilliseconds: timeIncrementMilliseconds,
                    popupPadding: popupPadding,
                    popupColor: popupColor,
                    popupShape: popupShape,
                    includeDate: includeDate,
                    includeTime: includeTime,
                    enabled: editable,
                    replacing: mixed,
                    onChanged: updatePicker,
                  ),
                ),
              ),
            ),
          ),
        ),
        child: ValidatedTextField<DateTime>(
          showDefaultIcon: showDefaultIcon,
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
          enabled: enabled,
          style: style,
          textAlign: textAlign,
          selectAllOnFocus: selectAllOnFocus,
          statesController: statesController,
          onCommittedDone: onCommittedDone,
          display: display,
          validator: validator,
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
            if (enabled && showPicker)
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
          decoration: (decoration ?? const InputDecoration()).copyWith(
            hintText: mixed
                ? "Multiple values"
                : decoration?.hintText ?? format,
            helperText: !mixed && currentValue == null
                ? "This value is Unfilled"
                : null,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (decoration?.suffixIcon != null) decoration!.suffixIcon!,
                if (!readOnly && showPicker)
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
