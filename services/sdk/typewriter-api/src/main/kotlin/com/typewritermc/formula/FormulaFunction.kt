package com.typewritermc.formula

import com.typewritermc.types.EvaluationValues
import skirout.editor.v1.type_catalog.FunctionTypeTemplate
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeTemplate

/**
 * One function formulas can call, generated from a `@TypewriterFormulaProvider` member or written by core.
 *
 * The signature uses the catalog's own type forms and never reaches a contract. Its context holds the receiver
 * first, named `this`; its parameters are what a call passes. Each type parameter is owned by a synthetic id,
 * `qualified("formula", "<provider>.<function>")`, so it cannot collide with a catalog definition's parameters.
 * [invoke] takes the evaluation values of the context slots, then of the parameters, and returns an evaluation value;
 * a parameter in [defaulted] may be [NotProvided], and the Kotlin default applies.
 */
class FormulaFunction(
    val name: String,
    val typeParameters: List<TypeParameter>,
    val signature: FunctionTypeTemplate,
    val defaulted: Set<String>,
    val invoke: FormulaCall.(arguments: List<Any?>) -> Any?,
) {
    override fun toString(): String = "FormulaFunction($name)"
}

/** Passed for a parameter a call left out, so the generated call uses the Kotlin default. */
data object NotProvided

/** The provider codegen emits for one `@TypewriterFormulaProvider` object. */
interface GeneratedFormulaProvider {
    val functions: List<FormulaFunction>
}

/**
 * One call of a formula function. A generated provider converts at its own edge with [intoKotlin] and [fromKotlin];
 * a core function works on evaluation values directly. The interpreter implements it for each call.
 */
interface FormulaCall : EvaluationValues {
    /** The Kotlin value of [value] at the declared [type], with this call's solved type arguments applied. */
    fun intoKotlin(
        value: Any?,
        type: TypeTemplate,
    ): Any?

    /** The evaluation value of a Kotlin [value] at the declared [type]. */
    fun fromKotlin(
        value: Any?,
        type: TypeTemplate,
    ): Any?

    /** [value] as creator text. */
    fun display(value: Any?): String
}

/** Why one evaluation failed. The interpreter adds the failures only it can detect. */
sealed interface FormulaFailure {
    /** A provider threw; [message] is what it said. */
    data class ProviderThrew(
        val message: String,
    ) : FormulaFailure

    data object Overflow : FormulaFailure

    data object DivisionByZero : FormulaFailure

    /** A floating point result was infinite or not a number. */
    data object NotFinite : FormulaFailure

    data object RecursionLimit : FormulaFailure

    data object StepLimit : FormulaFailure
}

/** What a provider throws to fail one evaluation with a stated [reason]. */
class FormulaFailureException(
    val reason: FormulaFailure,
) : RuntimeException(reason.toString())
