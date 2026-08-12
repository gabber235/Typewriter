import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/presentation_renderer_story.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/presentation_story_support.dart";

PresentationNode _label(String id, String label) => storyNode(
  id,
  PresentationElement.badge(label: label.asStringLiteral, tone: "neutral"),
);

final layoutRendererScenarios = [
  RendererStoryScenario(
    kind: RendererStoryKind.column,
    name: "Column",
    type: const UnitType(),
    value: const UnitValue(),
    presentation: storyNode(
      "column",
      PresentationElement.column(
        spacing: 12,
        children: [_label("columnOne", "First"), _label("columnTwo", "Second")],
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.row,
    name: "Row",
    type: const UnitType(),
    value: const UnitValue(),
    presentation: storyNode(
      "row",
      PresentationElement.row(
        spacing: 12,
        children: [_label("rowOne", "First"), _label("rowTwo", "Second")],
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.wrap,
    name: "Wrap",
    type: const UnitType(),
    value: const UnitValue(),
    presentation: storyNode(
      "wrap",
      PresentationElement.wrap(
        spacing: 8,
        children: [
          _label("wrapOne", "Dialogue"),
          _label("wrapTwo", "Cinematic"),
          _label("wrapThree", "Objective"),
          _label("wrapFour", "Reward"),
        ],
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.stack,
    name: "Stack",
    type: const UnitType(),
    value: const UnitValue(),
    presentation: storyNode(
      "stack",
      PresentationElement.stack(
        children: [
          storyNode(
            "stackBackground",
            PresentationElement.progress(
              value: floatLiteral(75),
              maximum: floatLiteral(100),
            ),
          ),
          storyNode(
            "stackLabel",
            PresentationElement.text("75 percent".asStringLiteral),
          ),
        ],
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.grid,
    name: "Grid",
    type: const UnitType(),
    value: const UnitValue(),
    presentation: storyNode(
      "grid",
      PresentationElement.grid(
        columns: 2,
        horizontalSpacing: 12,
        verticalSpacing: 12,
        children: [
          _label("gridOne", "One"),
          _label("gridTwo", "Two"),
          _label("gridThree", "Three"),
          _label("gridFour", "Four"),
        ],
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.scroll,
    name: "Scroll",
    type: const UnitType(),
    value: const UnitValue(),
    presentation: storyNode(
      "scroll",
      PresentationElement.scroll(
        storyNode(
          "scrollContent",
          PresentationElement.markdown(
            List.filled(
              8,
              "A longer line of scrollable renderer content.",
            ).join("\n\n").asStringLiteral,
          ),
        ),
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.card,
    name: "Card",
    type: const UnitType(),
    value: const UnitValue(),
    presentation: storyNode(
      "card",
      PresentationElement.card(
        storyNode(
          "cardContent",
          PresentationElement.text(
            "Content inside an outlined card.".asStringLiteral,
          ),
        ),
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.section,
    name: "Section",
    type: const UnitType(),
    value: const UnitValue(),
    presentation: storyNode(
      "section",
      PresentationElement.section(
        title: "Quest conditions".asStringLiteral,
        description: "Conditions determine when this quest becomes available."
            .asStringLiteral,
        initiallyExpanded: true,
        child: storyNode(
          "sectionContent",
          PresentationElement.text(
            "The player must reach level ten.".asStringLiteral,
          ),
        ),
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.collapsible,
    name: "Collapsible",
    type: const UnitType(),
    value: const UnitValue(),
    presentation: storyNode(
      "collapsible",
      PresentationElement.collapsible(
        title: "Advanced settings".asStringLiteral,
        initiallyExpanded: true,
        child: storyNode(
          "collapsibleContent",
          PresentationElement.text(
            "Optional advanced configuration.".asStringLiteral,
          ),
        ),
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.tabs,
    name: "Tabs",
    type: const UnitType(),
    value: const UnitValue(),
    presentation: storyNode(
      "tabs",
      PresentationElement.tabs(
        initiallySelectedTabId: "general",
        tabs: [
          TabItem(
            id: "general",
            label: "General".asStringLiteral,
            child: storyNode(
              "generalTab",
              PresentationElement.text("General settings".asStringLiteral),
            ),
          ),
          TabItem(
            id: "advanced",
            label: "Advanced".asStringLiteral,
            child: storyNode(
              "advancedTab",
              PresentationElement.text("Advanced settings".asStringLiteral),
            ),
          ),
        ],
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.divider,
    name: "Divider",
    type: const UnitType(),
    value: const UnitValue(),
    presentation: storyNode("divider", const PresentationElement.divider()),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.spacer,
    name: "Spacer",
    type: const UnitType(),
    value: const UnitValue(),
    presentation: storyNode(
      "spacer",
      PresentationElement.spacer(height: integerLiteral(32)),
      header: PresentationHeader(
        title: "Vertical spacer".asStringLiteral,
        description: "The empty area below this header is 32 pixels high."
            .asStringLiteral,
      ),
    ),
  ),
];
