package com.typewritermc.expression

import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.presentation.ExpressionNode
import com.typewritermc.types.DataValue
import com.typewritermc.types.ListItem
import com.typewritermc.types.MapRow
import com.typewritermc.types.canonicalValueKey
import java.math.BigDecimal
import java.math.MathContext
import java.util.concurrent.CancellationException

interface ExpressionEvaluator {
    context(reads: AuthoredReads)
    fun evaluate(
        expression: ExpressionNode,
        bindings: ExpressionBindings,
        budget: EvaluationBudget,
    ): Availability<DataValue>
}

fun interface ExpressionValueReader {
    context(reads: AuthoredReads)
    fun read(location: ValueLocation): Availability<DataValue>
}

data class PortableOperationSemantics(
    val id: OperationId,
    val minimumArguments: Int,
    val maximumArguments: Int,
    val meaning: String,
)

class PortableOperationRegistry private constructor(
    definitions: List<OperationDefinition>,
) {
    private val definitions = definitions.associateBy(OperationDefinition::semantics).mapKeys { it.key.id }

    val semantics: List<PortableOperationSemantics> = definitions.map(OperationDefinition::semantics)

    fun semantics(id: OperationId): PortableOperationSemantics? = definitions[id]?.semantics

    internal fun evaluate(
        id: OperationId,
        arguments: List<DataValue>,
        consumeStep: () -> Unit,
        consumeItems: (Int) -> Unit,
    ): DataValue {
        val definition = definitions[id] ?: throw OperationFailure("unknown_operation", "Unknown portable operation ${id.value}.")
        if (arguments.size !in definition.semantics.minimumArguments..definition.semantics.maximumArguments) {
            throw OperationFailure("operation_arity", "Portable operation ${id.value} received ${arguments.size} arguments.")
        }
        return definition.evaluate(arguments, consumeStep, consumeItems)
    }

    companion object {
        val Standard: PortableOperationRegistry = PortableOperationRegistry(standardOperations())
    }
}

class DefaultExpressionEvaluator(
    private val reader: ExpressionValueReader,
    private val operations: PortableOperationRegistry = PortableOperationRegistry.Standard,
) : ExpressionEvaluator {
    context(reads: AuthoredReads)
    override fun evaluate(
        expression: ExpressionNode,
        bindings: ExpressionBindings,
        budget: EvaluationBudget,
    ): Availability<DataValue> = EvaluatorState(reader, operations, bindings, budget).evaluate(expression)
}

object PortableExpressionLimits {
    const val MAX_DEPTH: Int = 512
    const val MAX_REGEX_PATTERN_CODE_UNITS: Int = 512
    const val MAX_REGEX_INPUT_CODE_UNITS: Int = 16_384
}

private class EvaluatorState(
    private val reader: ExpressionValueReader,
    private val operations: PortableOperationRegistry,
    private val bindings: ExpressionBindings,
    private val budget: EvaluationBudget,
) {
    private var steps = 0L
    private var collectionItems = 0L
    private var depth = 0
    private val localValues = mutableMapOf<ExpressionBindingId, DataValue>()
    private val localLocations = mutableMapOf<ExpressionBindingId, ValueLocation>()
    private val observedLocations = linkedSetOf<ValueLocation>()

    context(reads: AuthoredReads)
    fun evaluate(expression: ExpressionNode): Availability<DataValue> =
        try {
            depth += 1
            if (depth > PortableExpressionLimits.MAX_DEPTH) {
                throw OperationFailure(
                    "expression_depth_limit",
                    "The expression exceeded its depth limit.",
                )
            }
            step()
            when (expression) {
                is ExpressionNode.Literal -> available(expression.value)
                is ExpressionNode.Read -> read(expression)
                is ExpressionNode.Call -> call(expression)
                is ExpressionNode.And -> boolean(expression.left, expression.right, conjunction = true)
                is ExpressionNode.Or -> boolean(expression.left, expression.right, conjunction = false)
                is ExpressionNode.Conditional -> conditional(expression)
                is ExpressionNode.OrElse -> orElse(expression)
                is ExpressionNode.Collection -> collection(expression)
            }
        } catch (cancellation: CancellationException) {
            throw cancellation
        } catch (failure: OperationFailure) {
            Availability.Failed(
                EvaluationDiagnostic(failure.code, failure.message.orEmpty(), (observedLocations + localLocations.values).distinct()),
            )
        } catch (failure: Exception) {
            Availability.Failed(
                EvaluationDiagnostic(
                    "expression_evaluation_failed",
                    failure.message ?: failure::class.simpleName.orEmpty(),
                    (observedLocations + localLocations.values).distinct(),
                ),
            )
        } finally {
            depth -= 1
        }

    context(reads: AuthoredReads)
    private fun read(expression: ExpressionNode.Read): Availability<DataValue> {
        val local = localValues[expression.binding]
        if (local != null) {
            val value = local.at(expression.path)
            if (value == DataValue.Unfilled) {
                val location = localLocations[expression.binding]?.append(expression.path)
                return Availability.Unavailable(listOfNotNull(location))
            }
            return available(value)
        }
        val base =
            bindings.locations[expression.binding]
                ?: throw OperationFailure("unknown_expression_binding", "Unknown expression binding ${expression.binding.value}.")
        val location = base.append(expression.path)
        observedLocations += location
        return when (val result = reader.read(location)) {
            is Availability.Available -> if (result.value == DataValue.Unfilled) Availability.Unavailable(listOf(location)) else result
            is Availability.Unavailable -> result
            is Availability.Failed -> result
        }
    }

    context(reads: AuthoredReads)
    private fun call(expression: ExpressionNode.Call): Availability<DataValue> {
        val arguments = mutableListOf<DataValue>()
        val unavailable = linkedSetOf<ValueLocation>()
        val operation = expression.operation.value
        for ((index, argument) in expression.arguments.withIndex()) {
            when (val result = evaluate(argument)) {
                is Availability.Available -> {
                    arguments += result.value
                    if (
                        result.value.containsUnfilled() &&
                        !(index == 0 && operation in PARTIAL_COLLECTION_OPERATIONS)
                    ) {
                        sourceLocation(argument)?.let(unavailable::add)
                    }
                }

                is Availability.Unavailable -> {
                    return result
                }

                is Availability.Failed -> {
                    return result
                }
            }
        }
        if (operation == "typewriter.collection.access") {
            return collectionAccess(arguments, sourceLocation(expression.arguments[0]))
        }
        if (operation == "typewriter.collection.contains") {
            return collectionContains(arguments, sourceLocation(expression.arguments[0]))
        }
        if (operation == "typewriter.rule.unique") {
            return collectionUnique(arguments.single(), sourceLocation(expression.arguments[0]))
        }
        if (unavailable.isNotEmpty()) return Availability.Unavailable(unavailable.toList())
        if (
            arguments.withIndex().any { (index, value) ->
                value.containsUnfilled() && !(index == 0 && operation in PARTIAL_COLLECTION_OPERATIONS)
            }
        ) {
            throw OperationFailure("unfilled_expression_value", "An expression operand contains an unfilled value.")
        }
        return available(operations.evaluate(expression.operation, arguments, ::step, ::consumeItems))
    }

    private fun collectionUnique(
        value: DataValue,
        location: ValueLocation?,
    ): Availability<DataValue> {
        val entries = value.collectionEntries()
        val complete = entries.filterNot { it.value.containsUnfilled() }
        val keys = complete.map { it.value.canonicalValueKey() }
        if (keys.distinct().size != keys.size) return available(DataValue.Boolean(false))
        val unfinished = entries.filter { it.value.containsUnfilled() }
        if (unfinished.isNotEmpty()) {
            return Availability.Unavailable(
                unfinished.mapNotNull { entry -> location?.let(entry::location) },
            )
        }
        return available(DataValue.Boolean(true))
    }

    private fun collectionAccess(
        values: List<DataValue>,
        location: ValueLocation?,
    ): Availability<DataValue> {
        val collection = values[0].unwrapNamed()
        val key = values[1]
        val result =
            when {
                collection is DataValue.ListValue && key.unwrapNamed() is DataValue.Integer -> {
                    val index = (key.unwrapNamed() as DataValue.Integer).value.intValueExact()
                    val item =
                        collection.items.getOrNull(index)
                            ?: throw OperationFailure("collection_key_absent", "The collection key or index is absent.")
                    item.value to location?.append(ValuePath(listOf(PathSegment.Item(item.id))))
                }

                collection is DataValue.MapValue -> {
                    val unfinished = collection.rows.filter { it.key.containsUnfilled() }
                    val matches =
                        collection.rows
                            .filterNot { it.key.containsUnfilled() }
                            .filter { it.key.canonicalValueKey() == key.canonicalValueKey() }
                    if (matches.size > 1 || unfinished.isNotEmpty()) {
                        return Availability.Unavailable(
                            matches.mapNotNull { row ->
                                location?.append(ValuePath(listOf(PathSegment.Item(row.id), PathSegment.MapValue)))
                            } +
                                unfinished.mapNotNull { row ->
                                    location?.append(ValuePath(listOf(PathSegment.Item(row.id), PathSegment.MapKey)))
                                },
                        )
                    }
                    if (matches.isEmpty()) {
                        throw OperationFailure("collection_key_absent", "The collection key or index is absent.")
                    }
                    val row = matches.single()
                    row.value to location?.append(ValuePath(listOf(PathSegment.Item(row.id), PathSegment.MapValue)))
                }

                collection is DataValue.Record && key.unwrapNamed() is DataValue.StringValue -> {
                    val field = (key.unwrapNamed() as DataValue.StringValue).value
                    val value =
                        collection.fields[field]
                            ?: throw OperationFailure("collection_key_absent", "The collection key or index is absent.")
                    value to location?.append(ValuePath(listOf(PathSegment.Field(field))))
                }

                collection is DataValue.StringValue && key.unwrapNamed() is DataValue.Integer -> {
                    val index = (key.unwrapNamed() as DataValue.Integer).value.intValueExact()
                    val value =
                        collection.value
                            .getOrNull(index)
                            ?.toString()
                            ?.let(DataValue::StringValue)
                            ?: throw OperationFailure("collection_key_absent", "The collection key or index is absent.")
                    value to location
                }

                else -> {
                    throw OperationFailure("collection_key_absent", "The collection key or index is absent.")
                }
            }
        return if (result.first.containsUnfilled()) {
            Availability.Unavailable(listOfNotNull(result.second))
        } else {
            available(result.first)
        }
    }

    private fun collectionContains(
        values: List<DataValue>,
        location: ValueLocation?,
    ): Availability<DataValue> {
        val collection = values[0].unwrapNamed()
        val expected = values[1]
        val key = expected.canonicalValueKey()
        val candidates =
            when (collection) {
                is DataValue.ListValue -> {
                    collection.items.map { it.id to it.value }
                }

                is DataValue.SetValue -> {
                    collection.items.map { it.id to it.value }
                }

                is DataValue.MapValue -> {
                    collection.rows.map { it.id to it.key }
                }

                is DataValue.Record -> {
                    val field =
                        (expected.unwrapNamed() as? DataValue.StringValue)?.value
                            ?: throw OperationFailure("expected_collection", "The expression value is not a collection.")
                    return available(DataValue.Boolean(field in collection.fields))
                }

                else -> {
                    throw OperationFailure("expected_collection", "The expression value is not a collection.")
                }
            }
        if (candidates.any { (_, value) -> !value.containsUnfilled() && value.canonicalValueKey() == key }) {
            return available(DataValue.Boolean(true))
        }
        val unfinished = candidates.filter { (_, value) -> value.containsUnfilled() }
        if (unfinished.isNotEmpty()) {
            return Availability.Unavailable(
                unfinished.mapNotNull { (id, _) -> location?.append(ValuePath(listOf(PathSegment.Item(id)))) },
            )
        }
        return available(DataValue.Boolean(false))
    }

    context(reads: AuthoredReads)
    private fun boolean(
        left: ExpressionNode,
        right: ExpressionNode,
        conjunction: Boolean,
    ): Availability<DataValue> {
        val first = evaluate(left)
        if (first !is Availability.Available) return first
        val value = first.value.boolean()
        if ((conjunction && !value) || (!conjunction && value)) return available(DataValue.Boolean(value))
        val second = evaluate(right)
        if (second !is Availability.Available) return second
        return available(DataValue.Boolean(second.value.boolean()))
    }

    context(reads: AuthoredReads)
    private fun conditional(expression: ExpressionNode.Conditional): Availability<DataValue> {
        val test = evaluate(expression.test)
        if (test !is Availability.Available) return test
        return evaluate(if (test.value.boolean()) expression.yes else expression.no)
    }

    context(reads: AuthoredReads)
    private fun orElse(expression: ExpressionNode.OrElse): Availability<DataValue> =
        when (val input = evaluate(expression.input)) {
            is Availability.Available -> {
                if (input.value == DataValue.Null || input.value == DataValue.Unfilled) evaluate(expression.fallback) else input
            }

            is Availability.Unavailable -> {
                evaluate(expression.fallback)
            }

            is Availability.Failed -> {
                input
            }
        }

    context(reads: AuthoredReads)
    private fun collection(expression: ExpressionNode.Collection): Availability<DataValue> {
        val input = evaluate(expression.input)
        if (input !is Availability.Available) return input
        val entries = input.value.collectionEntries()
        val sourceLocation = sourceLocation(expression.input)
        val arguments = mutableListOf<DataValue>()
        expression.arguments.forEach { argument ->
            when (val result = evaluate(argument)) {
                is Availability.Available -> {
                    if (result.value.containsUnfilled()) {
                        return Availability.Unavailable(listOfNotNull(sourceLocation(argument)))
                    }
                    arguments += result.value
                }

                is Availability.Unavailable -> {
                    return result
                }

                is Availability.Failed -> {
                    return result
                }
            }
        }
        return when (expression.operation.value) {
            "typewriter.collection.take" -> {
                requireCollectionShape(expression, bindings = 0, arguments = 1, body = false)
                val count = nonnegativeCount(arguments.single())
                consumeItems(minOf(count, entries.size))
                available(input.value.reorder(entries.take(count)))
            }

            "typewriter.collection.skip" -> {
                requireCollectionShape(expression, bindings = 0, arguments = 1, body = false)
                val count = nonnegativeCount(arguments.single())
                consumeItems(minOf(count, entries.size))
                available(input.value.reorder(entries.drop(count)))
            }

            "typewriter.collection.reverse" -> {
                requireCollectionShape(expression, bindings = 0, arguments = 0, body = false)
                consumeItems(entries.size)
                available(input.value.reorder(entries.reversed()))
            }

            "typewriter.collection.distinct" -> {
                requireCollectionShape(expression, bindings = 0, arguments = 0, body = false)
                collectionDistinct(input.value, entries, sourceLocation)
            }

            "typewriter.collection.reduce", "typewriter.collection.fold" -> {
                collectionFold(expression, entries, arguments, sourceLocation)
            }

            "typewriter.collection.sort_with" -> {
                collectionSortWith(expression, input.value, entries, sourceLocation)
            }

            else -> {
                collectionWithUnaryBody(expression, input.value, entries, arguments, sourceLocation)
            }
        }
    }

    context(reads: AuthoredReads)
    private fun collectionWithUnaryBody(
        expression: ExpressionNode.Collection,
        input: DataValue,
        entries: List<CollectionEntry>,
        arguments: List<DataValue>,
        sourceLocation: ValueLocation?,
    ): Availability<DataValue> {
        val operation = expression.operation.value
        val allowedArguments = if (operation == "typewriter.collection.sort_by") 0..1 else 0..0
        requireCollectionShape(expression, bindings = 1, arguments = allowedArguments, body = true)
        val binding = expression.bindings.single()
        val bodyExpression = requireNotNull(expression.body)
        val results = mutableListOf<Pair<CollectionEntry, DataValue>>()
        val unavailable = linkedSetOf<ValueLocation>()
        for (entry in entries) {
            consumeItems(1)
            val body =
                evaluateWithLocals(
                    listOf(LocalBinding(binding, entry.value, sourceLocation?.let(entry::location))),
                    bodyExpression,
                )
            when (body) {
                is Availability.Available -> {
                    if (body.value.containsUnfilled()) {
                        sourceLocation?.let { unavailable += entry.location(it) }
                        continue
                    }
                    results += entry to body.value
                    if (operation == "typewriter.collection.any" && body.value.boolean()) {
                        return available(DataValue.Boolean(true))
                    }
                    if (operation == "typewriter.collection.all" && !body.value.boolean()) {
                        return available(DataValue.Boolean(false))
                    }
                    if (operation == "typewriter.collection.none" && body.value.boolean()) {
                        return available(DataValue.Boolean(false))
                    }
                    if (operation == "typewriter.collection.find" && body.value.boolean()) {
                        if (unavailable.isNotEmpty()) return Availability.Unavailable(unavailable.toList())
                        return available(entry.value)
                    }
                }

                is Availability.Unavailable -> {
                    unavailable += body.locations
                }

                is Availability.Failed -> {
                    return body
                }
            }
        }
        if (operation == "typewriter.collection.unique_by") {
            val keys = results.map { it.second.canonicalValueKey() }
            if (keys.distinct().size != keys.size) return available(DataValue.Boolean(false))
        }
        if (unavailable.isNotEmpty()) return Availability.Unavailable(unavailable.toList())
        return when (operation) {
            "typewriter.collection.any" -> {
                available(DataValue.Boolean(false))
            }

            "typewriter.collection.all", "typewriter.collection.none" -> {
                available(DataValue.Boolean(true))
            }

            "typewriter.collection.unique_by" -> {
                available(DataValue.Boolean(true))
            }

            "typewriter.collection.map" -> {
                available(DataValue.ListValue(results.map { (entry, value) -> ListItem(entry.id, value) }))
            }

            "typewriter.collection.filter" -> {
                val retained = results.filter { it.second.boolean() }.map { it.first }
                available(input.reorder(retained))
            }

            "typewriter.collection.find" -> {
                available(DataValue.Null)
            }

            "typewriter.collection.find_last" -> {
                available(results.lastOrNull { it.second.boolean() }?.first?.value ?: DataValue.Null)
            }

            "typewriter.collection.count" -> {
                available(DataValue.Integer(results.count { it.second.boolean() }.toBigInteger()))
            }

            "typewriter.collection.distinct_by" -> {
                val seen = hashSetOf<String>()
                available(input.reorder(results.filter { seen.add(it.second.canonicalValueKey()) }.map { it.first }))
            }

            "typewriter.collection.sort_by" -> {
                val descending = arguments.singleOrNull()?.boolean() ?: false
                val sorted =
                    results.sortedWith { left, right ->
                        val comparison = comparePortable(left.second, right.second)
                        if (descending) -comparison else comparison
                    }
                available(input.reorder(sorted.map { it.first }))
            }

            "typewriter.collection.group_by" -> {
                available(groupByKey(results))
            }

            "typewriter.collection.flat_map" -> {
                val flattened =
                    results.flatMap { (outer, value) ->
                        value.collectionEntries().map { inner ->
                            ListItem(nestedItemId(outer.id, inner.id), inner.value)
                        }
                    }
                available(DataValue.ListValue(flattened))
            }

            else -> {
                throw OperationFailure("unknown_collection_operation", "Unknown collection operation ${expression.operation.value}.")
            }
        }
    }

    context(reads: AuthoredReads)
    private fun collectionFold(
        expression: ExpressionNode.Collection,
        entries: List<CollectionEntry>,
        arguments: List<DataValue>,
        sourceLocation: ValueLocation?,
    ): Availability<DataValue> {
        val fold = expression.operation.value == "typewriter.collection.fold"
        requireCollectionShape(expression, bindings = 2, arguments = if (fold) 1 else 0, body = true)
        val body = requireNotNull(expression.body)
        if (!fold && entries.isEmpty()) return available(DataValue.Null)
        var accumulator = if (fold) arguments.single() else entries.first().value
        var accumulatorLocation =
            if (fold) {
                this.sourceLocation(
                    expression.arguments.single(),
                )
            } else {
                sourceLocation?.let(entries.first()::location)
            }
        val remaining = if (fold) entries else entries.drop(1)
        remaining.forEach { entry ->
            consumeItems(1)
            val result =
                evaluateWithLocals(
                    listOf(
                        LocalBinding(expression.bindings[0], accumulator, accumulatorLocation),
                        LocalBinding(expression.bindings[1], entry.value, sourceLocation?.let(entry::location)),
                    ),
                    body,
                )
            when (result) {
                is Availability.Available -> {
                    if (result.value.containsUnfilled()) {
                        return Availability.Unavailable(listOfNotNull(sourceLocation?.let(entry::location)))
                    }
                    accumulator = result.value
                    accumulatorLocation = null
                }

                is Availability.Unavailable -> {
                    return result
                }

                is Availability.Failed -> {
                    return result
                }
            }
        }
        return available(accumulator)
    }

    context(reads: AuthoredReads)
    private fun collectionSortWith(
        expression: ExpressionNode.Collection,
        input: DataValue,
        entries: List<CollectionEntry>,
        sourceLocation: ValueLocation?,
    ): Availability<DataValue> {
        requireCollectionShape(expression, bindings = 2, arguments = 0, body = true)
        val sorted = mutableListOf<CollectionEntry>()
        for (entry in entries) {
            var insertion = sorted.size
            while (insertion > 0) {
                consumeItems(2)
                val left = sorted[insertion - 1]
                val comparison =
                    evaluateWithLocals(
                        listOf(
                            LocalBinding(expression.bindings[0], left.value, sourceLocation?.let(left::location)),
                            LocalBinding(expression.bindings[1], entry.value, sourceLocation?.let(entry::location)),
                        ),
                        requireNotNull(expression.body),
                    )
                when (comparison) {
                    is Availability.Available -> {
                        if (comparison.value.containsUnfilled()) {
                            return Availability.Unavailable(
                                listOfNotNull(sourceLocation?.let(left::location), sourceLocation?.let(entry::location)),
                            )
                        }
                        if (number(comparison.value).signum() <= 0) break
                        insertion -= 1
                    }

                    is Availability.Unavailable -> {
                        return comparison
                    }

                    is Availability.Failed -> {
                        return comparison
                    }
                }
            }
            sorted.add(insertion, entry)
        }
        return available(input.reorder(sorted))
    }

    private fun collectionDistinct(
        input: DataValue,
        entries: List<CollectionEntry>,
        sourceLocation: ValueLocation?,
    ): Availability<DataValue> {
        consumeItems(entries.size)
        val unfinished = entries.filter { it.value.containsUnfilled() }
        if (unfinished.isNotEmpty()) {
            return Availability.Unavailable(unfinished.mapNotNull { entry -> sourceLocation?.let(entry::location) })
        }
        val seen = hashSetOf<String>()
        return available(input.reorder(entries.filter { seen.add(it.value.canonicalValueKey()) }))
    }

    context(reads: AuthoredReads)
    private fun evaluateWithLocals(
        values: List<LocalBinding>,
        body: ExpressionNode,
    ): Availability<DataValue> {
        val previous =
            values.associate { binding ->
                binding.id to
                    PreviousLocal(
                        binding.id in localValues,
                        localValues[binding.id],
                        binding.id in localLocations,
                        localLocations[binding.id],
                    )
            }
        return try {
            values.forEach { binding ->
                localValues[binding.id] = binding.value
                if (binding.location == null) localLocations.remove(binding.id) else localLocations[binding.id] = binding.location
            }
            evaluate(body)
        } finally {
            previous.forEach { (id, state) ->
                if (state.hadValue) localValues[id] = requireNotNull(state.value) else localValues.remove(id)
                if (state.hadLocation) localLocations[id] = requireNotNull(state.location) else localLocations.remove(id)
            }
        }
    }

    private fun requireCollectionShape(
        expression: ExpressionNode.Collection,
        bindings: Int,
        arguments: Int,
        body: Boolean,
    ) = requireCollectionShape(expression, bindings, arguments..arguments, body)

    private fun requireCollectionShape(
        expression: ExpressionNode.Collection,
        bindings: Int,
        arguments: IntRange,
        body: Boolean,
    ) {
        if (expression.bindings.size != bindings || expression.arguments.size !in arguments || (expression.body != null) != body) {
            throw OperationFailure(
                "collection_operation_shape",
                "Collection operation ${expression.operation.value} has an invalid binding, argument, or body shape.",
            )
        }
        if (expression.bindings.distinct().size != expression.bindings.size) {
            throw OperationFailure("duplicate_collection_binding", "Collection expression bindings must be distinct.")
        }
    }

    private fun step() {
        steps += 1
        if (steps > budget.maxSteps) throw OperationFailure("expression_step_limit", "The expression exceeded its step limit.")
    }

    private fun consumeItems(count: Int) {
        collectionItems += count
        if (collectionItems > budget.maxCollectionItems) {
            throw OperationFailure("expression_collection_limit", "The expression exceeded its collection item limit.")
        }
    }

    private fun sourceLocation(expression: ExpressionNode): ValueLocation? =
        when (expression) {
            is ExpressionNode.Read -> {
                (localLocations[expression.binding] ?: bindings.locations[expression.binding])?.append(expression.path)
            }

            else -> {
                null
            }
        }
}

private val PARTIAL_COLLECTION_OPERATIONS =
    setOf(
        "typewriter.collection.size",
        "typewriter.rule.minimumItems",
        "typewriter.rule.maximumItems",
        "typewriter.rule.itemsBetween",
        "typewriter.rule.unique",
    )

context(reads: AuthoredReads)
fun ExpressionNode.evaluateWith(
    evaluator: ExpressionEvaluator,
    bindings: ExpressionBindings,
    budget: EvaluationBudget,
): Availability<DataValue> = evaluator.evaluate(this, bindings, budget)

private data class OperationDefinition(
    val semantics: PortableOperationSemantics,
    val evaluate: (List<DataValue>, () -> Unit, (Int) -> Unit) -> DataValue,
)

private class OperationFailure(
    val code: String,
    message: String,
) : IllegalArgumentException(message)

private data class CollectionEntry(
    val id: com.typewritermc.authoring.ItemId,
    val value: DataValue,
) {
    fun location(base: ValueLocation): ValueLocation = base.append(ValuePath(listOf(PathSegment.Item(id))))
}

private data class LocalBinding(
    val id: ExpressionBindingId,
    val value: DataValue,
    val location: ValueLocation?,
)

private data class PreviousLocal(
    val hadValue: Boolean,
    val value: DataValue?,
    val hadLocation: Boolean,
    val location: ValueLocation?,
)

private fun DataValue.collectionEntries(): List<CollectionEntry> =
    when (val value = unwrapNamed()) {
        is DataValue.ListValue -> {
            value.items.map { CollectionEntry(it.id, it.value) }
        }

        is DataValue.SetValue -> {
            value.items.map { CollectionEntry(it.id, it.value) }
        }

        is DataValue.MapValue -> {
            value.rows.map { row ->
                CollectionEntry(row.id, DataValue.Record(mapOf("key" to row.key, "value" to row.value)))
            }
        }

        else -> {
            throw OperationFailure("expected_collection", "The expression value is not a collection.")
        }
    }

private fun DataValue.reorder(entries: List<CollectionEntry>): DataValue =
    when (this) {
        is DataValue.Named -> {
            copy(payload = payload.reorder(entries))
        }

        is DataValue.ListValue -> {
            val byId = items.associateBy(ListItem::id)
            copy(items = entries.map { entry -> requireNotNull(byId[entry.id]) })
        }

        is DataValue.SetValue -> {
            val byId = items.associateBy(ListItem::id)
            copy(items = entries.map { entry -> requireNotNull(byId[entry.id]) })
        }

        is DataValue.MapValue -> {
            val byId = rows.associateBy(MapRow::id)
            copy(rows = entries.map { entry -> requireNotNull(byId[entry.id]) })
        }

        else -> {
            throw OperationFailure("expected_collection", "The expression value is not a collection.")
        }
    }

private fun groupByKey(results: List<Pair<CollectionEntry, DataValue>>): DataValue.MapValue {
    val groups = linkedMapOf<String, Pair<DataValue, MutableList<CollectionEntry>>>()
    results.forEach { (entry, key) ->
        groups.getOrPut(key.canonicalValueKey()) { key to mutableListOf() }.second += entry
    }
    return DataValue.MapValue(
        groups.values.map { (key, entries) ->
            MapRow(
                entries.first().id,
                key,
                DataValue.ListValue(entries.map { entry -> ListItem(entry.id, entry.value) }),
            )
        },
    )
}

private fun nestedItemId(
    outer: com.typewritermc.authoring.ItemId,
    inner: com.typewritermc.authoring.ItemId,
): com.typewritermc.authoring.ItemId =
    com.typewritermc.authoring.ItemId("${outer.value.length}:${outer.value}${inner.value.length}:${inner.value}")

private fun nonnegativeCount(value: DataValue): Int {
    val count = integer(value)
    if (count < 0) throw OperationFailure("negative_collection_count", "A collection count cannot be negative.")
    return count
}

private fun comparePortable(
    left: DataValue,
    right: DataValue,
): Int {
    val first = left.unwrapNamed()
    val second = right.unwrapNamed()
    return when {
        first is DataValue.Integer || first is DataValue.Float || first is DataValue.Decimal -> compareNumbers(listOf(first, second))
        first is DataValue.StringValue && second is DataValue.StringValue -> compareCodePoints(first.value, second.value)
        first is DataValue.Boolean && second is DataValue.Boolean -> first.value.compareTo(second.value)
        first is DataValue.Timestamp && second is DataValue.Timestamp -> first.value.compareTo(second.value)
        first is DataValue.Duration && second is DataValue.Duration -> first.value.compareTo(second.value)
        else -> throw OperationFailure("collection_value_not_ordered", "The collection key does not have portable ordering semantics.")
    }
}

private fun compareCodePoints(
    left: String,
    right: String,
): Int {
    val first = left.codePoints().iterator()
    val second = right.codePoints().iterator()
    while (first.hasNext() && second.hasNext()) {
        val comparison = first.nextInt().compareTo(second.nextInt())
        if (comparison != 0) return comparison
    }
    return first.hasNext().compareTo(second.hasNext())
}

private fun DataValue.at(path: ValuePath): DataValue {
    var current = this
    path.segments.forEach { segment ->
        current = current.unwrapNamed()
        current =
            when (segment) {
                is PathSegment.Field -> {
                    (current as? DataValue.Record)?.fields?.get(segment.name)
                }

                is PathSegment.Item -> {
                    when (current) {
                        is DataValue.ListValue -> {
                            current.items.firstOrNull { it.id == segment.id }?.value
                        }

                        is DataValue.SetValue -> {
                            current.items.firstOrNull { it.id == segment.id }?.value
                        }

                        is DataValue.MapValue -> {
                            current.rows.firstOrNull { it.id == segment.id }?.let {
                                DataValue.Record(mapOf("key" to it.key, "value" to it.value))
                            }
                        }

                        else -> {
                            null
                        }
                    }
                }

                PathSegment.MapKey -> {
                    (current as? DataValue.Record)?.fields?.get("key")
                }

                PathSegment.MapValue -> {
                    (current as? DataValue.Record)?.fields?.get("value")
                }
            } ?: throw OperationFailure("missing_expression_path", "The expression path does not exist.")
    }
    return current
}

private fun ValueLocation.append(path: ValuePath): ValueLocation = copy(path = ValuePath(this.path.segments + path.segments))

private fun DataValue.unwrapNamed(): DataValue = if (this is DataValue.Named) payload.unwrapNamed() else this

private fun DataValue.boolean(): Boolean =
    (unwrapNamed() as? DataValue.Boolean)?.value
        ?: throw OperationFailure("expected_boolean", "The expression value is not Boolean.")

private fun available(value: DataValue): Availability<DataValue> = Availability.Available(value)

private fun standardOperations(): List<OperationDefinition> =
    buildList {
        operation("typewriter.value.eq", 2, "equality") {
            DataValue.Boolean(it[0].canonicalValueKey() == it[1].canonicalValueKey())
        }
        operation("typewriter.value.neq", 2, "inequality") {
            DataValue.Boolean(it[0].canonicalValueKey() != it[1].canonicalValueKey())
        }
        operation("typewriter.value.is_null", 1, "null test") { DataValue.Boolean(it.single() == DataValue.Null) }
        operation("typewriter.link.target", 1, "relationship target identity") {
            val link =
                it.single().unwrapNamed() as? DataValue.Link
                    ?: throw OperationFailure("expected_link", "The expression value is not a relationship link.")
            DataValue.StringValue(link.target.resource.value)
        }
        operation("typewriter.record.field", 2, "record field access") {
            val record =
                it[0].unwrapNamed() as? DataValue.Record
                    ?: throw OperationFailure("expected_record", "The expression value is not a record.")
            record.fields[text(it[1])]
                ?: throw OperationFailure("record_field_absent", "The record field is absent.")
        }
        operation("typewriter.boolean.not", 1, "Boolean negation") { DataValue.Boolean(!it.single().boolean()) }
        operation("typewriter.number.gt", 2, "numeric greater than") { DataValue.Boolean(compareNumbers(it) > 0) }
        operation("typewriter.number.gte", 2, "numeric greater than or equal") { DataValue.Boolean(compareNumbers(it) >= 0) }
        operation("typewriter.number.lt", 2, "numeric less than") { DataValue.Boolean(compareNumbers(it) < 0) }
        operation("typewriter.number.lte", 2, "numeric less than or equal") { DataValue.Boolean(compareNumbers(it) <= 0) }
        operation("typewriter.number.add", 2, Int.MAX_VALUE, "numeric addition") { arithmetic(it, Arithmetic.Add) }
        operation("typewriter.number.subtract", 2, Int.MAX_VALUE, "numeric subtraction") { arithmetic(it, Arithmetic.Subtract) }
        operation("typewriter.number.multiply", 2, Int.MAX_VALUE, "numeric multiplication") { arithmetic(it, Arithmetic.Multiply) }
        operation("typewriter.number.divide", 2, Int.MAX_VALUE, "numeric division") { arithmetic(it, Arithmetic.Divide) }
        operation("typewriter.number.remainder", 2, Int.MAX_VALUE, "numeric remainder") { arithmetic(it, Arithmetic.Remainder) }
        operation("typewriter.number.negate", 1, "numeric negation") { arithmetic(it, Arithmetic.Negate) }
        operation("typewriter.text.length", 1, "Unicode text length") { DataValue.Integer(text(it).codePointCount().toBigInteger()) }
        operation("typewriter.text.has_line_break", 1, "text line boundary test") { DataValue.Boolean(text(it).hasLineBreak()) }
        operation("typewriter.text.trim", 1, "trimmed text") { DataValue.StringValue(text(it).portableTrim()) }
        operation("typewriter.text.lower", 1, "lowercase text") { DataValue.StringValue(text(it).lowercase()) }
        operation("typewriter.text.upper", 1, "uppercase text") { DataValue.StringValue(text(it).uppercase()) }
        operation("typewriter.text.title", 1, "title case text") { DataValue.StringValue(text(it).titleCase()) }
        operationWithBudgets("typewriter.text.replace", 3, "text replacement") { values, consumeStep, _ ->
            val source = text(values[0])
            val target = text(values[1])
            val replacement = text(values[2])
            chargeLiteralReplacement(source, target, replacement, consumeStep)
            DataValue.StringValue(
                if (target.isEmpty()) {
                    replaceBetweenCodePoints(source, replacement)
                } else {
                    source.replace(target, replacement)
                },
            )
        }
        operationWithBudgets("typewriter.text.split", 2, "text splitting") { values, _, consumeItems ->
            val source = text(values[0])
            val separator = text(values[1])
            consumeItems(literalSplitItemCount(source, separator))
            val parts = if (separator.isEmpty()) source.splitIntoCodePoints() else source.split(separator)
            DataValue.ListValue(
                parts.mapIndexed { index, value ->
                    ListItem(com.typewritermc.authoring.ItemId("split.$index"), DataValue.StringValue(value))
                },
            )
        }
        operationWithBudgets("typewriter.text.join", 2, "text joining") { arguments, consumeStep, _ ->
            val values = arguments[0].collectionEntries().map { entry -> text(entry.value) }
            val separator = text(arguments[1])
            values.forEachIndexed { index, value ->
                if (index > 0) chargeCodePoints(separator, consumeStep)
                chargeCodePoints(value, consumeStep)
            }
            DataValue.StringValue(values.joinToString(separator))
        }
        operation("typewriter.text.substring", 2, 3, "text substring") { substring(it) }
        operation("typewriter.text.contains", 2, "text containment") { DataValue.Boolean(text(it[0]).contains(text(it[1]))) }
        operation("typewriter.text.starts_with", 2, "text prefix") { DataValue.Boolean(text(it[0]).startsWith(text(it[1]))) }
        operation("typewriter.text.ends_with", 2, "text suffix") { DataValue.Boolean(text(it[0]).endsWith(text(it[1]))) }
        add(
            OperationDefinition(
                PortableOperationSemantics(OperationId("typewriter.text.interpolate"), 0, Int.MAX_VALUE, "text interpolation"),
            ) { values, consumeStep, _ ->
                val rendered = values.map(DataValue::displayText)
                rendered.forEach { chargeCodePoints(it, consumeStep) }
                DataValue.StringValue(rendered.joinToString(separator = ""))
            },
        )
        operationWithSteps("typewriter.regex.matches", 2, "regular expression search") { values, consumeStep ->
            DataValue.Boolean(regex(values).containsMatchIn(text(values[0]), consumeStep))
        }
        operationWithSteps("typewriter.regex.capture", 3, "regular expression capture") { values, consumeStep ->
            val group = integer(values[2])
            require(group in 0..32) { "Regular expression capture group is out of range." }
            val input = text(values[0])
            val match =
                regex(values).find(input, consumeStep)
                    ?: throw OperationFailure("regex_no_match", "The regular expression did not match.")
            DataValue.StringValue(
                match.group(input, group)
                    ?: throw OperationFailure("regex_group_absent", "The regular expression capture group is absent."),
            )
        }
        operationWithSteps("typewriter.regex.replace", 3, "regular expression replacement") { values, consumeStep ->
            val pattern = regex(values)
            try {
                DataValue.StringValue(pattern.replace(text(values[0]), text(values[2]), consumeStep))
            } catch (_: PortableRegexCompileFailure) {
                throw OperationFailure("invalid_regex_replacement", "The regular expression replacement is invalid.")
            }
        }
        operation("typewriter.collection.size", 1, "collection cardinality") { DataValue.Integer(size(it.single()).toBigInteger()) }
        operation("typewriter.collection.access", 2, "collection access") { collectionAccess(it) }
        operation("typewriter.collection.contains", 2, "collection containment") { collectionContains(it) }
        operation("typewriter.color.with_alpha", 2, "color alpha replacement") { colorWithAlpha(it) }
        operation("typewriter.rule.one_of", 2, Int.MAX_VALUE, "allowed values") { values ->
            DataValue.Boolean(
                values.drop(1).any { it.canonicalValueKey() == values[0].canonicalValueKey() },
            )
        }
        operation("typewriter.rule.nonEmpty", 1, "nonempty value") { DataValue.Boolean(size(it.single()) > 0) }
        operation("typewriter.rule.nonBlank", 1, "nonblank text") { DataValue.Boolean(!text(it).portableIsBlank()) }
        operation("typewriter.rule.minimumLength", 2, "minimum value length") { DataValue.Boolean(size(it[0]) >= integer(it[1])) }
        operation("typewriter.rule.maximumLength", 2, "maximum value length") { DataValue.Boolean(size(it[0]) <= integer(it[1])) }
        operation("typewriter.rule.lengthBetween", 3, "bounded value length") {
            DataValue.Boolean(size(it[0]) in integer(it[1])..integer(it[2]))
        }
        operation("typewriter.rule.minimumLines", 2, "minimum text lines") { DataValue.Boolean(lineCount(text(it)) >= integer(it[1])) }
        operation("typewriter.rule.maximumLines", 2, "maximum text lines") { DataValue.Boolean(lineCount(text(it)) <= integer(it[1])) }
        operation("typewriter.rule.singleLine", 1, "single line text") { DataValue.Boolean(!text(it).hasLineBreak()) }
        operationWithSteps("typewriter.rule.regex", 2, "regular expression match") { values, consumeStep ->
            DataValue.Boolean(regex(values).matches(text(values), consumeStep))
        }
        operation("typewriter.rule.startsWith", 2, "text prefix") { DataValue.Boolean(text(it).startsWith(text(it.drop(1)))) }
        operation("typewriter.rule.endsWith", 2, "text suffix") { DataValue.Boolean(text(it).endsWith(text(it.drop(1)))) }
        operation("typewriter.rule.minimum", 3, "numeric minimum") {
            DataValue.Boolean(if (it[2].boolean()) compareNumbers(it) >= 0 else compareNumbers(it) > 0)
        }
        operation("typewriter.rule.maximum", 3, "numeric maximum") {
            DataValue.Boolean(if (it[2].boolean()) compareNumbers(it) <= 0 else compareNumbers(it) < 0)
        }
        operation("typewriter.rule.between", 3, "numeric interval") {
            DataValue.Boolean(number(it[0]) >= number(it[1]) && number(it[0]) <= number(it[2]))
        }
        operation("typewriter.rule.positive", 1, "positive number") { DataValue.Boolean(number(it[0]) > BigDecimal.ZERO) }
        operation("typewriter.rule.nonNegative", 1, "nonnegative number") { DataValue.Boolean(number(it[0]) >= BigDecimal.ZERO) }
        operation("typewriter.rule.multipleOf", 2, "numeric multiple") {
            val divisor = number(it[1])
            DataValue.Boolean(divisor.compareTo(BigDecimal.ZERO) != 0 && number(it[0]).remainder(divisor).compareTo(BigDecimal.ZERO) == 0)
        }
        operation("typewriter.rule.maximumScale", 2, "maximum decimal scale") {
            DataValue.Boolean(number(it[0]).stripTrailingZeros().scale() <= integer(it[1]))
        }
        operation("typewriter.rule.minimumItems", 2, "minimum collection items") { DataValue.Boolean(size(it[0]) >= integer(it[1])) }
        operation("typewriter.rule.maximumItems", 2, "maximum collection items") { DataValue.Boolean(size(it[0]) <= integer(it[1])) }
        operation("typewriter.rule.itemsBetween", 3, "bounded collection items") {
            DataValue.Boolean(size(it[0]) in integer(it[1])..integer(it[2]))
        }
        operation("typewriter.rule.unique", 1, "unique collection values") {
            val values = it.single().collectionEntries().map { entry -> entry.value.canonicalValueKey() }
            DataValue.Boolean(values.distinct().size == values.size)
        }
        operation("typewriter.rule.notNull", 1, "nonnull value") { DataValue.Boolean(it.single() != DataValue.Null) }
        operation("typewriter.rule.notBefore", 2, "timestamp lower bound") { DataValue.Boolean(timestamp(it[0]) >= timestamp(it[1])) }
        operation("typewriter.rule.notAfter", 2, "timestamp upper bound") { DataValue.Boolean(timestamp(it[0]) <= timestamp(it[1])) }
        operation("typewriter.rule.opaque", 1, "opaque color") {
            val bits =
                (it.single().unwrapNamed() as? DataValue.Integer)?.value
                    ?: throw OperationFailure("expected_color", "The color representation is not an integer.")
            DataValue.Boolean(bits.shiftRight(24).and(java.math.BigInteger.valueOf(255)).toInt() == 255)
        }
    }

private fun MutableList<OperationDefinition>.operation(
    id: String,
    arguments: Int,
    meaning: String,
    evaluate: (List<DataValue>) -> DataValue,
) = operation(id, arguments, arguments, meaning, evaluate)

private fun MutableList<OperationDefinition>.operation(
    id: String,
    minimumArguments: Int,
    maximumArguments: Int,
    meaning: String,
    evaluate: (List<DataValue>) -> DataValue,
) {
    add(
        OperationDefinition(
            PortableOperationSemantics(OperationId(id), minimumArguments, maximumArguments, meaning),
        ) { values, _, _ -> evaluate(values) },
    )
}

private fun MutableList<OperationDefinition>.operationWithSteps(
    id: String,
    arguments: Int,
    meaning: String,
    evaluate: (List<DataValue>, () -> Unit) -> DataValue,
) {
    add(
        OperationDefinition(PortableOperationSemantics(OperationId(id), arguments, arguments, meaning)) { values, consumeStep, _ ->
            evaluate(values, consumeStep)
        },
    )
}

private fun MutableList<OperationDefinition>.operationWithBudgets(
    id: String,
    arguments: Int,
    meaning: String,
    evaluate: (List<DataValue>, () -> Unit, (Int) -> Unit) -> DataValue,
) {
    add(OperationDefinition(PortableOperationSemantics(OperationId(id), arguments, arguments, meaning), evaluate))
}

private fun compareNumbers(values: List<DataValue>): Int = number(values[0]).compareTo(number(values[1]))

private enum class Arithmetic { Add, Subtract, Multiply, Divide, Remainder, Negate }

private fun arithmetic(
    values: List<DataValue>,
    operation: Arithmetic,
): DataValue {
    val unwrapped = values.map(DataValue::unwrapNamed)
    if (operation == Arithmetic.Negate) {
        return when (val value = unwrapped.single()) {
            is DataValue.Integer -> {
                DataValue.Integer(value.value.negate())
            }

            is DataValue.Float -> {
                DataValue.Float(finite(-value.value))
            }

            is DataValue.Decimal -> {
                DataValue.Decimal(
                    value.value
                        .toBigDecimal()
                        .negate()
                        .canonicalString(),
                )
            }

            else -> {
                throw OperationFailure("expected_number", "The expression value is not numeric.")
            }
        }
    }
    if (unwrapped.all { it is DataValue.Integer }) {
        var result = (unwrapped.first() as DataValue.Integer).value
        unwrapped.drop(1).map { (it as DataValue.Integer).value }.forEach { operand ->
            if ((operation == Arithmetic.Divide || operation == Arithmetic.Remainder) && operand.signum() == 0) {
                throw OperationFailure("division_by_zero", "Division by zero is not defined.")
            }
            result =
                when (operation) {
                    Arithmetic.Add -> result + operand
                    Arithmetic.Subtract -> result - operand
                    Arithmetic.Multiply -> result * operand
                    Arithmetic.Divide -> result / operand
                    Arithmetic.Remainder -> result.remainder(operand)
                    Arithmetic.Negate -> error("Negation is unary.")
                }
        }
        return DataValue.Integer(result)
    }
    if (unwrapped.all { it is DataValue.Float }) {
        var result = (unwrapped.first() as DataValue.Float).value
        unwrapped.drop(1).map { (it as DataValue.Float).value }.forEach { operand ->
            result =
                when (operation) {
                    Arithmetic.Add -> result + operand
                    Arithmetic.Subtract -> result - operand
                    Arithmetic.Multiply -> result * operand
                    Arithmetic.Divide -> result / operand
                    Arithmetic.Remainder -> result % operand
                    Arithmetic.Negate -> error("Negation is unary.")
                }
            result = finite(result)
        }
        return DataValue.Float(result)
    }
    if (unwrapped.all { it is DataValue.Decimal }) {
        var result = (unwrapped.first() as DataValue.Decimal).value.toBigDecimal()
        unwrapped.drop(1).map { (it as DataValue.Decimal).value.toBigDecimal() }.forEach { operand ->
            if ((operation == Arithmetic.Divide || operation == Arithmetic.Remainder) && operand.compareTo(BigDecimal.ZERO) == 0) {
                throw OperationFailure("division_by_zero", "Division by zero is not defined.")
            }
            result =
                when (operation) {
                    Arithmetic.Add -> result.add(operand)
                    Arithmetic.Subtract -> result.subtract(operand)
                    Arithmetic.Multiply -> result.multiply(operand)
                    Arithmetic.Divide -> result.divide(operand, MathContext.DECIMAL128)
                    Arithmetic.Remainder -> result.remainder(operand)
                    Arithmetic.Negate -> error("Negation is unary.")
                }
        }
        return DataValue.Decimal(result.canonicalString())
    }
    throw OperationFailure("numeric_family_mismatch", "Arithmetic operands must use one numeric representation.")
}

private fun finite(value: Double): Double =
    value.takeIf(Double::isFinite)
        ?: throw OperationFailure("nonfinite_number", "Floating point arithmetic produced a nonfinite value.")

private fun substring(values: List<DataValue>): DataValue {
    val source = text(values[0])
    val start = integer(values[1])
    val length = source.codePointCount()
    val end = values.getOrNull(2)?.let(::integer) ?: length
    if (start < 0 || end < start || end > length) {
        throw OperationFailure("substring_range", "The substring range is invalid.")
    }
    val startIndex = source.offsetByCodePoints(0, start)
    val endIndex = source.offsetByCodePoints(0, end)
    return DataValue.StringValue(source.substring(startIndex, endIndex))
}

private fun BigDecimal.canonicalString(): String = stripTrailingZeros().toPlainString()

private fun chargeLiteralReplacement(
    source: String,
    target: String,
    replacement: String,
    consumeStep: () -> Unit,
) {
    if (target.isEmpty()) {
        val sourceCodePoints = source.codePointCount()
        repeat(sourceCodePoints + 1) { chargeCodePoints(replacement, consumeStep) }
        repeat(sourceCodePoints) { consumeStep() }
        return
    }
    var copiedUntil = 0
    while (true) {
        val match = source.indexOf(target, copiedUntil)
        if (match < 0) {
            chargeCodePoints(source, copiedUntil, source.length, consumeStep)
            return
        }
        chargeCodePoints(source, copiedUntil, match, consumeStep)
        chargeCodePoints(replacement, consumeStep)
        copiedUntil = match + target.length
    }
}

private fun literalSplitItemCount(
    source: String,
    separator: String,
): Int {
    if (separator.isEmpty()) return source.codePointCount()
    var count = 1
    var from = 0
    while (true) {
        val match = source.indexOf(separator, from)
        if (match < 0) return count
        count += 1
        from = match + separator.length
    }
}

private fun replaceBetweenCodePoints(
    source: String,
    replacement: String,
): String =
    buildString {
        append(replacement)
        var offset = 0
        while (offset < source.length) {
            val codePoint = source.codePointAt(offset)
            appendCodePoint(codePoint)
            append(replacement)
            offset += Character.charCount(codePoint)
        }
    }

private fun String.splitIntoCodePoints(): List<String> {
    val count = codePointCount()
    if (count == 0) return emptyList()
    return buildList(count) {
        var offset = 0
        while (offset < length) {
            val codePoint = codePointAt(offset)
            add(String(Character.toChars(codePoint)))
            offset += Character.charCount(codePoint)
        }
    }
}

private fun chargeCodePoints(
    value: String,
    consumeStep: () -> Unit,
) = chargeCodePoints(value, 0, value.length, consumeStep)

private fun chargeCodePoints(
    value: String,
    start: Int,
    end: Int,
    consumeStep: () -> Unit,
) {
    repeat(Character.codePointCount(value, start, end - start)) { consumeStep() }
}

private fun regex(values: List<DataValue>): PortableRegexMatcher {
    val input = text(values[0])
    val pattern = text(values[1])
    if (
        pattern.length > PortableExpressionLimits.MAX_REGEX_PATTERN_CODE_UNITS ||
        input.length > PortableExpressionLimits.MAX_REGEX_INPUT_CODE_UNITS
    ) {
        throw OperationFailure("regex_limit", "The regular expression input exceeds its limit.")
    }
    val normalized =
        when (val normalization = pattern.normalizePortableRegex()) {
            is PortableRegexNormalization.Ready -> {
                normalization.pattern
            }

            is PortableRegexNormalization.Invalid -> {
                throw OperationFailure("invalid_regex", normalization.reason)
            }

            is PortableRegexNormalization.Unsupported -> {
                throw OperationFailure("unsupported_regex_pattern", normalization.reason)
            }
        }
    return try {
        PortableRegexMatcher.compile(normalized)
    } catch (_: PortableRegexCompileFailure) {
        throw OperationFailure("invalid_regex", "The regular expression pattern is invalid.")
    }
}

private fun collectionAccess(values: List<DataValue>): DataValue {
    val collection = values[0].unwrapNamed()
    val key = values[1].unwrapNamed()
    return when {
        collection is DataValue.ListValue && key is DataValue.Integer -> {
            collection.items.getOrNull(key.value.intValueExact())?.value
        }

        collection is DataValue.MapValue -> {
            collection.rows.firstOrNull { it.key.canonicalValueKey() == key.canonicalValueKey() }?.value
        }

        collection is DataValue.Record && key is DataValue.StringValue -> {
            collection.fields[key.value]
        }

        collection is DataValue.StringValue && key is DataValue.Integer -> {
            val index = key.value.intValueExact()
            collection.value
                .getOrNull(index)
                ?.toString()
                ?.let(DataValue::StringValue)
        }

        else -> {
            null
        }
    } ?: throw OperationFailure("collection_key_absent", "The collection key or index is absent.")
}

private fun collectionContains(values: List<DataValue>): DataValue.Boolean {
    val collection = values[0].unwrapNamed()
    val expected = values[1].unwrapNamed()
    val key = expected.canonicalValueKey()
    val contains =
        when (collection) {
            is DataValue.ListValue -> collection.items.any { it.value.canonicalValueKey() == key }
            is DataValue.SetValue -> collection.items.any { it.value.canonicalValueKey() == key }
            is DataValue.MapValue -> collection.rows.any { it.key.canonicalValueKey() == key }
            is DataValue.Record -> (expected as? DataValue.StringValue)?.value in collection.fields
            else -> throw OperationFailure("expected_collection", "The expression value is not a collection.")
        }
    return DataValue.Boolean(contains)
}

private fun colorWithAlpha(values: List<DataValue>): DataValue {
    val original = values[0]
    val color =
        (original.unwrapNamed() as? DataValue.Integer)?.value
            ?: throw OperationFailure("expected_color", "The color representation is not an integer.")
    val alpha = integer(values[1])
    if (alpha !in 0..255) throw OperationFailure("color_alpha_range", "Color alpha must be between zero and 255.")
    val replaced =
        color.and(java.math.BigInteger.valueOf(0x00ffffff)).or(
            java.math.BigInteger
                .valueOf(alpha.toLong())
                .shiftLeft(24),
        )
    val payload = DataValue.Integer(replaced)
    return if (original is DataValue.Named) original.copy(payload = payload) else payload
}

private fun DataValue.displayText(): String =
    when (val value = unwrapNamed()) {
        DataValue.Unfilled, DataValue.Null, DataValue.Unit -> ""
        is DataValue.Boolean -> value.value.toString()
        is DataValue.Integer -> value.value.toString()
        is DataValue.Float -> value.value.toString()
        is DataValue.Decimal -> value.value
        is DataValue.StringValue -> value.value
        is DataValue.Bytes -> "${value.value.size} bytes"
        is DataValue.Timestamp -> value.value.toString()
        is DataValue.Duration -> value.value.toString()
        is DataValue.EnumCase -> value.key
        is DataValue.ListValue -> "${value.items.size} items"
        is DataValue.SetValue -> "${value.items.size} items"
        is DataValue.MapValue -> "${value.rows.size} entries"
        is DataValue.Record -> "record"
        is DataValue.Link -> value.target.toString()
        is DataValue.Named -> error("Named values are unwrapped recursively.")
    }

private fun String.titleCase(): String =
    split(Regex("(\\s+)"))
        .joinToString(" ") { word -> word.lowercase().replaceFirstChar { character -> character.titlecase() } }

private fun number(value: DataValue): BigDecimal =
    when (val scalar = value.unwrapNamed()) {
        is DataValue.Integer -> scalar.value.toBigDecimal()
        is DataValue.Float -> BigDecimal.valueOf(scalar.value)
        is DataValue.Decimal -> scalar.value.toBigDecimal()
        else -> throw OperationFailure("expected_number", "The expression value is not numeric.")
    }

private fun integer(value: DataValue): Int =
    (value.unwrapNamed() as? DataValue.Integer)?.value?.intValueExact()
        ?: throw OperationFailure("expected_integer", "The expression value is not an integer.")

private fun text(values: List<DataValue>): String = text(values.first())

private fun text(value: DataValue): String =
    (value.unwrapNamed() as? DataValue.StringValue)?.value
        ?: throw OperationFailure("expected_text", "The expression value is not text.")

private fun timestamp(value: DataValue): kotlin.time.Instant =
    (value.unwrapNamed() as? DataValue.Timestamp)?.value
        ?: throw OperationFailure("expected_timestamp", "The expression value is not a timestamp.")

private fun size(value: DataValue): Int =
    when (val unwrapped = value.unwrapNamed()) {
        is DataValue.StringValue -> unwrapped.value.codePointCount()
        is DataValue.Bytes -> unwrapped.value.size
        is DataValue.ListValue -> unwrapped.items.size
        is DataValue.SetValue -> unwrapped.items.size
        is DataValue.MapValue -> unwrapped.rows.size
        is DataValue.Record -> unwrapped.fields.size
        else -> throw OperationFailure("expected_sized_value", "The expression value has no size.")
    }

private fun String.codePointCount(): Int = codePointCount(0, length)

private fun String.portableTrim(): String = trim { character -> character.code in PORTABLE_WHITESPACE }

private fun String.portableIsBlank(): Boolean = all { character -> character.code in PORTABLE_WHITESPACE }

private fun String.hasLineBreak(): Boolean = any { it == '\n' || it == '\r' || it == '\u2028' || it == '\u2029' }

private fun DataValue.containsUnfilled(): Boolean =
    when (this) {
        DataValue.Unfilled -> true
        is DataValue.Named -> payload.containsUnfilled()
        is DataValue.Record -> fields.values.any(DataValue::containsUnfilled)
        is DataValue.ListValue -> items.any { it.value.containsUnfilled() }
        is DataValue.SetValue -> items.any { it.value.containsUnfilled() }
        is DataValue.MapValue -> rows.any { it.key.containsUnfilled() || it.value.containsUnfilled() }
        else -> false
    }

private fun lineCount(value: String): Int {
    if (value.isEmpty()) return 0
    var lines = 1
    var index = 0
    while (index < value.length) {
        when (value[index]) {
            '\r' -> {
                lines += 1
                if (index + 1 < value.length && value[index + 1] == '\n') index += 1
            }

            '\n', '\u2028', '\u2029' -> {
                lines += 1
            }
        }
        index += 1
    }
    return lines
}

private val PORTABLE_WHITESPACE =
    setOf(
        0x0009,
        0x000A,
        0x000B,
        0x000C,
        0x000D,
        0x0020,
        0x0085,
        0x00A0,
        0x1680,
        0x2000,
        0x2001,
        0x2002,
        0x2003,
        0x2004,
        0x2005,
        0x2006,
        0x2007,
        0x2008,
        0x2009,
        0x200A,
        0x2028,
        0x2029,
        0x202F,
        0x205F,
        0x3000,
        0xFEFF,
    )
