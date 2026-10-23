@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.authoring

import com.typewritermc.expression.Expr
import com.typewritermc.expression.ExpressionFactory
import com.typewritermc.expression.MayBeMissing
import com.typewritermc.expression.MissingPolicy
import com.typewritermc.expression.field
import com.typewritermc.expression.literal
import com.typewritermc.expression.orElse
import com.typewritermc.expression.shortcuts.gte
import com.typewritermc.presentation.DefaultPresentationRuntime
import com.typewritermc.presentation.PresentationBuildBinding
import com.typewritermc.presentation.presentationTemplate
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.presentation.AxisChild
import skirout.editor.v1.presentation.ChildrenElement
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.ValuePath

val GeneratedPresentationScopeTest by testSuite {
    test("generated record value field remains distinct from the configured value") {
        val configured =
            com.typewritermc.expression.input<Any?>(ExpressionBindingId(value = "configured_value"))
        val expressions = ValueFieldExpressionsFactory.create(configured)

        expressions.value.toNode() shouldBe
            com.typewritermc.expression
                .input<Any?>(
                    ExpressionBindingId(value = "configured_value"),
                    ValuePath.root.field("value"),
                ).toNode()
    }

    test("generated record expressions compile into symbolic presentation conditions") {
        val catalog =
            DefaultCheckedCatalog(
                CatalogGeneration(value = "generated presentation"),
                listOf(
                    PlacementDefinition.definition,
                    TimelineCuePlacementDefinition.definition,
                    TimelineSegmentPlacementDefinition.definition,
                ),
            )
        val checked =
            (
                catalog.resolve(TimelineSegmentPlacementDefinition.id.use()) as
                    Resolution.Ready
            ).value
        val root =
            DefaultPresentationRuntime()
                .build(PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.WORKSPACE)) { build ->
                    with(ConditionalPlacementPresentation) {
                        TimelineSegmentPlacementPresentationScopeImpl(build).present()
                    }
                }.layout
        val column = (root.element as PresentationElement.ChildrenWrapper).value as ChildrenElement.ColumnWrapper
        val conditionalNode = (column.value.children.single() as AxisChild.FixedWrapper).value

        (conditionalNode.element is PresentationElement.ConditionalWrapper) shouldBe true
    }
}

private interface ValueFieldExpressions {
    val value: Expr<String, MayBeMissing>
}

private object ValueFieldExpressionsFactory : ExpressionFactory<ValueFieldExpressions> {
    override val scope = ValueFieldExpressions::class

    override fun create(value: Expr<*, out MissingPolicy>): ValueFieldExpressions =
        object : ValueFieldExpressions {
            override val value: Expr<String, MayBeMissing> = value.field("value")
        }
}

private object ConditionalPlacementPresentation : TimelineSegmentPlacementPresentation {
    override fun TimelineSegmentPlacementPresentationScope.present() {
        showIf(
            condition = { (endFrame gte startFrame).orElse(literal(false)) },
        ) {
            endFrame {
                label("End frame")
                numericInput()
            }
        }
    }
}
