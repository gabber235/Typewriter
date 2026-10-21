package com.typewritermc.library

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.expression.MissingPolicy
import com.typewritermc.expression.emptyListExpression
import com.typewritermc.expression.eq
import com.typewritermc.expression.gt
import com.typewritermc.expression.gte
import com.typewritermc.expression.literal
import com.typewritermc.expression.map
import com.typewritermc.expression.orElse
import com.typewritermc.expression.orIfBlank
import com.typewritermc.expression.size
import com.typewritermc.expression.target
import com.typewritermc.presentation.AxisLayout
import com.typewritermc.presentation.CollectionSource
import com.typewritermc.presentation.ConnectorEndpointMarker
import com.typewritermc.presentation.ConnectorStyle
import com.typewritermc.presentation.ContainerStyle
import com.typewritermc.presentation.GraphNodeScope
import com.typewritermc.presentation.Layout
import com.typewritermc.presentation.PresentationBorder
import com.typewritermc.presentation.PresentationColor
import com.typewritermc.presentation.PresentationInput
import com.typewritermc.presentation.PresentationInsets
import com.typewritermc.presentation.PresentationRadius
import com.typewritermc.presentation.TextParagraph
import com.typewritermc.presentation.asPresentationColor
import com.typewritermc.presentation.projectedCollectionSource
import com.typewritermc.presentation.withAlpha
import com.typewritermc.types.Color
import com.typewritermc.types.ResourceId
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.expression.RuleUnaryOperation
import skirout.editor.v1.presentation.CrossAxisAlignment

internal fun Layout.inspectorSection(
    id: String,
    title: String,
    input: PresentationInput<*, *>? = null,
    content: Layout.() -> Unit,
) {
    section {
        node(
            id = id,
            header = {
                title(literal(title))
                input?.let { diagnostics(it) }
            },
            body = content,
        )
    }
}

internal fun Layout.inspectorLayout(content: AxisLayout.() -> Unit) {
    column(
        spacing = 12.0,
        cross = CrossAxisAlignment.STRETCH,
        body = content,
    )
}

internal fun libraryTagCollectionSource(): CollectionSource<TagCollectionRow, ResourceId> =
    coreTagCollectionProjection().projectedCollectionSource {
        selectability(expressions.selectable.orElse(literal(false)))
        relations(
            "parents",
            expressions.parents
                .map { target }
                .orElse(emptyListExpression()),
        )
    }

/** Shares the inspector inheritance view while collection traversal remains renderer owned. */
internal fun Layout.tagInheritanceSection(
    id: String,
    title: String,
    source: CollectionSource<TagCollectionRow, ResourceId>,
    roots: Expr<List<ResourceId>, com.typewritermc.expression.MayBeMissing>,
) {
    showIf((roots.size gt 0).orElse(literal(true))) {
        inspectorSection(id, title) {
            collectionGraph(source) {
                roots(roots)
                relation("parents")
                rootSequence { column(spacing = 12.0, cross = CrossAxisAlignment.STRETCH) }
                childrenSequence {
                    val ownerColor =
                        TagCollectionRowExpressionsFactory
                            .create(
                                parent,
                            ).color
                            .orElse(literal(Color(0xff9e9e9eu)))
                            .asPresentationColor()
                    val childColor =
                        TagCollectionRowExpressionsFactory
                            .create(
                                item,
                            ).color
                            .orElse(literal(Color(0xff9e9e9eu)))
                            .asPresentationColor()
                    hierarchy(
                        unaryConnector = tagConnector(childColor, ConnectorEndpointMarker.Arrow(literal(8.0))),
                        trunkConnector = tagConnector(ownerColor, ConnectorEndpointMarker.Arrow(literal(10.0)), radius = 8.0),
                        branchConnector = tagConnector(childColor, ConnectorEndpointMarker.Circle(literal(6.0)), radius = 8.0),
                    )
                }
                node { tagInheritanceNode() }
            }
        }
    }
}

private fun tagConnector(
    color: PresentationColor,
    marker: ConnectorEndpointMarker,
    radius: Double = 0.0,
) = ConnectorStyle(
    color = color,
    width = literal(2.0),
    cornerRadius = literal(radius),
    startMarker = marker,
)

private fun GraphNodeScope<TagCollectionRow>.tagInheritanceNode() {
    val tag = TagCollectionRowExpressionsFactory.create(row)
    val count = children.size.orElse(literal(0))
    val accent = tag.color.orElse(literal(Color(0xff9e9e9eu))).asPresentationColor()
    val label = tag.name.orIfBlank("Unnamed tag")
    column(cross = CrossAxisAlignment.STRETCH) {
        showIf(
            count gte 2,
            whenFalse = {
                column(cross = CrossAxisAlignment.STRETCH) {
                    tagInheritanceCard(label, accent)
                    showIf(count eq literal(1)) { descendants() }
                }
            },
        ) {
            column(cross = CrossAxisAlignment.STRETCH) {
                section(
                    border = PresentationBorder.Sides(start = PresentationBorder.Side(width = 4.0, color = accent)),
                    header = {
                        title { column(cross = CrossAxisAlignment.STRETCH) { tagInheritanceCard(label, accent) } }
                        expanded(initially = false)
                        padding(header = PresentationInsets(0.0, 0.0, 0.0, 0.0), content = PresentationInsets(0.0, 0.0, 0.0, 0.0))
                    },
                ) { descendants() }
            }
        }
    }
}

private fun Layout.tagInheritanceCard(
    label: Expr<String, Handled>,
    accent: PresentationColor,
) {
    container(
        ContainerStyle(
            background = accent.withAlpha(46.0 / 255.0),
            foreground = accent,
            border = PresentationBorder.All(width = 1.0, color = accent),
            radius = PresentationRadius.Small,
        ),
    ) {
        padding(PresentationInsets(start = 12.0, top = 8.0, end = 12.0, bottom = 8.0)) {
            text(label, paragraph = TextParagraph(softWrap = true))
        }
    }
}

internal fun Layout.librarySubjectLayout(
    label: Expr<String, Handled>,
    leadingContent: Layout.() -> Unit,
) {
    adaptiveLeading {
        leading(leadingContent)
        center { text(label) }
        padding(PresentationInsets(8.0, 8.0, 8.0, 8.0))
        compactPadding(PresentationInsets(4.0, 4.0, 4.0, 4.0))
        gap(12.0)
        minimumCenterWidth(80.0)
    }
}
