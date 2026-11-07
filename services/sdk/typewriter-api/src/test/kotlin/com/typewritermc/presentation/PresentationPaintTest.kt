@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.presentation

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.expression.literal
import com.typewritermc.testkit.buildPresentation
import com.typewritermc.testkit.elementsOf
import com.typewritermc.testkit.literalFloat
import com.typewritermc.testkit.ready
import com.typewritermc.testkit.singleFixed
import com.typewritermc.types.Color
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.presentation.ChildrenElement
import skirout.editor.v1.presentation.PresentationAlignment
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationInteractionState
import skirout.editor.v1.presentation.PresentationInteractionState.FOCUSED
import skirout.editor.v1.presentation.PresentationInteractionState.HOVERED
import skirout.editor.v1.presentation.PresentationInteractionState.SELECTED
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.presentation.PresentationSpring
import skirout.editor.v1.presentation.PresentationTimedTransition
import skirout.editor.v1.presentation.PresentationTransition
import skirout.editor.v1.presentation.PresentationTransitionPolicy
import skirout.editor.v1.presentation.StackChild
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.presentation.PresentationColor as WireColor
import skirout.editor.v1.presentation.PresentationNumber as WireNumber

val PresentationPaintTest by testSuite {
    test("a positioned child declares at most two bounds on each axis") {
        shouldThrow<IllegalArgumentException> {
            buildPresentation {
                stack {
                    positioned(start = number(0.0), end = number(0.0), width = number(10.0)) {}
                }
            }.layout.singleFixed()
        }.message shouldContain "two horizontal bounds"
    }

    test("a presentation with no overrides leaves every move to the panel") {
        moveOverrides() shouldBe PresentationTransitionPolicy(hovered = null, focused = null, pressed = null, selected = null)
    }

    test("an override is keyed by the state whose move it changes and names no move") {
        val policy =
            moveOverrides(
                hovered = MoveOverride.Timed(length = DisplayDelay(120)),
                selected = MoveOverride.Spring(300.0, 12.0),
            )

        policy.hovered shouldBe
            PresentationTransition.TimedWrapper(PresentationTimedTransition(milliseconds = 120, curve = null))
        policy.selected shouldBe
            PresentationTransition.SpringWrapper(PresentationSpring(stiffness = 300.0, damping = 12.0))
        policy.focused shouldBe null
        policy.pressed shouldBe null
    }

    test("an override cannot be given a negative length") {
        shouldThrow<IllegalArgumentException> { MoveOverride.Timed(length = DisplayDelay(-1)) }.message shouldBe
            "Display delays must be nonnegative."
    }

    test("a timed override that replaces nothing is refused") {
        shouldThrow<IllegalArgumentException> { MoveOverride.Timed() }.message shouldBe
            "A timed override replaces a length, a curve or both."
    }

    test("curve and spring values outside their family are refused") {
        shouldThrow<IllegalArgumentException> { TimedCurve.Strike(1.0) }.message shouldBe "Strike overshoot must be between 0 and 1."
        shouldThrow<IllegalArgumentException> { TimedCurve.Carriage(-0.1) }.message shouldBe
            "Carriage recoil must be at least 0 and below 1."
        shouldThrow<IllegalArgumentException> { MoveOverride.Spring(0.0, 12.0) }.message shouldBe
            "Spring stiffness and damping must be finite and positive."
    }

    test("hand built wire overrides meet the same rules") {
        shouldThrow<IllegalArgumentException> {
            PresentationTransition.TimedWrapper(PresentationTimedTransition(milliseconds = -1, curve = null)).requireValid()
        }.message shouldBe "Presentation transitions cannot have a negative duration."
        shouldThrow<IllegalArgumentException> {
            PresentationTransitionPolicy(
                hovered = null,
                focused = null,
                pressed = PresentationTransition.SpringWrapper(PresentationSpring(stiffness = Double.NaN, damping = 12.0)),
                selected = null,
            ).requireValid()
        }.message shouldBe "Spring stiffness and damping must be finite and positive."
    }

    test("a collection sends no item motion unless it overrides one") {
        val appearance = collectionAppearance {}
        appearance.itemArrival shouldBe null
        appearance.itemLeave shouldBe null
    }

    test("a collection may override how items arrive and leave without naming a move") {
        val appearance =
            collectionAppearance {
                itemArrival(MoveOverride.Timed(length = DisplayDelay(400)))
                itemLeave(MoveOverride.Spring(380.0, 30.0))
            }
        appearance.itemArrival shouldBe
            PresentationTransition.TimedWrapper(PresentationTimedTransition(milliseconds = 400, curve = null))
        appearance.itemLeave shouldBe
            PresentationTransition.SpringWrapper(PresentationSpring(stiffness = 380.0, damping = 30.0))
    }

    test("a size encodes the bounds it was given and leaves the others open") {
        val size =
            buildPresentation {
                size(width = 175.0, maximumHeight = 230.0) {}
            }.layout.singleFixed().element.shouldBeInstanceOf<PresentationElement.SizeWrapper>().value

        size.width?.literalFloat() shouldBe 175.0
        size.height shouldBe null
        size.maximumHeight?.literalFloat() shouldBe 230.0
    }

    test("a negative size is refused") {
        shouldThrow<IllegalArgumentException> { buildPresentation { size(width = -1.0) {} }.layout.singleFixed() }.message shouldBe
            "Sizes must be finite and nonnegative."
    }

    test("a transform encodes its origin, perspective, state driven rotation, translation and motion") {
        val transform =
            buildPresentation {
                size(width = 175.0, maximumHeight = 230.0) {
                    transform(
                        TransformStyle(
                            origin = PresentationAlignment.CENTER_START,
                            perspective = 0.002,
                            rotateY = stateNumber(fallback = 0.0) { whenAll(SELECTED, excluded = setOf(HOVERED), value = 0.05) },
                            translateX = number(3.0),
                            transition = moveOverrides(selected = MoveOverride.Timed(DisplayDelay(750))),
                        ),
                    ) {}
                }
            }.layout
                .singleFixed()
                .element
                .shouldBeInstanceOf<PresentationElement.SizeWrapper>()
                .value.child
                .singleFixed()
                .element
                .shouldBeInstanceOf<PresentationElement.TransformWrapper>()
                .value
        val rotate = transform.rotateY.shouldBeInstanceOf<WireNumber.StatesWrapper>().value

        transform.origin shouldBe PresentationAlignment.CENTER_START
        transform.perspective shouldBe 0.002
        transform.scale shouldBe null
        rotate.fallback.literalFloat() shouldBe 0.0
        rotate.rules
            .single()
            .match.required shouldBe listOf(SELECTED)
        rotate.rules
            .single()
            .match.excluded shouldBe listOf(HOVERED)
        rotate.rules
            .single()
            .value
            .literalFloat() shouldBe 0.05
        transform.translateX?.literalFloat() shouldBe 3.0
        transform.transition?.selected shouldBe
            PresentationTransition.TimedWrapper(PresentationTimedTransition(milliseconds = 750, curve = null))
    }

    test("a container shadow encodes its color, blur and offsets, with unset offsets and spread at zero") {
        val accent = literalColor(Color(0xff3366ccu))
        val wireAccent =
            buildPresentation { container(ContainerStyle(background = accent)) {} }
                .layout
                .elementsOf<PresentationElement.ContainerWrapper>()
                .single()
                .value.backgroundColor
        val shadow =
            buildPresentation {
                size(width = 175.0, maximumHeight = 230.0) {
                    container(
                        ContainerStyle(
                            background = accent,
                            shadows = listOf(PresentationShadow(accent.withAlpha(0.4), blur = 8.0, offsetY = 2.0)),
                        ),
                    ) {}
                }
            }.layout
                .singleFixed()
                .element
                .shouldBeInstanceOf<PresentationElement.SizeWrapper>()
                .value.child
                .singleFixed()
                .element
                .shouldBeInstanceOf<PresentationElement.ContainerWrapper>()
                .value.shadows
                .single()
        val color = shadow.color.shouldBeInstanceOf<WireColor.AlphaWrapper>().value

        listOf(shadow.blur, shadow.spread, shadow.offsetX, shadow.offsetY) shouldBe listOf(8.0, 0.0, 0.0, 2.0)
        color.alpha shouldBe 0.4
        color.source shouldBe
            wireAccent
    }

    test("a brightness color keeps an adjusted light variant and a state driven dark variant over the same source") {
        val accent = literalColor(Color(0xff3366ccu))
        val wireAccent =
            buildPresentation { container(ContainerStyle(background = accent)) {} }
                .layout
                .elementsOf<PresentationElement.ContainerWrapper>()
                .single()
                .value.backgroundColor
        val brightness =
            buildPresentation {
                container(
                    ContainerStyle(
                        background =
                            brightnessColor(
                                light = accent.adjusted(lightness = 0.3, chroma = -0.3),
                                dark = stateColor(accent) { whenAll(FOCUSED, color = accent.adjusted(lightness = -0.5)) },
                            ),
                    ),
                ) {}
            }.layout
                .singleFixed()
                .element
                .shouldBeInstanceOf<PresentationElement.ContainerWrapper>()
                .value
                .backgroundColor
                .shouldNotBeNull()
                .shouldBeInstanceOf<WireColor.BrightnessWrapper>()
                .value
        val light = brightness.light.shouldBeInstanceOf<WireColor.AdjustedWrapper>().value
        val dark = brightness.dark.shouldBeInstanceOf<WireColor.StatesWrapper>().value
        val focused = dark.rules.single()

        listOf(light.lightness, light.chroma) shouldBe listOf(0.3, -0.3)
        light.source shouldBe
            wireAccent
        dark.fallback shouldBe
            wireAccent
        focused.match.required shouldBe listOf(FOCUSED)
        focused.color shouldBe
            buildPresentation {
                container(ContainerStyle(background = accent.adjusted(lightness = -0.5))) {
                }
            }.layout
                .singleFixed()
                .element
                .shouldBeInstanceOf<PresentationElement.ContainerWrapper>()
                .value
                .backgroundColor
                .shouldNotBeNull()
    }

    test("an adjustment outside minus one to one is refused") {
        shouldThrow<IllegalArgumentException> {
            literalColor(Color(0xff3366ccu)).adjusted(lightness = 1.5)
        }.message shouldBe "Presentation lightness must be between minus one and one."
    }
}
