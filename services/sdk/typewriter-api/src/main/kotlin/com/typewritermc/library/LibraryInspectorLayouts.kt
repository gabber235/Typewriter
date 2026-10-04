package com.typewritermc.library

import com.typewritermc.configuration.generatedExpressionScope
import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.expression.MissingPolicy
import com.typewritermc.expression.OperationId
import com.typewritermc.expression.emptyListExpression
import com.typewritermc.expression.literal
import com.typewritermc.expression.map
import com.typewritermc.expression.orElse
import com.typewritermc.expression.target
import com.typewritermc.presentation.AxisLayout
import com.typewritermc.presentation.CollectionSource
import com.typewritermc.presentation.ContainerStyle
import com.typewritermc.presentation.CrossAxisAlignment
import com.typewritermc.presentation.ExpressionNode
import com.typewritermc.presentation.GraphNodeScope
import com.typewritermc.presentation.Layout
import com.typewritermc.presentation.PresentationInsets
import com.typewritermc.presentation.projectedCollectionSource
import com.typewritermc.types.Color
import com.typewritermc.types.ResourceId

internal fun Layout.inspectorSection(
    id: String,
    title: String,
    content: Layout.() -> Unit,
) {
    section {
        node(
            id = id,
            header = { title(literal(title)) },
            body = content,
        )
    }
}

internal fun Layout.inspectorLayout(content: AxisLayout.() -> Unit) {
    column(
        spacing = 12.0,
        cross = CrossAxisAlignment.Stretch,
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

internal fun GraphNodeScope<TagCollectionRow>.tagGraphNode() {
    val tag = generatedExpressionScope(TagCollectionRowExpressions::class, row)
    chip(
        label = tag.name.orElse(literal("Unnamed tag")),
        color = tag.color.orElse(literal(Color(0xff9e9e9eu))),
    )
    descendants()
}

internal fun Layout.librarySubjectLayout(
    label: Expr<String, Handled>,
    color: Expr<Color, Handled>? = null,
    leadingContent: Layout.() -> Unit,
) {
    adaptiveLeading {
        leading {
            if (color == null) {
                leadingContent()
            } else {
                container(ContainerStyle(color = color)) {
                    padding(PresentationInsets(6.0, 6.0, 6.0, 6.0), leadingContent)
                }
            }
        }
        center { text(label) }
        padding(PresentationInsets(8.0, 8.0, 8.0, 8.0))
        compactPadding(PresentationInsets(4.0, 4.0, 4.0, 4.0))
        gap(12.0)
        minimumCenterWidth(80.0)
    }
}

internal fun Expr<String, MissingPolicy>.orIfBlank(fallback: String): Expr<String, Handled> {
    val fallbackNode = literal(fallback).node
    val nonBlank =
        ExpressionNode.Call(
            OperationId("typewriter.rule.nonBlank"),
            listOf(node),
        )
    return Expr(
        ExpressionNode.OrElse(
            ExpressionNode.Conditional(nonBlank, node, fallbackNode),
            fallbackNode,
        ),
    )
}
