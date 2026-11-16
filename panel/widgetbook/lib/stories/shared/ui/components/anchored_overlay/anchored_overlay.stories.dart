import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// An [AnchoredOverlayPortal] on a button near the edge of an
/// [AnchoredOverlayScope]: the overlay starts at Side, then flips, shifts or
/// shrinks to stay inside the outlined scope. Anchor moves the button into
/// the corner where it must flip.
@widgetbook.UseCase(name: "Default", type: AnchoredOverlayPortal)
Widget anchoredOverlayPortalUseCase(BuildContext context) {
  final visible = context.knobs.boolean(label: "Visible", initialValue: true);
  final side = context.knobs.object.segmented(
    label: "Side",
    options: AnchoredOverlaySide.values,
    initialOption: AnchoredOverlaySide.bottom,
    labelBuilder: (side) => side.name,
  );
  final anchor = context.knobs.object.segmented(
    label: "Anchor",
    options: const ["Centre", "Bottom right"],
    initialOption: "Centre",
  );
  return Story(
    const [],
    at: PanelLocation.component(
      Builder(
        builder: (context) => DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: context.colors.border),
          ),
          child: SizedBox(
            width: 480,
            height: 320,
            child: AnchoredOverlayScope(
              child: Align(
                alignment: anchor == "Centre"
                    ? Alignment.center
                    : Alignment.bottomRight,
                child: AnchoredOverlayPortal(
                  visible: visible,
                  config: AnchoredOverlayConfig(
                    preferredSide: side,
                    sharedAxisConstraintMode: SharedAxisConstraintMode.none,
                    spacing: 8,
                  ),
                  overlayBuilder: (context, anchorSize) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.colors.surfaceRaised,
                      borderRadius: context.shapes.mediumBorderRadius,
                    ),
                    child: const SizedBox(
                      width: 180,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PanelRow(dense: true, title: Text("Owner")),
                          PanelRow(dense: true, title: Text("Editor")),
                          PanelRow(dense: true, title: Text("Viewer")),
                        ],
                      ),
                    ),
                  ),
                  child: Button(
                    face: ButtonFace.outlined,
                    label: "Role",
                    onPressed: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
