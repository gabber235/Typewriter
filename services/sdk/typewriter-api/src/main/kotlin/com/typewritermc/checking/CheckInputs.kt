package com.typewritermc.checking

import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.CompleteValue
import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.configuration.RelativeFieldPattern
import com.typewritermc.configuration.RuleOrigin
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeTemplate

data class CheckInput(
    val owner: TypeDefinitionId,
    val path: RelativeFieldPattern,
    val expected: TypeTemplate,
    val skipNull: Boolean = false,
)

data class CheckRecipe(
    val owner: RuleOrigin,
    val inputs: List<CheckInput>,
    val predicate: RegisteredPredicate,
    val diagnostic: DiagnosticTemplate,
)

interface CheckInputs {
    context(reads: AuthoredReads)
    fun evaluate(
        recipe: CheckRecipe,
        subject: DraftBinding,
    ): CheckEvaluation
}

interface DiagnosticReporter {
    fun report(diagnostic: Diagnostic)
}

data class CheckEvaluation(
    val outcome: CheckOutcome,
    val findings: List<Diagnostic>,
)

interface RegisteredPredicate {
    val inputTypes: List<TypeTemplate>

    fun invoke(completeInputs: List<CompleteValue>): Boolean
}

interface CheckAssertion {
    fun error(
        message: String,
        at: ValueLocation,
        related: List<ValueLocation> = emptyList(),
    )
}

fun <T> CheckContext.check(
    input: Availability<T>,
    predicate: (T) -> Boolean,
): CheckAssertion = assertion(listOf(input)) { values -> predicate(values.single() as T) }

fun <A, B> CheckContext.check(
    first: Availability<A>,
    second: Availability<B>,
    predicate: (A, B) -> Boolean,
): CheckAssertion = assertion(listOf(first, second)) { values -> predicate(values[0] as A, values[1] as B) }

private fun CheckContext.assertion(
    inputs: List<Availability<*>>,
    predicate: (List<Any?>) -> Boolean,
): CheckAssertion = RuntimeCheckAssertion(this, inputs, predicate)

private class RuntimeCheckAssertion(
    private val context: CheckContext,
    inputs: List<Availability<*>>,
    predicate: (List<Any?>) -> Boolean,
) : CheckAssertion {
    private val violated =
        inputs.all { it is Availability.Available } &&
            !predicate(inputs.map { (it as Availability.Available).value })

    override fun error(
        message: String,
        at: ValueLocation,
        related: List<ValueLocation>,
    ) {
        if (violated) context.report(message, at, related)
    }
}
