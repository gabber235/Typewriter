@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.presentation

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.expression.literal
import com.typewritermc.types.Color
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.Resolution
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.presentation.ChildrenElement
import skirout.editor.v1.presentation.PresentationAlignment
import skirout.editor.v1.presentation.PresentationCurve
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationInteractionState
import skirout.editor.v1.presentation.PresentationInteractionState.FOCUSED
import skirout.editor.v1.presentation.PresentationInteractionState.HOVERED
import skirout.editor.v1.presentation.PresentationInteractionState.SELECTED
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.presentation.StackChild
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.presentation.PresentationColor as WireColor
import skirout.editor.v1.presentation.PresentationNumber as WireNumber

val PresentationPaintTest by testSuite {
    fun build(content: (PresentationBuildScope) -> Unit): PresentationNode {
        val catalog = DefaultCheckedCatalog(CatalogGeneration("paint"), StandardTypes.definitions)
        val checked = (catalog.resolve(TypeUse.Scalar(ScalarKind.Text)) as Resolution.Ready).value
        return DefaultPresentationRuntime()
            .build(PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.ITEM), content)
            .layout
            .single()
    }

    test("a stack keeps flow and positioned children in declaration order with its alignment") {
        val stack =
            build { scope ->
                scope.stack(alignment = PresentationAlignment.BOTTOM_END) {
                    text(literal("Under"))
                    positioned(
                        top = number(4.0),
                        end = stateNumber(fallback = 2.0) { whenAll(SELECTED, value = 8.0) },
                        width = number(30.0),
                    ) {
                        text(literal("Edge"))
                    }
                    fill { text(literal("Cover")) }
                }
            }.element
                .shouldBeInstanceOf<PresentationElement.ChildrenWrapper>()
                .value
                .shouldBeInstanceOf<ChildrenElement.StackWrapper>()
                .value

        stack.alignment shouldBe PresentationAlignment.BOTTOM_END
        stack.children.map { it.kind } shouldBe
            listOf(StackChild.Kind.FLOW_WRAPPER, StackChild.Kind.POSITIONED_WRAPPER, StackChild.Kind.POSITIONED_WRAPPER)
        val edge = stack.children[1].shouldBeInstanceOf<StackChild.PositionedWrapper>().value
        edge.top?.literal() shouldBe 4.0
        edge.start shouldBe null
        edge.width?.literal() shouldBe 30.0
        val end = edge.end.shouldBeInstanceOf<WireNumber.StatesWrapper>().value
        end.fallback.literal() shouldBe 2.0
        end.rules
            .single()
            .match.required shouldBe listOf(PresentationInteractionState.SELECTED)
        end.rules
            .single()
            .value
            .literal() shouldBe 8.0
        val fill = stack.children[2].shouldBeInstanceOf<StackChild.PositionedWrapper>().value
        listOf(fill.top, fill.start, fill.end, fill.bottom).map { it?.literal() } shouldBe listOf(0.0, 0.0, 0.0, 0.0)
    }

    test("a positioned child declares at most two bounds on each axis") {
        shouldThrow<IllegalArgumentException> {
            build { scope ->
                scope.stack {
                    positioned(start = number(0.0), end = number(0.0), width = number(10.0)) {}
                }
            }
        }.message shouldContain "two horizontal bounds"
    }

    test("transitions pick a curve per entered state and default to the fallback") {
        val policy = selectMotion

        policy.fallback.milliseconds shouldBe 300
        policy.fallback.curve shouldBe PresentationCurve.EMPHASIZED
        val selected = policy.rules.single()
        selected.match.required shouldBe listOf(PresentationInteractionState.SELECTED)
        selected.transition.milliseconds shouldBe 750
        selected.transition.curve
            .shouldBeInstanceOf<PresentationCurve.ElasticOutWrapper>()
            .value shouldBe 0.9
        shouldThrow<IllegalArgumentException> { transition(milliseconds = -1) }
        shouldThrow<IllegalArgumentException> { transition(milliseconds = 10, curve = PresentationCurve.ElasticOutWrapper(0.0)) }
    }

    test("size, transform and container shadows encode their paint") {
        val accent = literalColor(Color(0xff3366ccu))
        val sized =
            build { scope ->
                scope.size(width = 175.0, maximumHeight = 230.0) {
                    transform(
                        TransformStyle(
                            origin = PresentationAlignment.CENTER_START,
                            perspective = 0.002,
                            rotateY = stateNumber(fallback = 0.0) { whenAll(SELECTED, excluded = setOf(HOVERED), value = 0.05) },
                            translateX = number(3.0),
                            transition = selectMotion,
                        ),
                    ) {
                        container(
                            ContainerStyle(
                                background = accent,
                                shadows = listOf(PresentationShadow(accent.withAlpha(0.4), blur = 8.0, offsetY = 2.0)),
                            ),
                        ) {}
                    }
                }
            }.element
                .shouldBeInstanceOf<PresentationElement.SizeWrapper>()
                .value

        sized.width?.literal() shouldBe 175.0
        sized.height shouldBe null
        sized.maximumHeight?.literal() shouldBe 230.0
        val transform =
            sized.child
                .singleChild()
                .element
                .shouldBeInstanceOf<PresentationElement.TransformWrapper>()
                .value
        transform.origin shouldBe PresentationAlignment.CENTER_START
        transform.perspective shouldBe 0.002
        transform.scale shouldBe null
        val rotate = transform.rotateY.shouldBeInstanceOf<WireNumber.StatesWrapper>().value
        rotate.rules
            .single()
            .match.excluded shouldBe listOf(PresentationInteractionState.HOVERED)
        transform.translateX?.literal() shouldBe 3.0
        transform.transition?.rules?.size shouldBe 1
        val container =
            transform.child
                .singleChild()
                .element
                .shouldBeInstanceOf<PresentationElement.ContainerWrapper>()
                .value
        val shadow = container.shadows.single()
        listOf(shadow.blur, shadow.spread, shadow.offsetX, shadow.offsetY) shouldBe listOf(8.0, 0.0, 0.0, 2.0)
        shadow.color
            .shouldBeInstanceOf<WireColor.AlphaWrapper>()
            .value.alpha shouldBe 0.4
        shouldThrow<IllegalArgumentException> { build { scope -> scope.size(width = -1.0) {} } }
    }

    test("adjusted and brightness colors keep their source policy") {
        val accent = literalColor(Color(0xff3366ccu))
        val color =
            brightnessColor(
                light = accent.adjusted(lightness = 0.3, chroma = -0.3),
                dark = stateColor(accent) { whenAll(FOCUSED, color = accent.adjusted(lightness = -0.5)) },
            ).wire()

        val brightness = color.shouldBeInstanceOf<WireColor.BrightnessWrapper>().value
        val light = brightness.light.shouldBeInstanceOf<WireColor.AdjustedWrapper>().value
        listOf(light.lightness, light.chroma) shouldBe listOf(0.3, -0.3)
        light.source.shouldBeInstanceOf<WireColor.ValueWrapper>()
        brightness.dark.shouldBeInstanceOf<WireColor.StatesWrapper>()
        shouldThrow<IllegalArgumentException> { accent.adjusted(lightness = 1.5) }
    }
}

private fun WireNumber.literal(): Double = shouldBeInstanceOf<WireNumber.ValueWrapper>().value.literal()

private fun ExpressionNode.literal(): Double = ((this as ExpressionNode.LiteralWrapper).value as DataValue.FloatWrapper).value

/** The single child a builder wraps a body in. */
private fun PresentationNode.singleChild(): PresentationNode {
    val column = (element as PresentationElement.ChildrenWrapper).value as ChildrenElement.ColumnWrapper
    return (column.value.children.single() as skirout.editor.v1.presentation.AxisChild.FixedWrapper).value
}

/** The single root node of a built layout. */
private fun PresentationNode.single(): PresentationNode = singleChild()
