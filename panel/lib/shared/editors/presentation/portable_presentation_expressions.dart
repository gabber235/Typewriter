import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

extension PortableBindingExpressions on skir.ExpressionBindingId {
  skir.ExpressionNode readExpression() => skir.ExpressionNode.createRead(
    binding: this,
    path: skir.ValuePath(segments: const []),
  );
}

extension PortableTextExpressions on String {
  skir.ExpressionNode get portableExpression =>
      skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapStringValue(this));
}

extension PortableColorExpressions on Color {
  skir.ExpressionNode get portableExpression => skir.ExpressionNode.wrapLiteral(
    skir.DataValue.wrapInteger(toARGB32().toString()),
  );
}

extension PortableResourceHeading on skir.ExpressionNode {
  /// Composes a fitted title and optional identity, hidden for multiple selection.
  skir.PresentationNode resourceHeading({
    required String id,
    required skir.ExpressionNode color,
    skir.ExpressionNode? identifier,
  }) {
    skir.PresentationNode node(
      String suffix,
      skir.PresentationElement element,
    ) => skir.PresentationNode(
      nodeId: "$id.$suffix",
      properties: skir.PresentationProperties.defaultInstance,
      element: element,
      header: null,
    );
    skir.ExpressionNode number(double value) =>
        skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapFloat(value));
    final identity = identifier == null
        ? null
        : skir.ExpressionNode.createOrElse(
            input: identifier,
            fallback: "".portableExpression,
          );
    final title =
        (skir.TextContent.mutable()
              ..value = this
              ..color = color
              ..fontWeight = number(700)
              ..sizing = skir.TextSizing.createFit(
                minimum: number(18),
                maximum: number(40),
              )
              ..paragraph = skir.TextParagraph(
                maxLines: 1,
                overflow: skir.PresentationTextOverflow.ellipsis,
                softWrap: false,
                selectable: true,
                tone: skir.PresentationTextTone.primary,
              ))
            .toFrozen();
    return node(
      "visible",
      skir.PresentationElement.createConditional(
        condition: skir.ExpressionNode.createCall(
          operation: skir.OperationId(value: "typewriter.value.eq"),
          arguments: [
            skir.ExpressionNode.createOrElse(
              input: presentationSelectionCountBindingId.readExpression(),
              fallback: skir.ExpressionNode.wrapLiteral(
                skir.DataValue.wrapInteger("1"),
              ),
            ),
            skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapInteger("1")),
          ],
        ),
        whenTrue: node(
          "content",
          skir.PresentationElement.wrapChildren(
            skir.ChildrenElement.createColumn(
              children: [
                skir.AxisChild.wrapFixed(
                  node("title", skir.PresentationElement.wrapText(title)),
                ),
                if (identity != null)
                  skir.AxisChild.wrapFixed(
                    node(
                      "identity.visible",
                      skir.PresentationElement.createConditional(
                        condition: skir.ExpressionNode.createCall(
                          operation: skir.OperationId(
                            value: "typewriter.value.neq",
                          ),
                          arguments: [identity, "".portableExpression],
                        ),
                        whenTrue: node(
                          "identity",
                          skir.PresentationElement.wrapText(
                            (skir.TextContent.mutable()
                                  ..value = identity
                                  ..sizing = skir.TextSizing.wrapExact(
                                    number(12),
                                  )
                                  ..paragraph = skir.TextParagraph(
                                    maxLines: null,
                                    overflow:
                                        skir.PresentationTextOverflow.clip,
                                    softWrap: true,
                                    selectable: true,
                                    tone: skir.PresentationTextTone.secondary,
                                  ))
                                .toFrozen(),
                          ),
                        ),
                        whenFalse: null,
                      ),
                    ),
                  ),
              ],
              layout: skir.AxisChildrenLayout(
                spacing: 8,
                mainAxisAlignment: skir.MainAxisAlignment.start,
                crossAxisAlignment: skir.CrossAxisAlignment.stretch,
              ),
            ),
          ),
        ),
        whenFalse: null,
      ),
    );
  }
}
