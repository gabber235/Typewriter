package com.typewritermc.expression

import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.append
import com.typewritermc.authoring.name
import com.typewritermc.authoring.root
import com.typewritermc.expression.operations.EvaluatorFailure
import com.typewritermc.expression.operations.KernelArgument
import com.typewritermc.expression.operations.KernelContext
import com.typewritermc.expression.operations.LambdaInterrupted
import com.typewritermc.expression.operations.OperationFailure
import com.typewritermc.expression.operations.ParameterKind
import com.typewritermc.expression.operations.PortableMeter
import com.typewritermc.expression.operations.PortableOperationCatalog
import com.typewritermc.expression.operations.PortableRuleKernels
import com.typewritermc.expression.operations.PortableTypes
import com.typewritermc.expression.operations.asItems
import com.typewritermc.expression.operations.illTyped
import com.typewritermc.expression.operations.invoker
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.apply
import com.typewritermc.types.field
import com.typewritermc.types.requirePortable
import com.typewritermc.types.requireValid
import com.typewritermc.types.unwrapNamed
import skirout.editor.v1.expression.CallExpression
import skirout.editor.v1.expression.ConditionalExpression
import skirout.editor.v1.expression.EvaluationBudget
import skirout.editor.v1.expression.EvaluationDiagnostic
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.expression.FallbackExpression
import skirout.editor.v1.expression.LambdaExpression
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath

interface ExpressionEvaluator {
    context(reads: AuthoredReads)
    fun evaluate(
        expression: ExpressionNode,
        bindings: ExpressionBindings,
        budget: EvaluationBudget,
    ): Availability<DataValue>

    /** Evaluates a local candidate without assigning it a persisted resource location. */
    context(reads: AuthoredReads)
    fun evaluateScoped(
        expression: ExpressionNode,
        bindings: ExpressionBindings,
        localValues: Map<ExpressionBindingId, DataValue>,
        budget: EvaluationBudget,
    ): Availability<DataValue>
}

fun interface ExpressionValueReader {
    context(reads: AuthoredReads)
    fun read(location: ValueLocation): Availability<DataValue>
}

/**
 * Evaluates portable expressions against authored reads with fresh lexical state and accounting budgets per call.
 *
 * Structural forms are evaluated here; every call runs through one call rule into the rule profile kernels, so Realm
 * evaluates rules and selection predicates only and a profile panel call fails with outside_rule_profile. Missing
 * authored inputs remain [Availability.Unavailable]; declared failures and exhausted budgets produce diagnostics whose
 * failure id is declared in operations.yaml. Anything else a kernel throws is a bug and propagates. Only input
 * projections through located bindings are reads; lambda locals hold values an earlier read produced.
 *
 * [types] supplies the catalog type facts that typed operations (instance_of, cast, from_json, enum cases) need; every
 * host evaluates against the catalog its bindings were checked with.
 */
class DefaultExpressionEvaluator(
    private val reader: ExpressionValueReader,
    private val types: PortableTypes,
) : ExpressionEvaluator {
    context(reads: AuthoredReads)
    override fun evaluate(
        expression: ExpressionNode,
        bindings: ExpressionBindings,
        budget: EvaluationBudget,
    ): Availability<DataValue> = evaluateScoped(expression, bindings, emptyMap(), budget)

    context(reads: AuthoredReads)
    override fun evaluateScoped(
        expression: ExpressionNode,
        bindings: ExpressionBindings,
        localValues: Map<ExpressionBindingId, DataValue>,
        budget: EvaluationBudget,
    ): Availability<DataValue> {
        require(localValues.keys.none(bindings.locations::containsKey)) { "Local expression bindings must not replace source bindings." }
        return EvaluatorState(reader, types, bindings, budget, localValues).evaluate(expression)
    }
}

object PortableExpressionLimits {
    const val MAX_DEPTH: Int = 512
}

private class EvaluatorState(
    private val reader: ExpressionValueReader,
    types: PortableTypes,
    private val bindings: ExpressionBindings,
    private val budget: EvaluationBudget,
    initialValues: Map<ExpressionBindingId, DataValue>,
) : PortableMeter {
    private var steps = 0L
    private var collectionItems = 0L
    private var depth = 0
    private val inputValues = initialValues.toMap()
    private val frames = mutableListOf<List<LocalBinding>>()
    private val observedLocations = linkedSetOf<ValueLocation>()
    private val context = KernelContext(this, types)

    context(reads: AuthoredReads)
    fun evaluate(expression: ExpressionNode): Availability<DataValue> =
        try {
            depth += 1
            if (depth > PortableExpressionLimits.MAX_DEPTH) {
                throw OperationFailure(EvaluatorFailure.ExpressionDepthLimit, "The expression exceeded its depth limit.")
            }
            step()
            projection(expression)?.let { return evaluateProjection(it) }
            when (expression) {
                is ExpressionNode.LiteralWrapper -> Availability.Available(literal(expression.value))
                is ExpressionNode.AndWrapper -> logical(expression.value.left, expression.value.right, conjunction = true)
                is ExpressionNode.OrWrapper -> logical(expression.value.left, expression.value.right, conjunction = false)
                is ExpressionNode.ConditionalWrapper -> conditional(expression.value)
                is ExpressionNode.OrElseWrapper -> orElse(expression.value)
                is ExpressionNode.FieldWrapper -> field(expression.value.source, expression.value.path.requireValidPath())
                is ExpressionNode.CallWrapper -> call(expression.value)
                is ExpressionNode.LambdaWrapper -> throw illTyped("A lambda is only an argument of a lambda parameter.")
                is ExpressionNode.InputWrapper, is ExpressionNode.LocalWrapper -> error("Projection roots are evaluated above.")
                is ExpressionNode.Unknown -> throw OperationFailure(EvaluatorFailure.UnknownExpression, "Unknown expression node.")
            }
        } catch (failure: OperationFailure) {
            Availability.Failed(
                EvaluationDiagnostic(
                    failure = failure.failure,
                    message = failure.message.orEmpty(),
                    locations = (observedLocations + frames.flatten().mapNotNull { it.location }).distinct(),
                ),
            )
        } finally {
            depth -= 1
        }

    /** An input or local together with the field paths projected from it; field chains read one deeper location. */
    private class Projection(
        val root: ExpressionNode,
        val suffix: ValuePath,
        val descents: Int,
    )

    private fun projection(expression: ExpressionNode): Projection? {
        var root = expression
        val reversed = mutableListOf<ValuePath>()
        while (root is ExpressionNode.FieldWrapper) {
            if (depth + reversed.size > PortableExpressionLimits.MAX_DEPTH) {
                throw OperationFailure(EvaluatorFailure.ExpressionDepthLimit, "The projection exceeded its depth limit.")
            }
            reversed += root.value.path.requireValidPath()
            root = root.value.source
        }
        if (root !is ExpressionNode.InputWrapper && root !is ExpressionNode.LocalWrapper) return null
        val suffix = reversed.asReversed().fold(ValuePath.root) { path, segment -> path.append(segment) }
        return Projection(root, suffix, reversed.size)
    }

    context(reads: AuthoredReads)
    private fun evaluateProjection(projection: Projection): Availability<DataValue> {
        repeat(projection.descents) { step() }
        return when (val root = projection.root) {
            is ExpressionNode.InputWrapper -> {
                val binding = ExpressionBindingId(value = root.value.binding.value)
                val path =
                    root.value.path
                        .requireValidPath()
                        .append(projection.suffix)
                val local = inputValues[binding]
                if (local != null) {
                    present(local.at(path), location = null)
                } else {
                    val base =
                        bindings.locations[binding]
                            ?: throw OperationFailure(
                                EvaluatorFailure.UnknownExpressionBinding,
                                "Unknown expression binding ${binding.value}.",
                            )
                    read(base.append(path))
                }
            }

            is ExpressionNode.LocalWrapper -> {
                val local = local(root.value.depth, root.value.slot)
                val path =
                    root.value.path
                        .requireValidPath()
                        .append(projection.suffix)
                present(local.value.at(path), local.locate(path))
            }

            else -> {
                error("Only inputs and locals root a projection.")
            }
        }
    }

    context(reads: AuthoredReads)
    private fun read(location: ValueLocation): Availability<DataValue> {
        observedLocations += location
        return when (val result = reader.read(location)) {
            is Availability.Available -> present(result.value, location)
            is Availability.Unavailable -> result
            is Availability.Failed -> result
        }
    }

    /** A selected value, or missing at [location] when the path does not exist or the value is unfilled. */
    private fun present(
        value: DataValue?,
        location: ValueLocation?,
    ): Availability<DataValue> =
        if (value == null || value == DataValue.UNFILLED) {
            Availability.Unavailable(listOfNotNull(location))
        } else {
            Availability.Available(value)
        }

    private fun local(
        depth: Int,
        slot: Int,
    ): LocalBinding {
        if (depth < 0 || slot < 0) throw OperationFailure(EvaluatorFailure.InvalidExpressionLocal, "Invalid local address.")
        return frames.getOrNull(frames.lastIndex - depth)?.getOrNull(slot)
            ?: throw OperationFailure(EvaluatorFailure.InvalidExpressionLocal, "The local address is outside its lambda.")
    }

    context(reads: AuthoredReads)
    private fun field(
        source: ExpressionNode,
        path: ValuePath,
    ): Availability<DataValue> {
        val value = evaluate(source)
        if (value !is Availability.Available) return value
        if (value.value.unwrapNamed() == DataValue.NULL) return Availability.Unavailable(emptyList())
        return present(value.value.at(path), location = null)
    }

    context(reads: AuthoredReads)
    private fun logical(
        left: ExpressionNode,
        right: ExpressionNode,
        conjunction: Boolean,
    ): Availability<DataValue> {
        val first = evaluate(left)
        if (first !is Availability.Available) return first
        val decided = first.value.predicate()
        if (decided != conjunction) return Availability.Available(DataValue.BooleanWrapper(decided))
        val second = evaluate(right)
        if (second !is Availability.Available) return second
        return Availability.Available(DataValue.BooleanWrapper(second.value.predicate()))
    }

    context(reads: AuthoredReads)
    private fun conditional(expression: ConditionalExpression): Availability<DataValue> {
        val test = evaluate(expression.test)
        if (test !is Availability.Available) return test
        return evaluate(if (test.value.predicate()) expression.then else expression.otherwise)
    }

    context(reads: AuthoredReads)
    private fun orElse(expression: FallbackExpression): Availability<DataValue> =
        when (val value = evaluate(expression.value)) {
            is Availability.Available -> {
                if (value.value == DataValue.NULL ||
                    value.value == DataValue.UNFILLED
                ) {
                    evaluate(expression.fallback)
                } else {
                    value
                }
            }

            is Availability.Unavailable -> {
                evaluate(expression.fallback)
            }

            is Availability.Failed -> {
                value
            }
        }

    /**
     * The uniform call rule. Arguments evaluate left to right and the first missing or failed one decides the call.
     * Value arguments that still contain unfilled entries, and each lambdas whose body is missing for some item, do
     * not stop evaluation: their locations are collected, distinct and in collection order, and the call is missing
     * after every argument ran. Each lambdas run for every item of the first argument before the kernel; step,
     * comparator and apply lambdas are driven by the kernel and abort the call when a body is missing or failed. An
     * available result charges its size to the collection item budget (see [resultSize]).
     */
    context(reads: AuthoredReads)
    private fun call(expression: CallExpression): Availability<DataValue> {
        val declaration =
            PortableOperationCatalog.declaration(expression.operation)
                ?: throw OperationFailure(EvaluatorFailure.UnknownOperation, "Unknown operation ${expression.operation.value}.")
        val invoker =
            PortableRuleKernels.invoker(expression.operation)
                ?: throw OperationFailure(EvaluatorFailure.OutsideRuleProfile, "Realm does not evaluate ${expression.operation.value}.")
        if (!declaration.accepts(expression.arguments.size)) {
            throw OperationFailure(
                EvaluatorFailure.InvalidArgumentCount,
                "${declaration.id.value} received ${expression.arguments.size} arguments.",
            )
        }
        if (expression.typeArguments.size != declaration.explicitTypeParameters.size) {
            throw illTyped("${declaration.id.value} received ${expression.typeArguments.size} type arguments.")
        }
        val typeArguments = expression.typeArguments.map(::closedType)
        val arguments = ArrayList<KernelArgument>(expression.arguments.size)
        val missing = linkedSetOf<ValueLocation>()
        var incomplete = false
        for ((index, argument) in expression.arguments.withIndex()) {
            val parameter = requireNotNull(declaration.parameterAt(index))
            when (parameter.kind) {
                ParameterKind.EACH -> {
                    val source = arguments.firstOrNull() as? KernelArgument.Value ?: throw illTyped("An each lambda follows its source.")
                    when (val results = each(source, argument.lambda(arity = 1))) {
                        is Availability.Available -> {
                            arguments += KernelArgument.Each(results.value)
                        }

                        is Availability.Unavailable -> {
                            incomplete = true
                            missing += results.locations
                        }

                        is Availability.Failed -> {
                            return results
                        }
                    }
                }

                ParameterKind.STEP, ParameterKind.COMPARATOR -> {
                    arguments += kernelLambda(argument.lambda(arity = 2), arguments.firstOrNull())
                }

                ParameterKind.APPLY -> {
                    arguments += kernelLambda(argument.lambda(arity = 1), arguments.firstOrNull())
                }

                ParameterKind.VALUE, ParameterKind.PARTIAL, ParameterKind.LOCATED -> {
                    if (argument is ExpressionNode.LambdaWrapper) throw illTyped("A lambda is only an argument of a lambda parameter.")
                    val location = sourceLocation(argument)
                    when (val result = evaluate(argument)) {
                        is Availability.Available -> {
                            if (parameter.kind == ParameterKind.VALUE) {
                                val unfilled = result.value.unfilledPaths()
                                if (unfilled.isNotEmpty()) {
                                    incomplete = true
                                    if (location != null) unfilled.forEach { missing += location.append(it) }
                                }
                            }
                            arguments += KernelArgument.Value(result.value, location)
                        }

                        is Availability.Unavailable -> {
                            return result
                        }

                        is Availability.Failed -> {
                            return result
                        }
                    }
                }
            }
        }
        if (incomplete) return Availability.Unavailable(missing.toList())
        val result =
            try {
                invoker.invoke(arguments, typeArguments, context)
            } catch (interrupted: LambdaInterrupted) {
                interrupted.result
            }
        if (result is Availability.Available) items(result.value.resultSize())
        return result
    }

    /** Runs [body] once per item of [source], in item order; missing items collect their locations. */
    context(reads: AuthoredReads)
    private fun each(
        source: KernelArgument.Value,
        body: ExpressionNode,
    ): Availability<List<DataValue>> {
        val results = mutableListOf<DataValue>()
        val missing = linkedSetOf<ValueLocation>()
        var blocked = false
        val rows = source.value.isMap()
        for (item in source.value.asItems()) {
            items(1)
            val location = source.location?.item(item)
            when (val result = evaluateWithLocals(body, listOf(LocalBinding(item.value, location, row = rows)))) {
                is Availability.Available -> {
                    results += result.value
                }

                is Availability.Unavailable -> {
                    blocked = true
                    missing += result.locations.ifEmpty { listOfNotNull(location) }
                }

                is Availability.Failed -> {
                    return result
                }
            }
        }
        return if (blocked) Availability.Unavailable(missing.toList()) else Availability.Available(results)
    }

    /** A lambda the kernel drives; locals that carry an item of [source] keep that item's location. */
    context(reads: AuthoredReads)
    private fun kernelLambda(
        body: ExpressionNode,
        source: KernelArgument?,
    ): KernelArgument.Lambda {
        val sourceLocation = (source as? KernelArgument.Value)?.location
        val rows = (source as? KernelArgument.Value)?.value?.isMap() == true
        return KernelArgument.Lambda { inputs ->
            val locals =
                inputs.map { input ->
                    LocalBinding(input.value, input.item?.let { id -> sourceLocation?.item(id) }, row = rows && input.item != null)
                }
            when (val result = evaluateWithLocals(body, locals)) {
                is Availability.Available -> result.value
                else -> throw LambdaInterrupted(result)
            }
        }
    }

    context(reads: AuthoredReads)
    private fun evaluateWithLocals(
        body: ExpressionNode,
        values: List<LocalBinding>,
    ): Availability<DataValue> {
        frames += values
        return try {
            evaluate(body)
        } finally {
            frames.removeAt(frames.lastIndex)
        }
    }

    /** The authored location an argument projects, when it is an input or local projection with one. */
    private fun sourceLocation(expression: ExpressionNode): ValueLocation? {
        val projection = projection(expression) ?: return null
        return when (val root = projection.root) {
            is ExpressionNode.InputWrapper -> {
                bindings.locations[ExpressionBindingId(value = root.value.binding.value)]
                    ?.append(root.value.path.requireValidPath())
                    ?.append(projection.suffix)
            }

            is ExpressionNode.LocalWrapper -> {
                frames
                    .getOrNull(frames.lastIndex - root.value.depth)
                    ?.getOrNull(root.value.slot)
                    ?.locate(
                        root.value.path
                            .requireValidPath()
                            .append(projection.suffix),
                    )
            }

            else -> {
                null
            }
        }
    }

    private fun closedType(template: TypeTemplate): TypeUse =
        when (val resolved = template.apply(emptyMap())) {
            is Resolution.Ready -> resolved.value
            is Resolution.Invalid -> throw illTyped("A type argument is not a closed type.")
        }

    private fun ExpressionNode.lambda(arity: Int): ExpressionNode {
        val lambda: LambdaExpression =
            (this as? ExpressionNode.LambdaWrapper)?.value ?: throw illTyped("A lambda parameter takes a lambda.")
        if (lambda.arity != arity) throw illTyped("The lambda takes ${lambda.arity} locals instead of $arity.")
        return lambda.body
    }

    private fun step() {
        steps += 1
        if (steps > budget.maxSteps) throw OperationFailure(EvaluatorFailure.ExpressionStepLimit, "The expression exceeded its step limit.")
    }

    override fun steps(count: Int) {
        require(count >= 0) { "Step charges are not negative." }
        steps += count
        if (steps > budget.maxSteps) throw OperationFailure(EvaluatorFailure.ExpressionStepLimit, "The expression exceeded its step limit.")
    }

    override fun items(count: Int) {
        require(count >= 0) { "Item charges are not negative." }
        collectionItems += count
        if (collectionItems > budget.maxCollectionItems) {
            throw OperationFailure(EvaluatorFailure.ExpressionCollectionLimit, "The expression exceeded its collection item limit.")
        }
    }
}

context(reads: AuthoredReads)
fun ExpressionNode.evaluateWith(
    evaluator: ExpressionEvaluator,
    bindings: ExpressionBindings,
    budget: EvaluationBudget,
): Availability<DataValue> = evaluator.evaluate(this, bindings, budget)

/**
 * A lambda local. A local bound to a map entry ([row]) is located at the map row, and its `key` and `value` fields are
 * that row's key and value, so missing data inside them is reported where it is authored.
 */
private data class LocalBinding(
    val value: DataValue,
    val location: ValueLocation?,
    val row: Boolean = false,
) {
    fun locate(path: ValuePath): ValueLocation? {
        val location = location ?: return null
        val first = path.segments.firstOrNull() as? PathSegment.FieldWrapper
        if (!row || first == null) return location.append(path)
        val member =
            when (first.name) {
                "key" -> PathSegment.MAP_KEY
                "value" -> PathSegment.MAP_VALUE
                else -> return location.append(path)
            }
        return location.append(ValuePath(segments = listOf(member) + path.segments.drop(1)))
    }
}

private fun DataValue.isMap(): Boolean = unwrapNamed() is DataValue.MapValueWrapper

/**
 * The collection items a call result charges, so a composition cannot grow values past the budget without collections:
 * one per item of a list or set and per row of a map (top level only, through named wrappers), and one per started 64
 * UTF-16 code units of text or 64 bytes. Every other value charges nothing.
 */
private fun DataValue.resultSize(): Int =
    when (val value = unwrapNamed()) {
        is DataValue.ListValueWrapper -> value.value.items.size
        is DataValue.SetValueWrapper -> value.value.items.size
        is DataValue.MapValueWrapper -> value.value.rows.size
        is DataValue.StringValueWrapper -> startedBlocks(value.value.length)
        is DataValue.BytesWrapper -> startedBlocks(value.value.size)
        else -> 0
    }

private fun startedBlocks(length: Int): Int = (length + RESULT_BLOCK - 1) / RESULT_BLOCK

private const val RESULT_BLOCK = 64

private fun ValueLocation.item(item: ListItem): ValueLocation = item(item.id)

private fun ValueLocation.item(id: ItemId): ValueLocation = append(PathSegment.createItem(id = id))

/** The truth value of a logical operand or conditional test. */
private fun DataValue.predicate(): Boolean =
    (unwrapNamed() as? DataValue.BooleanWrapper)?.value
        ?: throw OperationFailure(EvaluatorFailure.ExpressionResultNotBoolean, "A logical operand or test is not a boolean.")

private fun literal(value: DataValue): DataValue =
    try {
        value.requirePortable()
    } catch (invalid: IllegalArgumentException) {
        throw OperationFailure(EvaluatorFailure.InvalidExpressionLiteral, invalid.message ?: "The expression literal is not portable.")
    }

private fun ValuePath.requireValidPath(): ValuePath =
    try {
        requireValid()
    } catch (invalid: IllegalArgumentException) {
        throw illTyped(invalid.message ?: "The expression path is not valid.")
    }

/**
 * The value at [path] through nominal wrappers, or null when the path does not exist. A map item selects the row as
 * an entry record; a following key or value segment selects that row's content.
 */
private fun DataValue.at(path: ValuePath): DataValue? {
    var current: DataValue = this
    for (segment in path.segments) {
        val container = current.unwrapNamed()
        current =
            when (segment) {
                is PathSegment.FieldWrapper -> (container as? DataValue.RecordWrapper)?.field(segment.name)
                is PathSegment.ItemWrapper -> (container.collectionItems() ?: return null).firstOrNull { it.id == segment.value.id }?.value
                PathSegment.MAP_KEY -> (container as? DataValue.RecordWrapper)?.field("key")
                PathSegment.MAP_VALUE -> (container as? DataValue.RecordWrapper)?.field("value")
                else -> null
            } ?: return null
    }
    return current
}

private fun DataValue.collectionItems(): List<ListItem>? =
    when (this) {
        is DataValue.ListValueWrapper, is DataValue.SetValueWrapper, is DataValue.MapValueWrapper -> asItems()
        else -> null
    }

/** The paths of every unfilled entry inside this value, through named, record, list, set and map values. */
private fun DataValue.unfilledPaths(): List<ValuePath> {
    val paths = mutableListOf<ValuePath>()

    fun visit(
        value: DataValue,
        path: ValuePath,
    ) {
        when (value) {
            DataValue.UNFILLED -> {
                paths += path
            }

            is DataValue.NamedWrapper -> {
                visit(value.value.payload, path)
            }

            is DataValue.RecordWrapper -> {
                value.value.fields.forEach { visit(it.value, path.append(PathSegment.createField(name = it.name))) }
            }

            is DataValue.ListValueWrapper -> {
                value.value.items.forEach { visit(it.value, path.append(PathSegment.createItem(id = it.id))) }
            }

            is DataValue.SetValueWrapper -> {
                value.value.items.forEach { visit(it.value, path.append(PathSegment.createItem(id = it.id))) }
            }

            is DataValue.MapValueWrapper -> {
                value.value.rows.forEach { row ->
                    val item = path.append(PathSegment.createItem(id = row.id))
                    visit(row.key, item.append(PathSegment.MAP_KEY))
                    visit(row.value, item.append(PathSegment.MAP_VALUE))
                }
            }

            else -> {
                Unit
            }
        }
    }
    visit(this, ValuePath.root)
    return paths
}
