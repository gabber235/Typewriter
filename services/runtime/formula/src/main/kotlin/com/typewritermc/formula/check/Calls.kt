package com.typewritermc.formula.check

import com.typewritermc.formula.FormulaFunction
import com.typewritermc.formula.TextSpan
import com.typewritermc.formula.syntax.Call
import com.typewritermc.formula.syntax.Expression
import com.typewritermc.formula.syntax.Lambda
import com.typewritermc.formula.syntax.ListLiteral
import com.typewritermc.formula.syntax.Literal
import com.typewritermc.formula.syntax.MapLiteral
import com.typewritermc.formula.syntax.Member
import com.typewritermc.formula.syntax.Name
import com.typewritermc.formula.syntax.NameBinding
import com.typewritermc.formula.syntax.Shorthand
import com.typewritermc.formula.syntax.Unary
import com.typewritermc.types.functionUse
import com.typewritermc.types.parameterKeys
import com.typewritermc.types.toTemplate
import skirout.editor.v1.type_catalog.FunctionParameterTemplate
import skirout.editor.v1.type_catalog.FunctionTypeUse
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse

// Calls: each candidate checks in a trace of its own, and the one that fits with the most specific context types
// wins. A call solves its own type parameters from its receiver, its arguments and the expected type.

/** What a call can call: a formula function's signature, or a function value's type with no type parameters. */
internal class Signature(
    val context: List<FunctionParameterTemplate>,
    val parameters: List<FunctionParameterTemplate>,
    val result: TypeTemplate,
    val defaulted: Set<String>,
    val typeParameters: List<TypeParameter> = emptyList(),
) {
    val slots: List<FunctionParameterTemplate> get() = context + parameters
}

internal val FormulaFunction.callSignature: Signature
    get() = Signature(signature.context, signature.parameters, signature.result, defaulted, typeParameters)

internal val FunctionTypeUse.callSignature: Signature
    get() {
        val template = (TypeUse.FunctionWrapper(this).toTemplate() as TypeTemplate.FunctionWrapper).value
        return Signature(template.context, template.parameters, template.result, emptySet())
    }

/** One argument of a call: written in the source, or already checked, such as a `when` subject. */
internal sealed interface CallArgument {
    val name: Name?
    val span: TextSpan

    data class Written(
        override val name: Name?,
        val value: Expression,
        override val span: TextSpan,
    ) : CallArgument

    data class Given(
        val node: CheckedExpression,
    ) : CallArgument {
        override val name: Name? get() = null
        override val span: TextSpan get() = node.span
    }
}

/** One candidate checked against a call: the argument per slot, the solved type parameters and the result. */
internal class Trial(
    val arguments: List<CheckedExpression?>,
    val solved: Map<ParameterKey, TypeUse>,
    val contextTypes: List<TypeUse>,
    val result: TypeUse,
    val trace: Trace,
    val receiverFits: Boolean,
)

/** What one candidate's check has placed and solved so far. */
private class CallState(
    val signature: Signature,
) {
    val slots = signature.slots
    val solved = mutableMapOf<ParameterKey, TypeUse>()
    val assigned = arrayOfNulls<CallArgument>(slots.size)
    val checked = arrayOfNulls<CheckedExpression>(slots.size)
    var receiverFits = true
}

/**
 * Checks a call of [signature] in a trace of its own: [receiver] fills the first context slot, named arguments their
 * slot, extra positional arguments the context slots in order and the rest the parameters, and what is left of the
 * context fills from scope by type.
 */
internal fun Checker.attempt(
    signature: Signature,
    receiver: CheckedExpression?,
    receiverType: TypeUse?,
    arguments: List<CallArgument>,
    expected: TypeUse?,
    span: TextSpan,
    scope: Scope,
): Trial {
    val state = CallState(signature)
    val trace =
        forked {
            if (receiver != null) bindReceiver(state, receiver, receiverType ?: receiver.type)
            assign(state, receiver != null, arguments)
            solve(state, expected, scope)
            complete(state, receiver != null, span, scope)
            checkBounds(state, span)
        }
    val contextTypes = signature.context.map { it.type.applied(state.solved) ?: ERROR }
    return Trial(
        state.checked.toList(),
        state.solved,
        contextTypes,
        signature.result.applied(state.solved) ?: ERROR,
        trace,
        state.receiverFits,
    )
}

private fun Checker.bindReceiver(
    state: CallState,
    receiver: CheckedExpression,
    type: TypeUse,
) {
    if (state.signature.context.isEmpty() || !unify(state.slots[0].type, type, state.solved)) {
        state.receiverFits = false
        report(receiver.span, "formula_type_mismatch", "This does not apply to ${shown(type)}")
    } else {
        state.checked[0] = receiver
    }
}

/** Places each argument at its slot: by name, else positionally, extra positional ones filling context slots first. */
private fun Checker.assign(
    state: CallState,
    hasReceiver: Boolean,
    arguments: List<CallArgument>,
) {
    val slots = state.slots
    val assigned = state.assigned
    val positional = mutableListOf<CallArgument>()
    for (argument in arguments) {
        val name = argument.name
        if (name == null) {
            positional += argument
            continue
        }
        val index = slots.indexOfFirst { it.name == name.text }
        when {
            index < 0 || (index == 0 && hasReceiver) -> {
                report(
                    name.span,
                    "formula_unknown_parameter",
                    "There is no parameter `${name.text}`",
                )
            }

            assigned[index] != null -> {
                report(argument.span, "formula_argument_twice", "`${name.text}` is given twice")
            }

            else -> {
                assigned[index] = argument
            }
        }
    }
    val contextCount = state.signature.context.size
    val freeParameters = (contextCount until slots.size).filter { assigned[it] == null }
    val freeContext = ((if (hasReceiver) 1 else 0) until contextCount).filter { assigned[it] == null }
    val targets = freeContext.take((positional.size - freeParameters.size).coerceAtLeast(0)) + freeParameters
    positional.forEachIndexed { position, argument ->
        val index = targets.getOrNull(position)
        if (index ==
            null
        ) {
            report(argument.span, "formula_too_many_arguments", "This call takes no more arguments")
        } else {
            assigned[index] = argument
        }
    }
}

/** Arguments whose type does not depend on the slot go first, then the expected type, then the rest, function values last. */
private fun Checker.solve(
    state: CallState,
    expected: TypeUse?,
    scope: Scope,
) {
    val byRank =
        state.assigned.indices
            .filter { state.assigned[it] != null }
            .groupBy { rank(state.assigned[it]!!, state.slots[it].type) }
    for (index in byRank[0].orEmpty()) {
        state.checked[index] =
            argument(state.assigned[index]!!, state.slots[index].type, state.solved, scope)
    }
    val result = state.signature.result
    if (expected != null && result.applied(state.solved) == null) unify(result, expected, state.solved)
    for (index in byRank[1].orEmpty() + byRank[2].orEmpty()) {
        state.checked[index] = argument(state.assigned[index]!!, state.slots[index].type, state.solved, scope)
    }
}

/** Fills the context slots left open from scope, then reports missing parameters and type parameters left unsolved. */
private fun Checker.complete(
    state: CallState,
    hasReceiver: Boolean,
    span: TextSpan,
    scope: Scope,
) {
    val signature = state.signature
    val contextCount = signature.context.size
    for (index in 0 until contextCount) {
        if (state.checked[index] != null || state.assigned[index] != null || (index == 0 && hasReceiver)) continue
        state.checked[index] = fill(state.slots[index], state.solved, span, scope)
    }
    for (index in contextCount until state.slots.size) {
        if (state.assigned[index] == null && state.slots[index].name !in signature.defaulted) {
            report(span, "formula_missing_argument", "`${state.slots[index].name}` is missing")
        }
    }
    val free = (state.slots.map { it.type } + signature.result).flatMap { it.parameterKeys() }.filterNot { it in state.solved }
    if (free.isNotEmpty() && trace.problems.isEmpty()) {
        report(span, "formula_cannot_infer", "The types of this call cannot be inferred here; state them, as in `let x: List<Int> = ...`")
    }
}

/** Each solved type parameter must fit its bounds, as `T : Entity` needs an Entity. */
private fun Checker.checkBounds(
    state: CallState,
    span: TextSpan,
) {
    for (parameter in state.signature.typeParameters) {
        val actual = state.solved[parameter.key] ?: continue
        for (bound in parameter.bounds) {
            val wanted = bound.applied(state.solved) ?: continue
            if (!fits(actual, wanted)) {
                report(span, "formula_type_bound", "`${parameter.name}` must be a ${shown(wanted)}, but here it is a ${shown(actual)}")
            }
        }
    }
}

private fun rank(
    argument: CallArgument,
    slot: TypeTemplate,
): Int =
    when {
        argument is CallArgument.Given -> 0
        slot is TypeTemplate.FunctionWrapper -> 2
        isFlexible((argument as CallArgument.Written).value) -> 1
        else -> 0
    }

private fun Checker.argument(
    argument: CallArgument,
    slot: TypeTemplate,
    solved: MutableMap<ParameterKey, TypeUse>,
    scope: Scope,
): CheckedExpression {
    val wanted = slot.applied(solved)
    val node =
        when {
            argument is CallArgument.Given -> argument.node
            slot is TypeTemplate.FunctionWrapper -> functionArgument(argument as CallArgument.Written, slot, solved, scope)
            isFlexible((argument as CallArgument.Written).value) -> infer(argument.value, wanted, scope)
            else -> synthOnce(argument.value, scope)
        }
    if (wanted != null) {
        expect(node, wanted)
    } else if (!unify(slot, node.type, solved)) {
        report(argument.span, "formula_type_mismatch", "Expected ${shownTemplate(slot)}, found ${shown(node.type)}")
    }
    return node
}

/**
 * An argument where a function is wanted: its parameter types must be known, while its result may still be solved
 * from it. A parameter type the other arguments and the receiver left open comes from the lambda's own declaration,
 * as `pass { x: Int -> x + 1 }` solves `T` as Int.
 */
private fun Checker.functionArgument(
    argument: CallArgument.Written,
    slot: TypeTemplate.FunctionWrapper,
    solved: MutableMap<ParameterKey, TypeUse>,
    scope: Scope,
): CheckedExpression {
    val function = slot.value
    val lambda = argument.value as? Lambda
    function.parameters.forEachIndexed { index, parameter ->
        if (parameter.type.applied(solved) != null) return@forEachIndexed
        val declared = (lambda?.parameters?.getOrNull(index) as? NameBinding)?.type ?: return@forEachIndexed
        unify(parameter.type, lower(declared, scope), solved)
    }
    val parameters = function.parameters.map { it.name to (it.type.applied(solved) ?: return cannotInfer(argument)) }
    val context = function.context.map { it.name to (it.type.applied(solved) ?: return cannotInfer(argument)) }
    return infer(argument.value, functionUse(context, parameters, function.result.applied(solved) ?: ERROR), scope)
}

private fun Checker.cannotInfer(argument: CallArgument): CheckedExpression {
    report(argument.span, "formula_cannot_infer", "The type of this argument cannot be inferred here")
    return Invalid(ERROR, argument.span)
}

/** A context slot no argument fills: the one value of its type at the innermost level that has one. */
private fun Checker.fill(
    slot: FunctionParameterTemplate,
    solved: Map<ParameterKey, TypeUse>,
    span: TextSpan,
    scope: Scope,
): CheckedExpression? {
    val type = slot.type.applied(solved)
    if (type == null) {
        report(span, "formula_cannot_infer", "The type of `${slot.name}` cannot be inferred here")
        return null
    }
    val level = scope.levelsMatching { fits(it, type) }.firstOrNull()
    if (level == null) {
        report(span, "formula_context_unfillable", "This needs a ${shown(type)} as `${slot.name}`, and none is in scope")
        return null
    }
    if (level.size > 1) {
        report(
            span,
            "formula_context_ambiguous",
            "Several values could be `${slot.name}`: ${level.joinToString { "`${it.name}`" }}; pass one by name",
        )
        return null
    }
    val bound = level.single()
    if (bound.isContext) trace.context += bound.name
    return LocalRead(bound.name, bound.type!!, span)
}

/**
 * Calls one of [functions]: every candidate is tried, and among those that fit, the one with the most specific
 * context types wins. [operator] names the operator a call stands for, which a failure then names.
 */
internal fun Checker.callFunctions(
    functions: List<FormulaFunction>,
    receiver: CheckedExpression?,
    arguments: List<CallArgument>,
    expected: TypeUse?,
    safe: Boolean,
    span: TextSpan,
    scope: Scope,
    operator: String? = null,
): CheckedExpression {
    val nullRead = receiver != null && receiver.type.isNullable && !safe
    val candidates = if (nullRead) functions.filter { it.takesNullReceiver } else functions
    if (blocked(receiver, arguments, nullRead && candidates.isEmpty(), scope)) return Invalid(ERROR, span)
    val receiverType = if (nullRead) receiver?.type else receiver?.type?.nonNull()
    val wanted = if (safe) expected?.nonNull() else expected
    val trials = candidates.map { it to attempt(it.callSignature, receiver, receiverType, arguments, wanted, span, scope) }
    val (function, trial) = choose(trials, operator, receiverType, span) ?: return Invalid(ERROR, span)
    absorb(trial.trace)
    if (trial.trace.problems.isNotEmpty()) return Invalid(ERROR, span)
    trace.providers += function.name
    val result = if (safe && receiver?.type?.isNullable == true) trial.result.orNull() else trial.result
    return FunctionCall(function, trial.solved, trial.arguments, safe, result, span)
}

/**
 * Whether [this] takes any receiver, null included, because its receiver is an unbounded type parameter, as the
 * generic `interpolate` is, so `${maybe}` shows "null".
 */
private val FormulaFunction.takesNullReceiver: Boolean
    get() {
        val receiver = signature.context.firstOrNull()?.type as? TypeTemplate.ParameterWrapper ?: return false
        return typeParameters.any { it.key == receiver.value && it.bounds.isEmpty() }
    }

/**
 * True when an operand already failed or a nullable receiver is read without `?.` by a call that cannot take null
 * ([nullRead]); the call then adds no problem of its own.
 */
private fun Checker.blocked(
    receiver: CheckedExpression?,
    arguments: List<CallArgument>,
    nullRead: Boolean,
    scope: Scope,
): Boolean {
    val written = arguments.filterIsInstance<CallArgument.Written>()
    val rigid = written.filterNot { isFlexible(it.value) }.map { synthOnce(it.value, scope) }
    if (receiver?.type == ERROR || rigid.any { it.type == ERROR }) {
        for (argument in written.filter { isFlexible(it.value) && !isFunctionLike(it.value) }) infer(argument.value, null, scope)
        return true
    }
    if (receiver != null && nullRead) {
        report(receiver.span, "formula_nullable_read", "This may be null; use `?.` or `?:`")
        return true
    }
    return false
}

/** The candidate a call keeps, or null when the call failed and its problem is reported. */
private fun Checker.choose(
    trials: List<Pair<FormulaFunction, Trial>>,
    operator: String?,
    receiverType: TypeUse?,
    span: TextSpan,
): Pair<FormulaFunction, Trial>? {
    val applicable =
        trials.filter {
            it.second.trace.problems
                .isEmpty()
        }
    if (applicable.size == 1 || (applicable.isEmpty() && trials.size == 1)) return (applicable.ifEmpty { trials }).single()
    if (applicable.size > 1) {
        return mostSpecific(applicable) ?: run {
            absorb(applicable.first().second.trace)
            report(span, "formula_ambiguous_function", "Several `${trials.first().first.name}` fit here equally well")
            null
        }
    }
    // The candidate that came closest explains the failure. For an operator, a plain argument mismatch reads better
    // as the operator not applying to its operands.
    val best = trials.sortedWith(compareBy({ !it.second.receiverFits }, { it.second.trace.problems.size })).firstOrNull() ?: return null
    val problems = best.second.trace.problems
    if (operator == null || (best.second.receiverFits && problems.any { it.code != "formula_type_mismatch" })) return best
    problems.clear()
    absorb(best.second.trace)
    val operands =
        (
            listOfNotNull(receiverType) +
                best.second.arguments
                    .drop(1)
                    .mapNotNull { it?.type }
        ).joinToString(" and ") { shown(it) }
    report(span, "formula_type_mismatch", "`$operator` does not apply to $operands")
    return null
}

/** The candidate whose context types fit every other's, when exactly one does. */
private fun Checker.mostSpecific(candidates: List<Pair<FormulaFunction, Trial>>): Pair<FormulaFunction, Trial>? {
    fun Trial.atMost(other: Trial) =
        contextTypes.size == other.contextTypes.size && contextTypes.zip(other.contextTypes).all { (a, b) -> fits(a, b) }
    return candidates.singleOrNull { (_, trial) ->
        candidates.all { (_, other) ->
            trial === other ||
                (trial.atMost(other) && !other.atMost(trial))
        }
    }
}

/** Calls the function value [callee] of [type]. */
internal fun Checker.invoke(
    callee: CheckedExpression,
    type: FunctionTypeUse,
    arguments: List<CallArgument>,
    expected: TypeUse?,
    safe: Boolean,
    span: TextSpan,
    scope: Scope,
): CheckedExpression {
    val trial = attempt(type.callSignature, null, null, arguments, expected, span, scope)
    absorb(trial.trace)
    if (trial.trace.problems.isNotEmpty()) return Invalid(ERROR, span)
    return Invoke(callee, trial.arguments.map { it ?: Invalid(ERROR, span) }, safe, if (safe) type.result.orNull() else type.result, span)
}

/** A formula function as a function value of the [expected] function type, when one of [functions] fits it. */
internal fun Checker.functionValue(
    name: Name,
    functions: List<FormulaFunction>,
    expected: FunctionTypeUse,
): CheckedExpression {
    val wanted = expected.context + expected.parameters
    val fitting =
        functions.mapNotNull { function ->
            val slots = function.signature.context + function.signature.parameters
            val solved = mutableMapOf<ParameterKey, TypeUse>()
            val fits = slots.size == wanted.size && slots.zip(wanted).all { (slot, parameter) -> unify(slot.type, parameter.type, solved) }
            if (fits && unify(function.signature.result, expected.result, solved)) function to solved else null
        }
    if (fitting.size != 1) {
        if (fitting.isEmpty()) {
            report(name.span, "formula_type_mismatch", "`${name.text}` is not a ${shown(TypeUse.FunctionWrapper(expected))}")
        } else {
            report(name.span, "formula_ambiguous_function", "Several `${name.text}` fit here equally well")
        }
        return Invalid(ERROR, name.span)
    }
    val (function, solved) = fitting.single()
    val result = function.signature.result.applied(solved) ?: return Invalid(ERROR, name.span).also { cannotInferAt(name.span) }
    trace.providers += function.name
    val type = TypeUse.createFunction(context = expected.context, parameters = expected.parameters, result = result)
    return FunctionReference(function, solved, type, name.span)
}

internal fun Checker.cannotInferAt(span: TextSpan) {
    report(span, "formula_cannot_infer", "The type here cannot be inferred; state it")
}

/** Expressions whose type depends on where they stand, so a call checks them again for each candidate. */
internal fun isFlexible(expression: Expression): Boolean =
    when (expression) {
        is Literal, is Name, is Member, is Lambda, is Shorthand, is ListLiteral, is MapLiteral -> true
        is Unary -> expression.value is Literal
        is Call -> expression.arguments.isEmpty() && expression.trailing == null
        else -> false
    }

private fun isFunctionLike(expression: Expression): Boolean = expression is Lambda || expression is Shorthand
