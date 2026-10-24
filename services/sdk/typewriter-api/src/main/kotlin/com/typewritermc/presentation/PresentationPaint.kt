package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.expression.literal
import skirout.editor.v1.presentation.PresentationCurve as WireCurve
import skirout.editor.v1.presentation.PresentationInteractionState as WireState
import skirout.editor.v1.presentation.PresentationNumber as WireNumber
import skirout.editor.v1.presentation.PresentationShadow as WireShadow
import skirout.editor.v1.presentation.PresentationStateMatch as WireStateMatch
import skirout.editor.v1.presentation.PresentationStateNumberRule as WireStateNumberRule
import skirout.editor.v1.presentation.PresentationStateTransitionRule as WireStateTransitionRule
import skirout.editor.v1.presentation.PresentationTransition as WireTransition
import skirout.editor.v1.presentation.PresentationTransitionPolicy as WireTransitionPolicy

/**
 * Holds when every [required] state is active and no [excluded] state is. The panel owns the states; presentations
 * only declare which values apply in which of them. Colors, numbers and transitions share this match.
 */
data class PresentationStateMatch(
    val required: Set<PresentationInteractionState>,
    val excluded: Set<PresentationInteractionState> = emptySet(),
) {
    init {
        require(required.intersect(excluded).isEmpty()) { "Presentation states cannot be both required and excluded." }
    }
}

/** A number that may change with interaction state, in the unit of the property holding it. */
sealed interface PresentationNumber {
    data class Value(
        val expression: Expr<Double, Handled>,
    ) : PresentationNumber

    /** Ordered rules use the first match. The fallback covers every other state. */
    data class States(
        val rules: List<PresentationStateNumberRule>,
        val fallback: Expr<Double, Handled>,
    ) : PresentationNumber
}

data class PresentationStateNumberRule(
    val match: PresentationStateMatch,
    val value: Expr<Double, Handled>,
)

class PresentationStateNumberScope internal constructor() {
    internal val rules = mutableListOf<PresentationStateNumberRule>()

    fun whenAll(
        vararg required: PresentationInteractionState,
        excluded: Set<PresentationInteractionState> = emptySet(),
        value: Expr<Double, Handled>,
    ) {
        rules += PresentationStateNumberRule(PresentationStateMatch(required.toSet(), excluded), value)
    }

    fun whenAll(
        vararg required: PresentationInteractionState,
        excluded: Set<PresentationInteractionState> = emptySet(),
        value: Double,
    ) = whenAll(*required, excluded = excluded, value = literal(value))
}

fun number(value: Double): PresentationNumber = PresentationNumber.Value(literal(value))

fun number(value: Expr<Double, Handled>): PresentationNumber = PresentationNumber.Value(value)

/** Declares ordered rules for a number that follows interaction state, such as a scale that grows on hover. */
fun stateNumber(
    fallback: Expr<Double, Handled>,
    configure: PresentationStateNumberScope.() -> Unit,
): PresentationNumber {
    val scope = PresentationStateNumberScope().apply(configure)
    return PresentationNumber.States(scope.rules.toList(), fallback)
}

fun stateNumber(
    fallback: Double,
    configure: PresentationStateNumberScope.() -> Unit,
): PresentationNumber = stateNumber(literal(fallback), configure)

/** How an animated change progresses over its duration. */
sealed interface PresentationCurve {
    data object Linear : PresentationCurve

    data object EaseInOut : PresentationCurve

    data object EaseOut : PresentationCurve

    /** Quick start and long settle, for movement that should feel deliberate. */
    data object Emphasized : PresentationCurve

    /** Springs past the target and settles; [period] is the overshoot period in curve progress units. */
    data class ElasticOut(
        val period: Double,
    ) : PresentationCurve {
        init {
            require(period.isFinite() && period > 0.0) { "Elastic curve periods must be finite and positive." }
        }
    }
}

data class PresentationTransition(
    val milliseconds: Int,
    val curve: PresentationCurve = PresentationCurve.Linear,
) {
    init {
        require(milliseconds >= 0) { "Presentation transitions cannot have a negative duration." }
    }
}

/** Chooses how a change animates by the state being entered: the first matching rule, otherwise [fallback]. */
data class PresentationTransitionPolicy(
    val rules: List<PresentationStateTransitionRule>,
    val fallback: PresentationTransition,
)

data class PresentationStateTransitionRule(
    val match: PresentationStateMatch,
    val transition: PresentationTransition,
)

class PresentationStateTransitionScope internal constructor() {
    internal val rules = mutableListOf<PresentationStateTransitionRule>()

    fun whenAll(
        vararg required: PresentationInteractionState,
        excluded: Set<PresentationInteractionState> = emptySet(),
        transition: PresentationTransition,
    ) {
        rules += PresentationStateTransitionRule(PresentationStateMatch(required.toSet(), excluded), transition)
    }
}

/**
 * Declares how changes animate by the state being entered, such as a spring when a card becomes selected and an
 * ease back otherwise. Without rules, every change uses [fallback].
 */
fun stateTransition(
    fallback: PresentationTransition,
    configure: PresentationStateTransitionScope.() -> Unit = {},
): PresentationTransitionPolicy {
    val scope = PresentationStateTransitionScope().apply(configure)
    return PresentationTransitionPolicy(scope.rules.toList(), fallback)
}

/** A shadow below a container. Blur, spread and offsets are in logical pixels. */
data class PresentationShadow(
    val color: PresentationColor,
    val blur: Double = 0.0,
    val spread: Double = 0.0,
    val offsetX: Double = 0.0,
    val offsetY: Double = 0.0,
) {
    init {
        require(blur.isFinite() && blur >= 0.0) { "Shadow blur must be finite and nonnegative." }
        require(spread.isFinite() && offsetX.isFinite() && offsetY.isFinite()) { "Shadow spread and offsets must be finite." }
    }
}

/**
 * Paints a child scaled, rotated and translated around [origin]. Paint only: layout and the host hit region keep the
 * untransformed bounds. Rotations are in turns, translations in logical pixels, and [perspective] is the Matrix4 entry
 * (3, 2); zero keeps the transform flat.
 */
data class TransformStyle(
    val origin: PresentationAlignment = PresentationAlignment.Center,
    val perspective: Double = 0.0,
    val scale: PresentationNumber? = null,
    val rotateX: PresentationNumber? = null,
    val rotateY: PresentationNumber? = null,
    val rotateZ: PresentationNumber? = null,
    val translateX: PresentationNumber? = null,
    val translateY: PresentationNumber? = null,
    val transition: PresentationTransitionPolicy? = null,
) {
    init {
        require(perspective.isFinite()) { "Transform perspective must be finite." }
    }
}

internal fun PresentationStateMatch.wire(): WireStateMatch =
    WireStateMatch(
        required = required.map { it.wire() },
        excluded = excluded.map { it.wire() },
    )

internal fun PresentationNumber.wire(): WireNumber =
    when (this) {
        is PresentationNumber.Value -> {
            WireNumber.ValueWrapper(expression(expression))
        }

        is PresentationNumber.States -> {
            WireNumber.createStates(
                rules = rules.map { rule -> WireStateNumberRule(match = rule.match.wire(), value = expression(rule.value)) },
                fallback = expression(fallback),
            )
        }
    }

internal fun PresentationTransitionPolicy.wire(): WireTransitionPolicy =
    WireTransitionPolicy(
        rules = rules.map { rule -> WireStateTransitionRule(match = rule.match.wire(), transition = rule.transition.wire()) },
        fallback = fallback.wire(),
    )

private fun PresentationTransition.wire(): WireTransition =
    WireTransition(
        milliseconds = milliseconds,
        curve =
            when (val curve = curve) {
                PresentationCurve.Linear -> WireCurve.LINEAR
                PresentationCurve.EaseInOut -> WireCurve.EASE_IN_OUT
                PresentationCurve.EaseOut -> WireCurve.EASE_OUT
                PresentationCurve.Emphasized -> WireCurve.EMPHASIZED
                is PresentationCurve.ElasticOut -> WireCurve.ElasticOutWrapper(curve.period)
            },
    )

internal fun PresentationShadow.wire(): WireShadow =
    WireShadow(
        color = color.wire(),
        blur = blur,
        spread = spread,
        offsetX = offsetX,
        offsetY = offsetY,
    )

internal fun PresentationInteractionState.wire(): WireState =
    when (this) {
        PresentationInteractionState.Hovered -> WireState.HOVERED
        PresentationInteractionState.Selected -> WireState.SELECTED
        PresentationInteractionState.Focused -> WireState.FOCUSED
        PresentationInteractionState.Pressed -> WireState.PRESSED
        PresentationInteractionState.Disabled -> WireState.DISABLED
        PresentationInteractionState.ReadOnly -> WireState.READ_ONLY
        PresentationInteractionState.Invalid -> WireState.INVALID
        PresentationInteractionState.Routed -> WireState.ROUTED
        PresentationInteractionState.DropAccepted -> WireState.DROP_ACCEPTED
        PresentationInteractionState.DropRejected -> WireState.DROP_REJECTED
    }
