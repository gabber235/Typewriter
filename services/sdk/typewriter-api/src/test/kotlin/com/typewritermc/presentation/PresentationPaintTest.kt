@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.presentation

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.expression.literal
import com.typewritermc.types.Color
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.nulls.shouldNotBeNull
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
import skirout.editor.v1.presentation.PresentationTransition
import skirout.editor.v1.presentation.StackChild
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.presentation.PresentationColor as WireColor
import skirout.editor.v1.presentation.PresentationNumber as WireNumber

val PresentationPaintTest by testSuite {
    fun build(content: (PresentationBuildScope) -> Unit): PresentationNode {
        val catalog = DefaultCheckedCatalog(CatalogGeneration(value = "paint"), StandardTypes.definitions)
        val checked = (catalog.resolve(ScalarKind.TEXT.use) as Resolution.Ready).value
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

    test("a state transition picks the rule of the entered state and otherwise its fallback") {
        val policy =
            stateTransition(fallback = transition(DisplayDelay(120), curve = PresentationCurve.EASE_OUT)) {
                whenAll(
                    SELECTED,
                    excluded = setOf(HOVERED),
                    transition = transition(DisplayDelay(480), curve = PresentationCurve.ElasticOutWrapper(0.5)),
                )
            }

        policy.fallback shouldBe PresentationTransition(milliseconds = 120, curve = PresentationCurve.EASE_OUT)
        policy.rules
            .single()
            .match.required shouldBe listOf(SELECTED)
        policy.rules
            .single()
            .match.excluded shouldBe listOf(HOVERED)
        policy.rules.single().transition shouldBe
            PresentationTransition(milliseconds = 480, curve = PresentationCurve.ElasticOutWrapper(0.5))
    }

    test("a transition cannot be given a negative length") {
        shouldThrow<IllegalArgumentException> { transition(DisplayDelay(-1)) }.message shouldBe "Display delays must be nonnegative."
    }

    test("a state transition built from a negative wire transition is refused") {
        shouldThrow<IllegalArgumentException> {
            stateTransition(fallback = PresentationTransition(milliseconds = -1, curve = PresentationCurve.LINEAR))
        }.message shouldBe "Presentation transitions cannot have a negative duration."
    }

    test("an elastic transition whose period is not positive is refused") {
        shouldThrow<IllegalArgumentException> {
            transition(DisplayDelay(10), curve = PresentationCurve.ElasticOutWrapper(0.0))
        }.message shouldBe "Elastic curve periods must be finite and positive."
    }

    /** The size node of a layout whose only content is [sizeBody] inside a size of width 175 and maximum height 230. */
    fun sized(sizeBody: Layout.() -> Unit) =
        build { scope -> scope.size(width = 175.0, maximumHeight = 230.0, body = sizeBody) }
            .element
            .shouldBeInstanceOf<PresentationElement.SizeWrapper>()
            .value

    test("a size encodes the bounds it was given and leaves the others open") {
        val size = sized {}

        size.width?.literal() shouldBe 175.0
        size.height shouldBe null
        size.maximumHeight?.literal() shouldBe 230.0
    }

    test("a negative size is refused") {
        shouldThrow<IllegalArgumentException> { build { scope -> scope.size(width = -1.0) {} } }.message shouldBe
            "Sizes must be finite and nonnegative."
    }

    test("a transform encodes its origin, perspective, state driven rotation, translation and motion") {
        val transform =
            sized {
                transform(
                    TransformStyle(
                        origin = PresentationAlignment.CENTER_START,
                        perspective = 0.002,
                        rotateY = stateNumber(fallback = 0.0) { whenAll(SELECTED, excluded = setOf(HOVERED), value = 0.05) },
                        translateX = number(3.0),
                        transition = selectMotion,
                    ),
                ) {}
            }.child
                .singleChild()
                .element
                .shouldBeInstanceOf<PresentationElement.TransformWrapper>()
                .value
        val rotate = transform.rotateY.shouldBeInstanceOf<WireNumber.StatesWrapper>().value

        transform.origin shouldBe PresentationAlignment.CENTER_START
        transform.perspective shouldBe 0.002
        transform.scale shouldBe null
        rotate.fallback.literal() shouldBe 0.0
        rotate.rules
            .single()
            .match.required shouldBe listOf(SELECTED)
        rotate.rules
            .single()
            .match.excluded shouldBe listOf(HOVERED)
        rotate.rules
            .single()
            .value
            .literal() shouldBe 0.05
        transform.translateX?.literal() shouldBe 3.0
        transform.transition shouldBe selectMotion
    }

    /** The wire form of [color] as a container background. */
    fun wireColor(color: PresentationColor): WireColor =
        build { scope -> scope.container(ContainerStyle(background = color)) {} }
            .element
            .shouldBeInstanceOf<PresentationElement.ContainerWrapper>()
            .value.backgroundColor
            .shouldNotBeNull()

    test("a container shadow encodes its color, blur and offsets, with unset offsets and spread at zero") {
        val accent = literalColor(Color(0xff3366ccu))
        val shadow =
            sized {
                container(
                    ContainerStyle(
                        background = accent,
                        shadows = listOf(PresentationShadow(accent.withAlpha(0.4), blur = 8.0, offsetY = 2.0)),
                    ),
                ) {}
            }.child
                .singleChild()
                .element
                .shouldBeInstanceOf<PresentationElement.ContainerWrapper>()
                .value.shadows
                .single()
        val color = shadow.color.shouldBeInstanceOf<WireColor.AlphaWrapper>().value

        listOf(shadow.blur, shadow.spread, shadow.offsetX, shadow.offsetY) shouldBe listOf(8.0, 0.0, 0.0, 2.0)
        color.alpha shouldBe 0.4
        color.source shouldBe wireColor(accent)
    }

    test("a brightness color keeps an adjusted light variant and a state driven dark variant over the same source") {
        val accent = literalColor(Color(0xff3366ccu))
        val brightness =
            wireColor(
                brightnessColor(
                    light = accent.adjusted(lightness = 0.3, chroma = -0.3),
                    dark = stateColor(accent) { whenAll(FOCUSED, color = accent.adjusted(lightness = -0.5)) },
                ),
            ).shouldBeInstanceOf<WireColor.BrightnessWrapper>().value
        val light = brightness.light.shouldBeInstanceOf<WireColor.AdjustedWrapper>().value
        val dark = brightness.dark.shouldBeInstanceOf<WireColor.StatesWrapper>().value
        val focused = dark.rules.single()

        listOf(light.lightness, light.chroma) shouldBe listOf(0.3, -0.3)
        light.source shouldBe wireColor(accent)
        dark.fallback shouldBe wireColor(accent)
        focused.match.required shouldBe listOf(FOCUSED)
        focused.color shouldBe wireColor(accent.adjusted(lightness = -0.5))
    }

    test("an adjustment outside minus one to one is refused") {
        shouldThrow<IllegalArgumentException> {
            literalColor(Color(0xff3366ccu)).adjusted(lightness = 1.5)
        }.message shouldBe "Presentation lightness must be between minus one and one."
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
