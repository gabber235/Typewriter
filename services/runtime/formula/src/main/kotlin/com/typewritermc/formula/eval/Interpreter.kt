package com.typewritermc.formula.eval

import com.typewritermc.formula.FormulaCall
import com.typewritermc.formula.FormulaFailure
import com.typewritermc.formula.FormulaFailureException
import com.typewritermc.formula.FormulaFunction
import com.typewritermc.formula.NamedValue
import com.typewritermc.formula.NotProvided
import com.typewritermc.formula.RecordValue
import com.typewritermc.formula.check.Block
import com.typewritermc.formula.check.CheckedBinding
import com.typewritermc.formula.check.CheckedExpression
import com.typewritermc.formula.check.CheckedPattern
import com.typewritermc.formula.check.Compare
import com.typewritermc.formula.check.Constant
import com.typewritermc.formula.check.Construct
import com.typewritermc.formula.check.Elvis
import com.typewritermc.formula.check.Equals
import com.typewritermc.formula.check.ExpressionLine
import com.typewritermc.formula.check.FieldRead
import com.typewritermc.formula.check.FunctionCall
import com.typewritermc.formula.check.FunctionLine
import com.typewritermc.formula.check.FunctionReference
import com.typewritermc.formula.check.If
import com.typewritermc.formula.check.Invalid
import com.typewritermc.formula.check.Invoke
import com.typewritermc.formula.check.Lambda
import com.typewritermc.formula.check.LetLine
import com.typewritermc.formula.check.ListOf
import com.typewritermc.formula.check.LocalRead
import com.typewritermc.formula.check.Logic
import com.typewritermc.formula.check.MapOf
import com.typewritermc.formula.check.Not
import com.typewritermc.formula.check.ResourceRead
import com.typewritermc.formula.check.SafeCast
import com.typewritermc.formula.check.TypeTest
import com.typewritermc.formula.check.When
import com.typewritermc.formula.graph.DeepStacks
import com.typewritermc.formula.syntax.BinaryOperator
import com.typewritermc.services.libs.utils.runExtension
import com.typewritermc.types.EvaluationValues
import com.typewritermc.types.Ref
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.apply
import com.typewritermc.types.fromValueAny
import com.typewritermc.types.toValueAny
import skirout.editor.v1.type_catalog.FunctionTypeUse
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import java.util.IdentityHashMap
import java.util.concurrent.CancellationException

/**
 * Evaluates this checked tree as the formula at [at], with [locals] bound: its context values and parameters. Never
 * throws for a failure of the formula itself; graph control flow and fatal JVM errors pass through.
 */
context(environment: EvaluationEnvironment)
fun CheckedExpression.evaluate(
    locals: Map<String, Any?>,
    at: ValueLocation,
    limits: EvaluationLimits = EvaluationLimits(),
): Evaluation<Any?> = Interpreter(environment, at, limits).outcome { evaluate(this@evaluate, locals) }

/** Calls this function value with [arguments], context first, as its own evaluation. */
context(environment: EvaluationEnvironment)
fun FunctionValue.call(
    arguments: List<Any?>,
    limits: EvaluationLimits = EvaluationLimits(),
): Evaluation<Any?> = Interpreter(environment, at, limits).outcome { enter(this@call, arguments) }

/** One evaluation: its depth and step counts, which every lambda a provider calls shares. */
private class Interpreter(
    private val environment: EvaluationEnvironment,
    private val at: ValueLocation,
    private val limits: EvaluationLimits,
) {
    private var depth = 0
    private var steps = 0

    fun <T> outcome(body: Interpreter.() -> T): Evaluation<T> =
        try {
            Evaluation.Value(body())
        } catch (failed: FailedEvaluation) {
            Evaluation.Failed(at, failed.reason)
        }

    fun evaluate(
        node: CheckedExpression,
        locals: Map<String, Any?>,
    ): Any? {
        step()
        return when (node) {
            is Constant -> node.value
            is LocalRead -> environment.resolve(locals.getValue(node.name))
            is ResourceRead -> environment.resolve(environment.exported(node.id))
            is FieldRead -> fieldRead(node, locals)
            is FunctionCall -> functionCall(node, locals)
            is FunctionReference -> reference(node)
            is Invoke -> invoke(node, locals)
            is Construct -> construct(node, locals)
            is Lambda -> lambda(node, locals)
            is Block -> block(node, locals)
            else -> control(node, locals)
        }
    }

    /** A node that picks which of its parts run: a branch, a match, a comparison or a logical operator. */
    private fun control(
        node: CheckedExpression,
        locals: Map<String, Any?>,
    ): Any? =
        when (node) {
            is If -> branch(node, locals)
            is When -> choose(node, locals)
            is Equals -> equals(node, locals)
            is Compare -> compare(evaluate(node.comparison, locals) as Int, node.operator)
            is Logic -> logic(node, locals)
            is Not -> !(evaluate(node.value, locals) as Boolean)
            is Elvis -> elvis(node, locals)
            else -> shape(node, locals)
        }

    /** A node that tests or builds a value's shape: a type test, a cast, a collection, or a part that did not check. */
    private fun shape(
        node: CheckedExpression,
        locals: Map<String, Any?>,
    ): Any? =
        when (node) {
            is TypeTest -> environment.isA(evaluate(node.value, locals), node.tested) != node.negated
            is SafeCast -> safeCast(node, locals)
            is ListOf -> listValue(node, locals)
            is MapOf -> mapValue(node, locals)
            is Invalid -> throw FailedEvaluation(FormulaFailure.Dependency(at.resource))
            else -> error("Every checked node has an evaluation; ${node::class.simpleName} has none.")
        }

    private fun elvis(
        node: Elvis,
        locals: Map<String, Any?>,
    ): Any? = evaluate(node.left, locals) ?: evaluate(node.right, locals)

    // A part that did not check with no problem of its own, such as an emptied reference or a gone type, has its
    // finding at that source, so reaching it fails silently with Dependency.

    // Each node with more than one step has its own function, so the frame of evaluate, which every nested call
    // passes through, stays small and the depth limit fits in a small stack.

    private fun lambda(
        node: Lambda,
        locals: Map<String, Any?>,
    ): FunctionValue = FunctionValue(node.body, node.contextBindings() + node.parameters, locals.toMap(), at)

    private fun equals(
        node: Equals,
        locals: Map<String, Any?>,
    ): Boolean = same(environment.force(evaluate(node.left, locals)), environment.force(evaluate(node.right, locals))) != node.negated

    /**
     * `==`: structural, except that two floating point numbers compare as Kotlin compares Float and Double values, by
     * IEEE 754, so -0.0 equals 0.0. Inside a record or a collection equality stays structural, as in Kotlin.
     */
    private fun same(
        left: Any?,
        right: Any?,
    ): Boolean =
        when {
            left is Double && right is Double -> left == right
            left is Float && right is Float -> left == right
            else -> left == right
        }

    private fun safeCast(
        node: SafeCast,
        locals: Map<String, Any?>,
    ): Any? {
        val value = evaluate(node.value, locals)
        return if (environment.isA(value, node.tested)) value else null
    }

    private fun listValue(
        node: ListOf,
        locals: Map<String, Any?>,
    ): List<Any?> = node.items.map { evaluate(it, locals) }

    private fun mapValue(
        node: MapOf,
        locals: Map<String, Any?>,
    ): Map<Any?, Any?> =
        node.entries.associateTo(LinkedHashMap()) { (key, value) ->
            environment.force(evaluate(key, locals)) to
                evaluate(value, locals)
        }

    /**
     * A user function call. The first one off the large stacks moves onto one, and every [CALLS_PER_STACK] nested calls
     * continue on a fresh one, so the depth limit is reachable from any caller, however little stack it has left.
     */
    fun enter(
        function: FunctionValue,
        arguments: List<Any?>,
    ): Any? {
        depth++
        try {
            if (depth > limits.maxDepth) throw FailedEvaluation(FormulaFailure.RecursionLimit)
            return if (depth % CALLS_PER_STACK != 0 &&
                DeepStacks.isCurrent()
            ) {
                body(function, arguments)
            } else {
                DeepStacks.run { body(function, arguments) }
            }
        } finally {
            depth--
        }
    }

    private fun body(
        function: FunctionValue,
        arguments: List<Any?>,
    ): Any? {
        val locals = HashMap(function.captured)
        function.self?.let { locals[it] = function }
        function.parameters.zip(arguments).forEach { (parameter, argument) -> bind(parameter, argument, locals) }
        return evaluate(function.tree, locals)
    }

    private fun fieldRead(
        node: FieldRead,
        locals: Map<String, Any?>,
    ): Any? {
        val target = evaluate(node.target, locals) ?: return nullTarget(node.safe)
        return readField(target, node.field)
    }

    private fun nullTarget(safe: Boolean): Any? =
        if (safe) null else error("The checker allows a plain field read only on a value that is not null.")

    /** Field [field] of [target], resolved one level: a record's field, a value class's value, or the field of the resource a Ref names. */
    private fun readField(
        target: Any,
        field: String,
    ): Any? =
        environment.resolve(
            when (target) {
                is RecordValue -> target.fields[field]
                is NamedValue -> target.value
                is Ref<*, *> -> environment.fieldOf(target.target, field)
                else -> error("A field read on ${target::class.simpleName}.")
            },
        )

    private fun functionCall(
        node: FunctionCall,
        locals: Map<String, Any?>,
    ): Any? {
        val arguments = ArrayList<Any?>(node.arguments.size)
        for ((index, argument) in node.arguments.withIndex()) {
            val value = if (argument == null) NotProvided else evaluate(argument, locals)
            if (index == 0 && node.safe && value == null) return null
            arguments += value
        }
        return call(node.function, node.typeArguments, arguments)
    }

    /**
     * The failure rule. A provider calling a lambda re-enters the interpreter through this boundary, so inner failures
     * and graph control flow pass through unchanged; only what the provider itself threw becomes its failure. A
     * collection it returns costs one step per item.
     */
    private fun call(
        function: FormulaFunction,
        solved: Map<ParameterKey, TypeUse>,
        arguments: List<Any?>,
    ): Any? {
        step()
        val result = boundary { ProviderCall(function, solved).run(arguments) }
        when (result) {
            is Collection<*> -> charge(result.size)
            is Map<*, *> -> charge(result.size)
        }
        return result
    }

    /** A formula function used as a value: a function value whose body calls it with its own parameters. */
    private fun reference(node: FunctionReference): FunctionValue {
        val type = (node.type as TypeUse.FunctionWrapper).value
        val slots = type.context + type.parameters
        val names = slots.indices.map { "\$$it" }
        val signature = node.function.signature
        val arguments =
            (0 until signature.context.size + signature.parameters.size).map { index ->
                slots.getOrNull(index)?.let { LocalRead(names[index], it.type, node.span) }
            }
        val tree = FunctionCall(node.function, node.typeArguments, arguments, false, type.result, node.span)
        return FunctionValue(tree, slots.mapIndexed { index, slot -> CheckedBinding.Named(names[index], slot.type) }, emptyMap(), at)
    }

    private fun invoke(
        node: Invoke,
        locals: Map<String, Any?>,
    ): Any? {
        val function = evaluate(node.function, locals) ?: return nullTarget(node.safe)
        val arguments = node.arguments.map { evaluate(it, locals) }
        return enter(function as FunctionValue, arguments)
    }

    private fun construct(
        node: Construct,
        locals: Map<String, Any?>,
    ): Any? {
        val fields = node.fields.mapValues { (_, value) -> evaluate(value, locals) }
        return boundary { environment.construct(node.type, fields) }
    }

    private fun block(
        node: Block,
        locals: Map<String, Any?>,
    ): Any? {
        val scope = HashMap(locals)
        for (line in node.lines) {
            when (line) {
                is LetLine -> {
                    val value = evaluate(line.value, scope)
                    if (value == null && line.otherwise != null) return evaluate(line.otherwise, scope)
                    bind(line.binding, value, scope)
                }

                is FunctionLine -> {
                    val function = line.function
                    scope[line.name] =
                        FunctionValue(function.body, function.contextBindings() + function.parameters, scope.toMap(), at, line.name)
                }

                is ExpressionLine -> {
                    evaluate(line.value, scope)
                }
            }
        }
        return evaluate(node.result, scope)
    }

    private fun branch(
        node: If,
        locals: Map<String, Any?>,
    ): Any? {
        val binding =
            node.binding ?: return evaluate(if (evaluate(node.condition, locals) as Boolean) node.then else node.otherwise, locals)
        val value = evaluate(node.condition, locals) ?: return evaluate(node.otherwise, locals)
        val scope = HashMap(locals)
        bind(binding, value, scope)
        return evaluate(node.then, scope)
    }

    private fun choose(
        node: When,
        locals: Map<String, Any?>,
    ): Any? {
        val subject = node.subject?.let { evaluate(it, locals) }
        val scope = HashMap(locals)
        node.subjectName?.let { scope[it] = subject }
        for (arm in node.arms) {
            for (pattern in arm.patterns) {
                val armScope = HashMap(scope)
                if (matches(pattern, subject, armScope) && (arm.guard == null || evaluate(arm.guard, armScope) as Boolean)) {
                    return evaluate(arm.body, armScope)
                }
            }
        }
        error("The checker proves every when exhaustive.")
    }

    private fun matches(
        pattern: CheckedPattern,
        subject: Any?,
        scope: HashMap<String, Any?>,
    ): Boolean =
        when (pattern) {
            is CheckedPattern.Is -> {
                environment.isA(subject, pattern.type).also { matched ->
                    if (matched) {
                        pattern.bindings.forEach { (field, binding) -> bind(binding, readField(subject!!, field), scope) }
                        pattern.narrowed?.let { scope[it] = subject }
                    }
                }
            }

            is CheckedPattern.Test -> {
                evaluate(pattern.condition, scope) as Boolean
            }

            CheckedPattern.Else -> {
                true
            }
        }

    private fun logic(
        node: Logic,
        locals: Map<String, Any?>,
    ): Boolean =
        when (node.operator) {
            BinaryOperator.And -> evaluate(node.left, locals) as Boolean && evaluate(node.right, locals) as Boolean
            BinaryOperator.Or -> evaluate(node.left, locals) as Boolean || evaluate(node.right, locals) as Boolean
            else -> error("${node.operator} is not a logic operator.")
        }

    private fun compare(
        answer: Int,
        operator: BinaryOperator,
    ): Boolean =
        when (operator) {
            BinaryOperator.Less -> answer < 0
            BinaryOperator.LessOrEqual -> answer <= 0
            BinaryOperator.Greater -> answer > 0
            BinaryOperator.GreaterOrEqual -> answer >= 0
            else -> error("$operator is not a comparison.")
        }

    private fun bind(
        binding: CheckedBinding,
        value: Any?,
        scope: MutableMap<String, Any?>,
    ) {
        when (binding) {
            is CheckedBinding.Named -> scope[binding.name] = value
            is CheckedBinding.Fields -> binding.fields.forEach { (field, inner) -> bind(inner, readField(value!!, field), scope) }
            CheckedBinding.Ignored -> Unit
        }
    }

    private fun step() {
        if (++steps > limits.maxSteps) throw FailedEvaluation(FormulaFailure.StepLimit)
        if (steps % CANCEL_CHECK_INTERVAL == 0) environment.ensureCurrent()
    }

    private fun charge(count: Int) {
        val before = steps
        steps += count
        if (steps > limits.maxSteps) throw FailedEvaluation(FormulaFailure.StepLimit)
        if (before / CANCEL_CHECK_INTERVAL != steps / CANCEL_CHECK_INTERVAL) environment.ensureCurrent()
    }

    /**
     * One call of a formula function. It owns the crossing a generated provider uses at its own edge, the first failure
     * or graph signal a lambda raised, and how long its lambdas stay valid. Graph control is a CancellationException,
     * so a provider could swallow it; the kept signal is rethrown whatever the provider did.
     */
    private inner class ProviderCall(
        private val function: FormulaFunction,
        private val solved: Map<ParameterKey, TypeUse>,
    ) : FormulaCall,
        EvaluationValues by environment {
        private var signal: Throwable? = null
        private var open = true
        private val lambdas = IdentityHashMap<Function<*>, FunctionValue>()

        fun run(arguments: List<Any?>): Any? {
            val outcome = runCatching { function.invoke(this, arguments) }
            open = false
            signal?.let { throw it }
            return outcome.getOrThrow()
        }

        /** The checker solves every type argument of a call, so the declared template applies once and every position converts at its concrete type. */
        override fun intoKotlin(
            value: Any?,
            type: TypeTemplate,
        ): Any? = into(value, type.concrete())

        override fun fromKotlin(
            value: Any?,
            type: TypeTemplate,
        ): Any? = from(value, type.concrete())

        override fun display(value: Any?): String = environment.display(value)

        private fun TypeTemplate.concrete(): TypeUse =
            when (val applied = apply(solved)) {
                is Resolution.Ready -> applied.value
                is Resolution.Invalid -> error("The checker left a type argument of ${function.name} unsolved.")
            }

        /** [given] at [type] for Kotlin. A stored Var anywhere inside it is worked out here, as a Var field is when read. */
        private fun into(
            given: Any?,
            type: TypeUse,
        ): Any? {
            if (given === NotProvided) return given
            val value = environment.resolve(given) ?: return null
            val collection = (type as? TypeUse.NamedWrapper)?.value
            return when {
                type is TypeUse.NullableWrapper -> {
                    into(value, type.value.value)
                }

                type is TypeUse.FunctionWrapper -> {
                    kotlinFunction(value as FunctionValue, type.value)
                }

                collection?.definition == StandardTypes.set -> {
                    (value as Set<*>).mapTo(LinkedHashSet()) { into(it, collection.arguments[0]) }
                }

                collection?.definition == StandardTypes.list -> {
                    (value as List<*>).map { into(it, collection.arguments[0]) }
                }

                collection?.definition == StandardTypes.map -> {
                    (value as Map<*, *>).entries.associateTo(LinkedHashMap()) { (key, item) ->
                        into(key, collection.arguments[0]) to into(item, collection.arguments[1])
                    }
                }

                else -> {
                    environment.binding(type).fromValueAny(value, this)
                }
            }
        }

        private fun from(
            value: Any?,
            type: TypeUse,
        ): Any? {
            if (value == null) return null
            val collection = (type as? TypeUse.NamedWrapper)?.value
            return when {
                type is TypeUse.NullableWrapper -> {
                    from(value, type.value.value)
                }

                type is TypeUse.FunctionWrapper -> {
                    lambdas[value] ?: fail("A provider returned a function it was not given.")
                }

                collection?.definition == StandardTypes.set -> {
                    (value as Set<*>).mapTo(LinkedHashSet()) { from(it, collection.arguments[0]) }
                }

                collection?.definition == StandardTypes.list -> {
                    (value as List<*>).map { from(it, collection.arguments[0]) }
                }

                collection?.definition == StandardTypes.map -> {
                    (value as Map<*, *>).entries.associateTo(LinkedHashMap()) { (key, item) ->
                        from(key, collection.arguments[0]) to from(item, collection.arguments[1])
                    }
                }

                else -> {
                    environment.binding(type).toValueAny(value, this)
                }
            }
        }

        private fun kotlinFunction(
            lambda: FunctionValue,
            type: FunctionTypeUse,
        ): Function<*> {
            val slots = type.context + type.parameters

            fun calling(arguments: List<Any?>): Any? {
                check(open) { "A provider kept a formula lambda past its call." }
                return runCatching {
                    into(
                        enter(lambda, arguments.zip(slots) { argument, slot -> from(argument, slot.type) }),
                        type.result,
                    )
                }.onFailure { raised -> if (raised is FailedEvaluation || raised is CancellationException) signal = signal ?: raised }
                    .getOrThrow()
            }
            val none: () -> Any? = { calling(emptyList()) }
            val one: (Any?) -> Any? = { a -> calling(listOf(a)) }
            val two: (Any?, Any?) -> Any? = { a, b -> calling(listOf(a, b)) }
            val three: (Any?, Any?, Any?) -> Any? = { a, b, c -> calling(listOf(a, b, c)) }
            val kotlin: Function<*> =
                when (slots.size) {
                    0 -> none
                    1 -> one
                    2 -> two
                    3 -> three
                    else -> error("A provider function parameter takes at most three values.")
                }
            return kotlin.also { lambdas[it] = lambda }
        }
    }
}

/** The context of a lambda's function type, bound by name before its parameters, as a call passes context first. */
private fun Lambda.contextBindings(): List<CheckedBinding> =
    (type as? TypeUse.FunctionWrapper)
        ?.value
        ?.context
        .orEmpty()
        .map { CheckedBinding.Named(it.name, it.type) }

/**
 * Turns what a provider or constructor threw into the evaluation's failure. An inner failure passes unchanged;
 * cancellation, graph control and fatal JVM errors pass through, while a provider's own LinkageError or stack overflow
 * is its failure.
 */
private inline fun <T> boundary(body: () -> T): T =
    runExtension(body) { failure ->
        if (failure is FailedEvaluation) throw failure
        throw FailedEvaluation(extensionFailure(failure), failure)
    }

/** The evaluation's failure for what a provider or constructor threw. */
private fun extensionFailure(failure: Throwable): FormulaFailure =
    when (failure) {
        is FormulaFailureException -> failure.reason
        is ArithmeticException -> arithmeticFailure(failure)
        else -> FormulaFailure.ProviderThrew(failure.message ?: failure::class.simpleName.orEmpty())
    }

/** Exact arithmetic throws one exception type for both cases; its message tells them apart. */
private fun arithmeticFailure(failure: ArithmeticException): FormulaFailure {
    val message = failure.message.orEmpty().lowercase()
    return if ("zero" in message || "undefined" in message) FormulaFailure.DivisionByZero else FormulaFailure.Overflow
}

private const val CALLS_PER_STACK = 64

private const val CANCEL_CHECK_INTERVAL = 1024
