import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/presentation_renderer_story.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/presentation_story_support.dart";

const _queryBindingId = BindingId(10);
const _summaryBindingId = BindingId(11);
const _resultBindingId = BindingId(12);
const _resultBinding = BindingReference(bindingId: _resultBindingId);
const _stringType = StringType();

final _resultExpression = TypedExpression(
  resultType: _stringType,
  expression: const BindingExpression(_resultBinding),
);

final searchInputRendererScenario = RendererStoryScenario(
  kind: RendererStoryKind.searchInput,
  name: "Search input",
  type: _stringType,
  value: const StringValue("Strength"),
  presentation: storyNode(
    "searchInput",
    PresentationElement.searchInput(
      control: storyControl("Minecraft effect"),
      selectionMode: SearchSelectionMode.single,
      queryBindingId: _queryBindingId,
      summaryBindingId: _summaryBindingId,
      maximumExtent: 280.asFloatLiteral,
      placeholder: "Search effects".asStringLiteral,
      provider: SearchProvider.staticValues(
        values: const ListValue([
          StringValue("Speed"),
          StringValue("Haste"),
          StringValue("Strength"),
          StringValue("Regeneration"),
        ]).asLiteral(const ListType(element: _stringType)),
        result: SearchResultMapping(
          bindingId: _resultBindingId,
          key: _resultExpression,
          selectedValue: _resultExpression,
          presentation: PresentationNode(
            id: "searchInput.result",
            element: TextElement(_resultExpression),
          ),
        ),
      ),
    ),
  ),
);
