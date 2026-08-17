import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/presentation_renderer_story.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/presentation_story_support.dart";

const _itemBinding = BindingId(90);

final hierarchySequenceRendererScenario = RendererStoryScenario(
  kind: RendererStoryKind.connectionLayer,
  name: "Hierarchy sequence",
  type: const UnitType(),
  value: const UnitValue(),
  presentation: storyNode(
    "hierarchy.sequence",
    RepeatedElement(
      source: TypedExpression(
        resultType: ListType(element: NamedType(standardTypeRefs.color)),
        expression: LiteralExpression(
          ListValue([
            IntegerValue(BigInt.from(0xFF4CAF50)),
            IntegerValue(BigInt.from(0xFF03A9F4)),
            IntegerValue(BigInt.from(0xFFFF9800)),
          ]),
        ),
      ),
      itemBindingId: _itemBinding,
      presentation: SequencePresentation(
        item: storyNode(
          "hierarchy.item",
          PresentationElement.container(
            border: PresentationBorder.all(const PresentationBorderSide()),
            radius: const PresentationRadius.small(),
            child: storyNode(
              "hierarchy.item.padding",
              PresentationElement.padding(
                top: 10,
                start: 12,
                end: 12,
                bottom: 10,
                child: storyNode(
                  "hierarchy.item.label",
                  PresentationElement.text("Hierarchy item".asStringLiteral),
                ),
              ),
            ),
          ),
        ),
        layout: PresentationSequenceLayout.hierarchy(
          HierarchySequenceLayout(
            unaryConnector: _style(
              _itemColor,
              startMarker: ConnectorEndpointMarker.arrow(
                size: 7.asFloatLiteral,
              ),
            ),
            trunkConnector: _style(
              _trunkColor,
              cornerRadius: 8,
              startMarker: ConnectorEndpointMarker.arrow(
                size: 7.asFloatLiteral,
              ),
            ),
            branchConnector: _style(_itemColor, cornerRadius: 8),
            itemSpacing: 12.asFloatLiteral,
            indentation: 24.asFloatLiteral,
            leadingSpacing: 12.asFloatLiteral,
            itemAnchor: const ConnectorAnchor.center(),
            flattenSingleItem: true.asBooleanLiteral,
            crossAxisAlignment: PresentationCrossAxisAlignment.stretch,
          ),
        ),
      ),
    ),
  ),
);

final _itemColor = TypedExpression(
  resultType: NamedType(standardTypeRefs.color),
  expression: BindingExpression(BindingReference(bindingId: _itemBinding)),
);

final _trunkColor = TypedExpression(
  resultType: NamedType(standardTypeRefs.color),
  expression: LiteralExpression(IntegerValue(BigInt.from(0xFF967BFA))),
);

ConnectorStyle _style(
  TypedExpression color, {
  double cornerRadius = 0,
  ConnectorEndpointMarker? startMarker,
}) => ConnectorStyle(
  stroke: ConnectorStroke(color: color, width: 2.asFloatLiteral),
  cornerRadius: cornerRadius.asFloatLiteral,
  startMarker: startMarker,
);
