package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.expression.literal
import com.typewritermc.types.requireValid
import skirout.editor.v1.presentation.PresentationAlignment
import skirout.editor.v1.presentation.PresentationInteractionState
import skirout.editor.v1.presentation.PresentationSpring
import skirout.editor.v1.presentation.PresentationStateMatch
import skirout.editor.v1.presentation.PresentationTimedCurve
import skirout.editor.v1.presentation.PresentationTimedTransition
import skirout.editor.v1.presentation.PresentationTransition
import skirout.editor.v1.presentation.PresentationTransitionPolicy
import skirout.editor.v1.presentation.PresentationNumber as WireNumber
import skirout.editor.v1.presentation.PresentationShadow as WireShadow
import skirout.editor.v1.presentation.PresentationStateNumberRule as WireStateNumberRule

/**
 * Holds when every [required] state is active and no [excluded] state is. The panel owns the states; presentations
 * only declare which values apply in which of them. Colors and numbers share this match.
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

/** A curve that runs over a duration, replacing the panel move's own. */
sealed interface TimedCurve {
    /** Arrives early and overshoots once by [overshoot], a fraction of the travel. */
    data class Strike(
        val overshoot: Double,
    ) : TimedCurve {
        init {
            require(overshoot.isFinite() && overshoot > 0.0 && overshoot < 1.0) { "Strike overshoot must be between 0 and 1." }
        }
    }

    /** Hits the target and recoils once by [recoil], a fraction of the travel. */
    data class Carriage(
        val recoil: Double,
    ) : TimedCurve {
        init {
            require(recoil.isFinite() && recoil >= 0.0 && recoil < 1.0) { "Carriage recoil must be at least 0 and below 1." }
        }
    }

    /** Leaves quickly, with no bounce. */
    data object Exit : TimedCurve

    data object EaseOut : TimedCurve

    data object Linear : TimedCurve
}

/** Replaces how one of the panel's moves plays. Reduced motion still applies after it. */
sealed interface MoveOverride {
    /**
     * Replaces the [length], the [curve], or both. A spring move given only a length settles in that time with its
     * own damping ratio; a length of 0 lands at once.
     */
    data class Timed(
        val length: DisplayDelay? = null,
        val curve: TimedCurve? = null,
    ) : MoveOverride {
        init {
            require(length != null || curve != null) { "A timed override replaces a length, a curve or both." }
        }
    }

    /** Plays a spring of [stiffness] and [damping] at unit mass; it settles by itself. */
    data class Spring(
        val stiffness: Double,
        val damping: Double,
    ) : MoveOverride {
        init {
            require(stiffness.isFinite() && stiffness > 0.0 && damping.isFinite() && damping > 0.0) {
                "Spring stiffness and damping must be finite and positive."
            }
        }
    }
}

private fun TimedCurve.wire(): PresentationTimedCurve =
    when (this) {
        is TimedCurve.Strike -> PresentationTimedCurve.StrikeWrapper(overshoot)
        is TimedCurve.Carriage -> PresentationTimedCurve.CarriageWrapper(recoil)
        TimedCurve.Exit -> PresentationTimedCurve.EXIT
        TimedCurve.EaseOut -> PresentationTimedCurve.EASE_OUT
        TimedCurve.Linear -> PresentationTimedCurve.LINEAR
    }

internal fun MoveOverride.wire(): PresentationTransition =
    when (this) {
        is MoveOverride.Timed -> {
            PresentationTransition.TimedWrapper(
                PresentationTimedTransition(milliseconds = length?.milliseconds, curve = curve?.wire()),
            )
        }

        is MoveOverride.Spring -> {
            PresentationTransition.SpringWrapper(PresentationSpring(stiffness = stiffness, damping = damping))
        }
    }

/**
 * Overrides how the panel's own moves play, by the state whose change the move belongs to: [hovered] for hoverIn
 * and hoverOut, [focused] for focusMove, [pressed] for press, [selected] for ink. Without it, or for a state left
 * null, the panel's move plays as tuned. Example: `moveOverrides(selected = MoveOverride.Spring(280.0, 17.0))`.
 */
fun moveOverrides(
    hovered: MoveOverride? = null,
    focused: MoveOverride? = null,
    pressed: MoveOverride? = null,
    selected: MoveOverride? = null,
): PresentationTransitionPolicy =
    PresentationTransitionPolicy(
        hovered = hovered?.wire(),
        focused = focused?.wire(),
        pressed = pressed?.wire(),
        selected = selected?.wire(),
    )

/**
 * Rejects what the wire can still carry but the panel cannot play: a negative duration, a curve value outside its
 * family, a spring that is not finite and positive, and unknown variants. Hand built wire values reach the layout
 * encoders, so they meet the same rules as the builders.
 */
internal fun PresentationTransition.requireValid(): PresentationTransition =
    apply {
        when (val transition = this) {
            is PresentationTransition.TimedWrapper -> transition.value.requireValid()
            is PresentationTransition.SpringWrapper -> transition.value.requireValid()
            else -> throw IllegalArgumentException("Presentation transition is unknown.")
        }
    }

private fun PresentationTimedTransition.requireValid() {
    milliseconds?.let { require(it >= 0) { "Presentation transitions cannot have a negative duration." } }
    curve?.requireValid()
}

private fun PresentationTimedCurve.requireValid() {
    when (val curve = this) {
        PresentationTimedCurve.EXIT, PresentationTimedCurve.EASE_OUT, PresentationTimedCurve.LINEAR -> {
            Unit
        }

        is PresentationTimedCurve.StrikeWrapper -> {
            require(curve.value.isFinite() && curve.value > 0.0 && curve.value < 1.0) {
                "Strike overshoot must be between 0 and 1."
            }
        }

        is PresentationTimedCurve.CarriageWrapper -> {
            require(curve.value.isFinite() && curve.value >= 0.0 && curve.value < 1.0) {
                "Carriage recoil must be at least 0 and below 1."
            }
        }

        else -> {
            throw IllegalArgumentException("Presentation transition curve is unknown.")
        }
    }
}

private fun PresentationSpring.requireValid() {
    require(stiffness.isFinite() && stiffness > 0.0 && damping.isFinite() && damping > 0.0) {
        "Spring stiffness and damping must be finite and positive."
    }
}

/** Validates every override of the policy where it enters the presentation wire form. */
internal fun PresentationTransitionPolicy.requireValid(): PresentationTransitionPolicy =
    apply {
        listOfNotNull(hovered, focused, pressed, selected).forEach { it.requireValid() }
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

internal fun PresentationNumber.wire(state: PresentationBuildState): WireNumber =
    when (this) {
        is PresentationNumber.Value -> {
            WireNumber.ValueWrapper(state.lower(expression, DOUBLE_SLOT))
        }

        is PresentationNumber.States -> {
            WireNumber.createStates(
                rules = rules.map { rule -> WireStateNumberRule(match = rule.match, value = state.lower(rule.value, DOUBLE_SLOT)) },
                fallback = state.lower(fallback, DOUBLE_SLOT),
            )
        }
    }

internal fun PresentationShadow.wire(state: PresentationBuildState): WireShadow =
    WireShadow(
        color = color.wire(state),
        blur = blur,
        spread = spread,
        offsetX = offsetX,
        offsetY = offsetY,
    )
