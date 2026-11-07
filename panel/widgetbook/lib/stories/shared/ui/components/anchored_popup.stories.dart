import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A control whose popover grows out of it with panelIn and goes back into
/// it with panelOut; [opened] starts it focused.
class _Popover extends HookWidget {
  const _Popover({this.opened = false});

  final bool opened;

  @override
  Widget build(BuildContext context) {
    final controller = useMemoized(() {
      final controller = AnchoredPopupController();
      if (opened) controller.openFocused();
      return controller;
    });
    useEffect(() => controller.dispose, [controller]);
    return Center(
      child: AnchoredPopup(
        controller: controller,
        builder: (context, show) =>
            Button(label: "Open details", onPressed: show),
        popupBuilder: (context, close) => IntrinsicWidth(
          child: Padding(
            padding: EdgeInsets.all(context.spacing.space1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PanelMenuItem(label: "Rename", onPressed: close),
                PanelMenuItem(label: "Duplicate", onPressed: close),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Hovering the control previews the popover; pressing it focuses it.
@widgetbook.UseCase(name: "Preview on hover", type: AnchoredPopup)
Widget anchoredPopupPreviewUseCase(BuildContext context) =>
    Story(const [], at: const PanelLocation.component(_Popover()));

/// The popover open and focused: arrows move, Escape sends it back.
@widgetbook.UseCase(name: "Focused", type: AnchoredPopup)
Widget anchoredPopupFocusedUseCase(BuildContext context) =>
    Story(const [], at: const PanelLocation.component(_Popover(opened: true)));

/// Under reduced motion the popover shows and goes at once.
@widgetbook.UseCase(name: "Reduced motion", type: AnchoredPopup)
Widget anchoredPopupReducedMotionUseCase(BuildContext context) => Story(const [
  reducedMotion,
], at: const PanelLocation.component(_Popover(opened: true)));
