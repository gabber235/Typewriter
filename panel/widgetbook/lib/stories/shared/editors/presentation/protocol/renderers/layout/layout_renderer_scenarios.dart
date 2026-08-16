import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/presentation_renderer_story.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/presentation_story_support.dart";

PresentationNode _label(String id, String label) => storyNode(
  id,
  PresentationElement.badge(label: label.asStringLiteral, tone: "neutral"),
);

final dropdownTabsRendererScenario = RendererStoryScenario(
  kind: RendererStoryKind.tabs,
  name: "Tabs with dropdown",
  type: const UnitType(),
  value: const UnitValue(),
  presentation: storyNode(
    "dropdownTabs",
    PresentationElement.tabs(
      initiallySelectedTabId: "general",
      tabs: [
        TabItem(
          id: "general",
          label: "General".asStringLiteral,
          child: storyNode(
            "dropdownGeneralTab",
            PresentationElement.text("General settings".asStringLiteral),
          ),
        ),
        TabItem(
          id: "advanced",
          label: "Advanced".asStringLiteral,
          child: storyNode(
            "dropdownAdvancedTab",
            PresentationElement.text("Advanced settings".asStringLiteral),
          ),
        ),
        TabItem(
          id: "history",
          label: "History".asStringLiteral,
          child: storyNode(
            "dropdownHistoryTab",
            PresentationElement.text("Change history".asStringLiteral),
          ),
        ),
        TabItem(
          id: "permissions",
          label: "Permissions".asStringLiteral,
          child: storyNode(
            "dropdownPermissionsTab",
            PresentationElement.text("Tab permissions".asStringLiteral),
          ),
        ),
      ],
    ),
  ),
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
    kind: RendererStoryKind.section,
    name: "Section",
    type: const UnitType(),
    value: const UnitValue(),
    presentation: storyNode(
      "section",
      PresentationElement.section(
        child: storyNode(
          "sectionContent",
          PresentationElement.text(
            "The player must reach level ten.".asStringLiteral,
          ),
        ),
        border: PresentationBorder.sides(
          start: PresentationBorderSide(
            color: TypedExpression(
              resultType: NamedType(standardTypeRefs.color),
              expression: LiteralExpression(
                IntegerValue(BigInt.from(0xFF967BFA)),
              ),
            ),
            width: 4,
          ),
          bottom: const PresentationBorderSide(width: 1),
        ),
      ),
      header: PresentationHeader(
        title: "Quest conditions".asStringLiteral.asHeaderTitle,
        description: "Conditions determine when this quest becomes available."
            .asStringLiteral,
        initiallyExpanded: true,
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
          TabItem(
            id: "history",
            label: "History".asStringLiteral,
            child: storyNode(
              "historyTab",
              PresentationElement.text("Change history".asStringLiteral),
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
        title: "Vertical spacer".asStringLiteral.asHeaderTitle,
        description: "The empty area below this header is 32 pixels high."
            .asStringLiteral,
      ),
    ),
  ),
];
