package com.typewritermc.formula.eval

import com.typewritermc.formula.FormulaFailure
import com.typewritermc.formula.FormulaLimits
import com.typewritermc.formula.check.CheckedBinding
import com.typewritermc.formula.check.CheckedExpression
import com.typewritermc.types.EvaluationValues
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.Ref
import com.typewritermc.types.RelationshipEndpoint
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceId
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation

/** What evaluating one formula gave. */
sealed interface Evaluation<out T> {
    data class Value<T>(
        val value: T,
    ) : Evaluation<T>

    /** The evaluation failed for [reason]; [at] is the formula that failed. */
    data class Failed(
        val at: ValueLocation,
        val reason: FormulaFailure,
    ) : Evaluation<Nothing>

    /** The formula has problems, or needs a context the realm lacks, so it was not run. Not an error. */
    data object NotEvaluated : Evaluation<Nothing>
}

/**
 * What stops one evaluation. Thrown through the interpreter and every provider call, and turned into
 * [Evaluation.Failed] at the evaluation's boundary. It carries no stack trace: it is control flow. [cause] is what a
 * provider threw, when the failure came from one.
 */
class FailedEvaluation(
    val reason: FormulaFailure,
    cause: Throwable? = null,
) : RuntimeException(reason.toString(), cause, false, false)

/**
 * A function value: a lambda, a local function, a function Definition's body or a provider function used as a value.
 * It holds no graph frame: its body runs in the environment of whoever calls it, so that caller records the body's
 * reads and reruns when they change. Plain data, so it compares by value for early cutoff. A local function names
 * itself as [self], so its body can call it without the value holding itself.
 */
data class FunctionValue(
    val tree: CheckedExpression,
    val parameters: List<CheckedBinding>,
    val captured: Map<String, Any?>,
    val at: ValueLocation,
    val self: String? = null,
)

/** A reference to [target], as evaluation holds one: the Kotlin Ref, whose endpoint type is erased at runtime. */
fun refTo(target: ResourceId): Ref<*, *> = Ref<RelationshipEndpoint<Resource, Resource>, Resource>(target)

/** The bounds of one evaluation: user function depth and the number of steps. */
data class EvaluationLimits(
    val maxDepth: Int = FormulaLimits.MAX_DEPTH,
    val maxSteps: Int = FormulaLimits.MAX_STEPS,
)

/** What evaluation asks the world. In the realm every answer is a tracked read of the running query. */
interface EvaluationEnvironment : EvaluationValues {
    /** The value of [field] on the resource [resource]: a Var or function typed field stays deferred until resolved. */
    fun fieldOf(
        resource: ResourceId,
        field: String,
    ): Any?

    /** What naming [resource] gives: its exported value, or a Ref to it when it exports nothing. */
    fun exported(resource: ResourceId): Any?

    /** The native binding of an applied type. */
    fun binding(type: TypeUse): NativeBinding<*>

    /**
     * A record of [type] from the fields a constructor call gave: a content record is its RecordValue at its expanded
     * type; a code record runs its Kotlin constructor, with omitted defaulted fields taking their Kotlin defaults.
     */
    fun construct(
        type: TypeUse,
        fields: Map<String, Any?>,
    ): Any?

    /** Whether [value] is a value of [type], for `is`, `as?` and a `when` arm. */
    fun isA(
        value: Any?,
        type: TypeUse,
    ): Boolean

    /**
     * [value] as creator text, the body of the generic interpolate: forced; null and every scalar exactly as a rule
     * template shows it, a list as `[a, b]`, a map as `[k: v]`, a record as `Reward(gold = 5)`, a case by its name, a
     * Ref as its target's name.
     */
    fun display(value: Any?): String

    /** Stops a run whose answer can no longer be used, such as a stale revision. */
    fun ensureCurrent()
}
