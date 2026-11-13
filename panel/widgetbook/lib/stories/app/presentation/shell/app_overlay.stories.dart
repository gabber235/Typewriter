import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/shared/shell.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The [AppOverlay] that holds the panel's body: the tooltip, the sheet and
/// the popups a page opens all rise inside it and keep their focus while
/// the body rebuilds. Hover Details or press Open sheet.
@widgetbook.UseCase(name: "Layers above a page", type: AppOverlay)
Widget appOverlayUseCase(BuildContext context) {
  return Story([
    signedIn(ada, organization: acme),
  ], at: const PanelLocation.component(_OverlayLayers()));
}

class _OverlayLayers extends StatelessWidget {
  const _OverlayLayers();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: context.spacing.space2,
      children: [
        PanelTooltip(
          message: "Tooltips rise in the app overlay",
          triggerMode: TooltipTriggerMode.tap,
          child: Button(label: "Details", onPressed: () {}),
        ),
        Button(
          label: "Open sheet",
          autofocus: true,
          onPressed: () =>
              context.showPanelSheet<void>((_) => const StorySidebarContent()),
        ),
      ],
    );
  }
}
