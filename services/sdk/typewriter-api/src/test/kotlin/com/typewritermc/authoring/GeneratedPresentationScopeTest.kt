package com.typewritermc.authoring

import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.expression.Expr
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.expression.ExpressionFactory
import com.typewritermc.expression.MayBeMissing
import com.typewritermc.expression.MissingPolicy
import com.typewritermc.expression.field
import com.typewritermc.expression.gte
import com.typewritermc.expression.literal
import com.typewritermc.expression.orElse
import com.typewritermc.presentation.DefaultPresentationRuntime
import com.typewritermc.presentation.ExpressionNode
import com.typewritermc.presentation.PresentationBuildBinding
import com.typewritermc.presentation.presentationTemplate
import com.typewritermc.types.PresentationRole
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.Resolution
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.presentation.AxisChild
import skirout.editor.v1.presentation.ChildrenElement
import skirout.editor.v1.presentation.PresentationElement

val GeneratedPresentationScopeTest by testSuite {
    test("generated record value field remains distinct from the configured value") {
        val configured =
            Expr<Any?, MayBeMissing>(
                ExpressionNode.Read(ExpressionBindingId("configured_value"), ValuePath()),
            )
        val expressions = ValueFieldExpressionsFactory.create(configured)

        expressions.value.node shouldBe
            ExpressionNode.Read(
                ExpressionBindingId("configured_value"),
                ValuePath(listOf(PathSegment.Field("value"))),
            )
    }

    test("generated record expressions compile into symbolic presentation conditions") {
        val catalog =
            DefaultCheckedCatalog(
                CatalogGeneration("generated presentation"),
                listOf(
                    PlacementDefinition.definition,
                    TimelineCuePlacementDefinition.definition,
                    TimelineSegmentPlacementDefinition.definition,
                ),
            )
        val checked =
            (
                catalog.resolve(TypeUse.Named(TimelineSegmentPlacementDefinition.id)) as
                    Resolution.Ready
            ).value
        val root =
            DefaultPresentationRuntime()
                .build(PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.EDITOR)) { build ->
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
