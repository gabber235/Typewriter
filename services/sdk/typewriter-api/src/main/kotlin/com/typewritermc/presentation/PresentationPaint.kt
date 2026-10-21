package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.expression.literal
import skirout.editor.v1.presentation.PresentationAlignment
import skirout.editor.v1.presentation.PresentationCurve
import skirout.editor.v1.presentation.PresentationInteractionState
import skirout.editor.v1.presentation.PresentationStateMatch
import skirout.editor.v1.presentation.PresentationStateTransitionRule
import skirout.editor.v1.presentation.PresentationTransition
import skirout.editor.v1.presentation.PresentationTransitionPolicy
import skirout.editor.v1.presentation.PresentationNumber as WireNumber
import skirout.editor.v1.presentation.PresentationShadow as WireShadow
import skirout.editor.v1.presentation.PresentationStateNumberRule as WireStateNumberRule

/**
 * Holds when every [required] state is active and no [excluded] state is. The panel owns the states; presentations
 * only declare which values apply in which of them. Colors, numbers and transitions share this match.
 */
internal fun stateMatch(
    required: Set<PresentationInteractionState>,
    excluded: Set<PresentationInteractionState>,
): PresentationStateMatch {
    require(required.intersect(excluded).isEmpty()) { "Presentation states cannot be both required and excluded." }
    return PresentationStateMatch(required = required, excluded = excluded)
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
        rules += PresentationStateNumberRule(stateMatch(required.toSet(), excluded), value)
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

/**
 * An animated change of [milliseconds] that progresses along [curve], such as
 * `transition(750, PresentationCurve.ElasticOutWrapper(0.9))` for a spring whose overshoot period is 0.9.
 */
fun transition(
    milliseconds: Int,
    curve: PresentationCurve = PresentationCurve.LINEAR,
): PresentationTransition = PresentationTransition(milliseconds = milliseconds, curve = curve).requireValid()

/** Rejects negative durations, elastic periods that are not finite and positive, and unknown curves. */
internal fun PresentationTransition.requireValid(): PresentationTransition =
    apply {
        require(milliseconds >= 0) { "Presentation transitions cannot have a negative duration." }
        when (val curve = curve) {
            PresentationCurve.LINEAR, PresentationCurve.EASE_IN_OUT, PresentationCurve.EASE_OUT, PresentationCurve.EMPHASIZED -> {
                Unit
            }

            is PresentationCurve.ElasticOutWrapper -> {
                require(curve.value.isFinite() && curve.value > 0.0) { "Elastic curve periods must be finite and positive." }
            }

            else -> {
                throw IllegalArgumentException("Presentation transition curve is unknown.")
            }
        }
    }

/** Validates every transition of the policy where it enters the presentation wire form. */
internal fun PresentationTransitionPolicy.requireValid(): PresentationTransitionPolicy =
    apply {
        rules.forEach { rule -> rule.transition.requireValid() }
        fallback.requireValid()
    }

class PresentationStateTransitionScope internal constructor() {
    internal val rules = mutableListOf<PresentationStateTransitionRule>()

    fun whenAll(
        vararg required: PresentationInteractionState,
        excluded: Set<PresentationInteractionState> = emptySet(),
        transition: PresentationTransition,
    ) {
        rules +=
            PresentationStateTransitionRule(match = stateMatch(required.toSet(), excluded), transition = transition.requireValid())
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
    return PresentationTransitionPolicy(rules = scope.rules, fallback = fallback.requireValid())
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
    val origin: PresentationAlignment = PresentationAlignment.CENTER,
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

internal fun PresentationNumber.wire(): WireNumber =
    when (this) {
        is PresentationNumber.Value -> {
            WireNumber.ValueWrapper(expression(expression))
        }

        is PresentationNumber.States -> {
            WireNumber.createStates(
                rules = rules.map { rule -> WireStateNumberRule(match = rule.match, value = expression(rule.value)) },
                fallback = expression(fallback),
            )
        }
    }

internal fun PresentationShadow.wire(): WireShadow =
    WireShadow(
        color = color.wire(),
        blur = blur,
        spread = spread,
        offsetX = offsetX,
        offsetY = offsetY,
    )
