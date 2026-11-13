import "package:typewriter_panel/typewriter_panel.dart";

/// Shows the panel's one dialog, with Typewriter's provider, responsive and
/// keyboard context: it arrives with dialogIn, leaves with dialogOut, and
/// the page behind sinks back while it is open. The returned future carries
/// the route result, or null when no result was supplied.
Future<T?> showAdvancedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  // Read once: the dialog outlives [context] while it closes, such as when
  // the dialog's action removed the resource it was opened from.
  final container = ProviderScope.containerOf(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  return navigator.push(
    MotionDialogRoute<T>(
      arrive: motionTimeline(context, MotionToken.dialogIn),
      leave: motionTimeline(context, MotionToken.dialogOut),
      originScale: context.motion
          .spec(MotionToken.dialogIn)
          .landing
          .originScale,
      sinksPage: true,
      barrierDismissible: barrierDismissible,
      barrierLabel: "Close dialog",
      barrierColor: context.colors.scrim,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      builder: (_) => SafeArea(
        child: UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, child) => Shortcuts(
              shortcuts: typewriterShortcuts,
              child: GlobalModeShortcut(
                child: ManagedActionSet(
                  shortcuts: ref.watch(dialogShortcutsProvider),
                  child: Responsive(child: builder(context)),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The panel's one bottom sheet, a [PanelSheetRoute] with the caller's
/// provider scope.
extension PanelSheet on BuildContext {
  Future<T?> showPanelSheet<T>(WidgetBuilder builder) {
    final container = ProviderScope.containerOf(this);
    final navigator = Navigator.of(this);
    return navigator.push(
      PanelSheetRoute<T>(
        arrive: motionTimeline(this, MotionToken.surfaceIn),
        leave: motionTimeline(this, MotionToken.panelOut),
        barrierColor: colors.scrim,
        themes: InheritedTheme.capture(from: this, to: navigator.context),
        builder: (sheetContext) => UncontrolledProviderScope(
          container: container,
          child: builder(sheetContext),
        ),
      ),
    );
  }
}
