package com.typewritermc.expression

import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.append
import com.typewritermc.types.actualType
import com.typewritermc.types.bigInteger
import com.typewritermc.types.canonicalValueKey
import com.typewritermc.types.duration
import com.typewritermc.types.field
import com.typewritermc.types.fields
import com.typewritermc.types.instant
import com.typewritermc.types.integer
import com.typewritermc.types.items
import com.typewritermc.types.linkTarget
import com.typewritermc.types.listValue
import com.typewritermc.types.mapValue
import com.typewritermc.types.named
import com.typewritermc.types.payload
import com.typewritermc.types.record
import com.typewritermc.types.requirePortable
import com.typewritermc.types.requireValid
import com.typewritermc.types.rows
import com.typewritermc.types.setValue
import com.typewritermc.types.skir.SkirAuthoringValueCodec
import com.typewritermc.types.skir.SkirConversionResult
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import com.typewritermc.types.unknownVariant
import com.typewritermc.types.unwrapNamed
import com.typewritermc.types.use
import kotlinx.coroutines.CancellationException
import skirout.editor.v1.expression.BoundDirection
import skirout.editor.v1.expression.ConditionalExpression
import skirout.editor.v1.expression.EntryBranch
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.expression.ExpressionQuery
import skirout.editor.v1.expression.NumberArithmeticOperation
import skirout.editor.v1.expression.NumberCompareOperation
import skirout.editor.v1.expression.OrElseExpression
import skirout.editor.v1.expression.RegexMatchMode
import skirout.editor.v1.expression.RuleUnaryOperation
import skirout.editor.v1.expression.SizeBoundMetric
import skirout.editor.v1.expression.SizeRangeMetric
import skirout.editor.v1.expression.TextCompareOperation
import skirout.editor.v1.expression.TextUnaryOperation
import skirout.editor.v1.expression.TimestampBoundDirection
import skirout.editor.v1.expression.ValueCompareOperation
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.MapRow
import java.math.BigDecimal
import java.math.MathContext

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
 * Missing authored inputs remain [Availability.Unavailable], while invalid operations and exhausted budgets produce
 * diagnostics. Boolean branches short circuit; fallback expressions recover missing or null values while preserving
 * evaluation failures. Canonical resource and catalog queries require [evaluateChecked] so each call uses its checked
 * lexical contract and the supplied query reader's catalog matches the authored observation.
 */
class DefaultExpressionEvaluator(
    private val reader: ExpressionValueReader,
    private val queries: CanonicalQueryReader? = null,
) : ExpressionEvaluator {
    context(reads: AuthoredReads)
    override fun evaluate(
        expression: ExpressionNode,
        bindings: ExpressionBindings,
        budget: EvaluationBudget,
    ): Availability<DataValue> = evaluateScoped(expression, bindings, emptyMap(), budget)

    context(reads: AuthoredReads)
    fun evaluateChecked(
        program: CheckedExpressionProgram,
        bindings: ExpressionBindings,
        budget: EvaluationBudget,
        localValues: Map<ExpressionBindingId, DataValue> = emptyMap(),
    ): Availability<DataValue> = EvaluatorState(reader, bindings, budget, localValues, queries, program.queries).evaluate(program.body)

    context(reads: AuthoredReads)
    override fun evaluateScoped(
        expression: ExpressionNode,
        bindings: ExpressionBindings,
        localValues: Map<ExpressionBindingId, DataValue>,
        budget: EvaluationBudget,
    ): Availability<DataValue> {
        require(localValues.keys.none(bindings.locations::containsKey)) { "Local expression bindings must not replace source bindings." }
        return EvaluatorState(reader, bindings, budget, localValues).evaluate(expression)
    }
}

object PortableExpressionLimits {
    const val MAX_DEPTH: Int = 512
    const val MAX_REGEX_PATTERN_CODE_UNITS: Int = 512
    const val MAX_REGEX_INPUT_CODE_UNITS: Int = 16_384
}

private class EvaluatorState(
    private val reader: ExpressionValueReader,
    private val bindings: ExpressionBindings,
    private val budget: EvaluationBudget,
    initialValues: Map<ExpressionBindingId, DataValue>,
    private val queries: CanonicalQueryReader? = null,
    private val queryContracts: Map<ExpressionOccurrence, CheckedQueryCall> = emptyMap(),
) {
    private var currentOccurrence = ExpressionOccurrence()
    private var collectionBodyOccurrence = ExpressionOccurrence()
    private var steps = 0L
    private var collectionItems = 0L
    private var depth = 0
    private val inputValues = initialValues.toMap()
    private val frames = mutableListOf<List<LocalBinding>>()
    private val observedLocations = linkedSetOf<ValueLocation>()

    context(reads: AuthoredReads)
    fun evaluate(expression: ExpressionNode): Availability<DataValue> {
        return try {
            depth += 1
            if (depth > PortableExpressionLimits.MAX_DEPTH) {
                throw OperationFailure(
                    "expression_depth_limit",
                    "The expression exceeded its depth limit.",
                )
            }
            step()
            val projection = projection(expression)
            if (projection != null) return evaluateProjection(projection)
            return when (expression) {
                is ExpressionNode.Unknown -> {
                    throw OperationFailure("unknown_expression", "Unknown expression node.")
                }

                is ExpressionNode.LiteralWrapper -> {
                    available(decodeLiteral(expression.value))
                }

                is ExpressionNode.AndWrapper -> {
                    boolean(expression.value.left, expression.value.right, true)
                }

                is ExpressionNode.OrWrapper -> {
                    boolean(expression.value.left, expression.value.right, false)
                }

                is ExpressionNode.ConditionalWrapper -> {
                    conditional(expression.value)
                }

                is ExpressionNode.OrElseWrapper -> {
                    orElse(expression.value)
                }

                is ExpressionNode.AnyWrapper -> {
                    collection(expression, expression.value.source, body = expression.value.body)
                }

                is ExpressionNode.AllWrapper -> {
                    collection(expression, expression.value.source, body = expression.value.body)
                }

                is ExpressionNode.NoneWrapper -> {
                    collection(expression, expression.value.source, body = expression.value.body)
                }

                is ExpressionNode.MapWrapper -> {
                    collection(expression, expression.value.source, body = expression.value.body)
                }

                is ExpressionNode.FilterWrapper -> {
                    collection(expression, expression.value.source, body = expression.value.body)
                }

                is ExpressionNode.FindWrapper -> {
                    collection(expression, expression.value.source, body = expression.value.body)
                }

                is ExpressionNode.FindLastWrapper -> {
                    collection(expression, expression.value.source, body = expression.value.body)
                }

                is ExpressionNode.CountWrapper -> {
                    collection(expression, expression.value.source, body = expression.value.body)
                }

                is ExpressionNode.DistinctByWrapper -> {
                    collection(expression, expression.value.source, body = expression.value.body)
                }

                is ExpressionNode.GroupByWrapper -> {
                    collection(expression, expression.value.source, body = expression.value.body)
                }

                is ExpressionNode.FlatMapWrapper -> {
                    collection(expression, expression.value.source, body = expression.value.body)
                }

                is ExpressionNode.UniqueByWrapper -> {
                    collection(expression, expression.value.source, body = expression.value.body)
                }

                is ExpressionNode.ReduceWrapper -> {
                    collection(expression, expression.value.source, body = expression.value.body)
                }

                is ExpressionNode.FoldWrapper -> {
                    collection(
                        expression,
                        expression.value.source,
                        listOf(expression.value.initial),
                        expression.value.body,
                        2,
                    )
                }

                is ExpressionNode.SortByWrapper -> {
                    collection(
                        expression,
                        expression.value.source,
                        listOfNotNull(expression.value.descending),
                        expression.value.key,
                        2,
                    )
                }

                is ExpressionNode.SortWithWrapper -> {
                    collection(expression, expression.value.source, body = expression.value.comparator)
                }

                is ExpressionNode.TakeWrapper -> {
                    collection(expression, expression.value.source, listOf(expression.value.count))
                }

                is ExpressionNode.SkipWrapper -> {
                    collection(expression, expression.value.source, listOf(expression.value.count))
                }

                is ExpressionNode.ReverseWrapper -> {
                    collection(expression, expression.value)
                }

                is ExpressionNode.DistinctWrapper -> {
                    collection(expression, expression.value)
                }

                is ExpressionNode.FieldWrapper -> {
                    field(
                        expression.value.source,
                        ValuePath(listOf(PathSegment.Field(expression.value.name))),
                    )
                }

                is ExpressionNode.EntryProjectionWrapper -> {
                    field(
                        expression.value.source,
                        ValuePath(listOf(expression.value.branch.pathSegment())),
                    )
                }

                else -> {
                    scalar(expression)
                }
            }
        } catch (cancellation: CancellationException) {
            throw cancellation
        } catch (failure: OperationFailure) {
            Availability.Failed(
                EvaluationDiagnostic(
                    failure.code,
                    failure.message.orEmpty(),
                    (
                        observedLocations +
                            frames.flatten().mapNotNull { it.location }
                    ).distinct(),
                ),
            )
        } catch (failure: Exception) {
            Availability.Failed(
                EvaluationDiagnostic(
                    "expression_evaluation_failed",
                    failure.message ?: failure::class.simpleName.orEmpty(),
                    (observedLocations + frames.flatten().mapNotNull { it.location }).distinct(),
                ),
            )
        } finally {
            depth -= 1
        }
    }

    context(reads: AuthoredReads)
    private fun evaluateAt(
        expression: ExpressionNode,
        occurrence: ExpressionOccurrence,
    ): Availability<DataValue> {
        val previous = currentOccurrence
        currentOccurrence = occurrence
        return try {
            evaluate(expression)
        } finally {
            currentOccurrence = previous
        }
    }

    context(reads: AuthoredReads)
    private fun child(
        expression: ExpressionNode,
        index: Int,
    ): Availability<DataValue> = evaluateAt(expression, currentOccurrence.child(index))

    private data class Projection(
        val root: ExpressionNode,
        val path: ValuePath,
        val occurrence: ExpressionOccurrence,
        val descents: Int,
    )

    private fun projection(expression: ExpressionNode): Projection? {
        var root = expression
        var occurrence = currentOccurrence
        val reversed = mutableListOf<PathSegment>()
        while (true) {
            if (depth + reversed.size >
                PortableExpressionLimits.MAX_DEPTH
            ) {
                throw OperationFailure("expression_depth_limit", "Projection depth exceeded.")
            }
            when (val node = root) {
                is ExpressionNode.FieldWrapper -> {
                    reversed += PathSegment.Field(node.value.name)
                    root = node.value.source
                }

                is ExpressionNode.EntryProjectionWrapper -> {
                    reversed += node.value.branch.pathSegment()
                    root = node.value.source
                }

                else -> {
                    break
                }
            }
            occurrence = occurrence.child(0)
        }
        if (root !is ExpressionNode.InputWrapper && root !is ExpressionNode.LocalWrapper &&
            root !is ExpressionNode.QueryWrapper
        ) {
            return null
        }
        return Projection(root, ValuePath(reversed.asReversed()), occurrence, reversed.size)
    }

    private fun local(
        depth: Int,
        slot: Int,
    ): LocalBinding {
        if (depth < 0 || slot < 0) throw OperationFailure("invalid_expression_local", "Invalid local address.")
        return frames.getOrNull(frames.lastIndex - depth)?.getOrNull(slot)
            ?: throw OperationFailure("invalid_expression_local", "The local address is outside its lambda.")
    }

    context(reads: AuthoredReads)
    private fun evaluateProjection(projection: Projection): Availability<DataValue> {
        repeat(projection.descents) { step() }
        return when (val root = projection.root) {
            is ExpressionNode.InputWrapper -> {
                val binding = ExpressionBindingId(root.value.binding.value)
                val path = SkirAuthoringValueCodec.decode(root.value.path).getOrThrow().append(projection.path)
                val value = inputValues[binding]
                if (value != null) {
                    projected(value.at(path))
                } else {
                    val base =
                        bindings.locations[binding]
                            ?: throw OperationFailure("unknown_expression_binding", "Unknown expression binding ${binding.value}.")
                    readAt(base.append(path))
                }
            }

            is ExpressionNode.LocalWrapper -> {
                val value = local(root.value.depth, root.value.slot)
                val path = SkirAuthoringValueCodec.decode(root.value.path).getOrThrow().append(projection.path)
                value.location?.append(path)?.let { observedLocations += it }
                val selected = value.value.at(path)
                if (selected ==
                    DataValue.UNFILLED
                ) {
                    Availability.Unavailable(listOfNotNull(value.location?.append(path)))
                } else {
                    available(selected)
                }
            }

            is ExpressionNode.QueryWrapper -> {
                canonicalQuery(root.value, projection.path, projection.occurrence)
            }

            else -> {
                error("Projection root was not admitted")
            }
        }
    }

    context(reads: AuthoredReads)
    private fun readAt(location: ValueLocation): Availability<DataValue> {
        observedLocations += location
        return when (val result = reader.read(location)) {
            is Availability.Available -> if (result.value == DataValue.UNFILLED) Availability.Unavailable(listOf(location)) else result
            is Availability.Unavailable -> result
            is Availability.Failed -> result
        }
    }

    context(reads: AuthoredReads)
    private fun field(
        source: ExpressionNode,
        path: ValuePath,
    ): Availability<DataValue> {
        val value = child(source, 0)
        if (value !is Availability.Available) return value
        if (value.value.unwrapNamed() == DataValue.NULL || value.value == DataValue.UNFILLED) return Availability.Unavailable(emptyList())
        return projected(value.value.at(path))
    }

    context(reads: AuthoredReads)
    private fun scalar(expression: ExpressionNode): Availability<DataValue> {
        val operands = expression.children()
        val arguments = mutableListOf<DataValue>()
        val unavailable = linkedSetOf<ValueLocation>()
        val partialSource =
            when (expression) {
                is ExpressionNode.CollectionSizeWrapper -> true
                is ExpressionNode.RuleUnaryWrapper -> expression.value.operation == RuleUnaryOperation.UNIQUE
                is ExpressionNode.RuleSizeBoundWrapper -> expression.value.metric == SizeBoundMetric.COLLECTION_ITEMS
                is ExpressionNode.RuleSizeRangeWrapper -> expression.value.metric == SizeRangeMetric.COLLECTION_ITEMS
                else -> false
            }
        for ((position, operand) in operands.withIndex()) {
            when (val result = child(operand.node, operand.index)) {
                is Availability.Available -> {
                    arguments += result.value
                    if (result.value.containsUnfilled() &&
                        !(position == 0 && partialSource)
                    ) {
                        sourceLocation(operand.node)?.let(unavailable::add)
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
        when (expression) {
            is ExpressionNode.CollectionAccessWrapper -> {
                return collectionAccess(arguments, sourceLocation(expression.value.source))
            }

            is ExpressionNode.CollectionContainsWrapper -> {
                return collectionContains(arguments, sourceLocation(expression.value.source))
            }

            is ExpressionNode.RuleUnaryWrapper -> {
                if (expression.value.operation ==
                    RuleUnaryOperation.UNIQUE
                ) {
                    return collectionUnique(arguments.single(), sourceLocation(expression.value.source))
                }
            }

            else -> {
                Unit
            }
        }
        if (unavailable.isNotEmpty()) return Availability.Unavailable(unavailable.toList())
        if (arguments.withIndex().any { (index, value) -> value.containsUnfilled() && !(index == 0 && partialSource) }) {
            throw OperationFailure("unfilled_expression_value", "An expression operand contains an unfilled value.")
        }
        return available(scalarValue(expression, arguments, ::step, ::consumeItems))
    }

    context(reads: AuthoredReads)
    private fun canonicalQuery(
        expression: ExpressionQuery,
        suffix: ValuePath,
        occurrence: ExpressionOccurrence,
    ): Availability<DataValue> {
        val operation = expression.kind
        val fields =
            suffix.segments.map { segment ->
                (segment as? PathSegment.Field)?.name
                    ?: throw OperationFailure("invalid_model_projection", "Canonical model projection requires fields.")
            }
        val contract =
            queryContracts[occurrence] ?: throw OperationFailure("unchecked_query", "Canonical queries require checked lexical contracts.")
        val source = evaluateAt(expression.sourceExpression(), occurrence.child(0))
        if (source !is Availability.Available) return source
        if (operation == ExpressionQuery.Kind.VALUE_CONFIGURATION_WRAPPER) {
            val named = source.value as? DataValue.NamedWrapper ?: return Availability.Unavailable(emptyList())
            return projected(
                readModel(
                    com.typewritermc.authoring.TypeSelection
                        .Complete(named.actualType),
                    fields,
                ),
            )
        }
        val query = queries ?: throw OperationFailure("unsupported_query", "The expression has no canonical snapshot query capability.")
        if (query.catalog.generation !=
            reads.catalog
        ) {
            throw OperationFailure("query_catalog_mismatch", "Canonical queries must use the authored read catalog.")
        }
        if (operation == ExpressionQuery.Kind.CATALOG_DECLARATION_WRAPPER) {
            // Temporary bridge until data values are Skir values: the selection is read back through its Skir read model.
            val selection =
                CanonicalReadModels.typeSelection.decode(source.value.requirePortable())
            val definition =
                when (selection) {
                    is skirout.editor.v1.type_catalog.TypeSelection.CompleteWrapper -> selection.value.definition
                    is skirout.editor.v1.type_catalog.TypeSelection.PendingWrapper -> selection.value.definition
                    else -> throw OperationFailure("invalid_type_selection", "The type selection variant is unknown.")
                }
            return when (val declaration = query.declaration(definition.requireValid())) {
                is Availability.Available -> {
                    projected(project(CanonicalReadModels.publishedType.encode(declaration.value, fields)))
                }

                is Availability.Unavailable -> {
                    declaration
                }

                is Availability.Failed -> {
                    declaration
                }
            }
        }
        val id =
            if (contract.sourceIsReference) {
                val link =
                    source.value.unwrapNamed() as? DataValue.LinkWrapper
                        ?: throw OperationFailure("expected_link", "The query receiver is not a relationship.")
                link.linkTarget.resource
            } else {
                val named =
                    source.value as? DataValue.NamedWrapper
                        ?: throw OperationFailure("expected_resource_identity", "Resource queries require a typed identity.")
                if (named.actualType !=
                    com.typewritermc.types.ResourceIdDefinition.use
                ) {
                    throw OperationFailure("expected_resource_identity", "Resource queries require a typed identity.")
                }
                com.typewritermc.types.ResourceId(text(named))
            }
        val path = suffix
        val location =
            ValueLocation(
                id,
                if (operation ==
                    ExpressionQuery.Kind.RESOURCE_VALUE_WRAPPER
                ) {
                    path
                } else {
                    com.typewritermc.authoring.ValuePath()
                },
            )
        observedLocations += location
        val record =
            when (val selected = query.resource(id)) {
                is Availability.Available -> selected.value
                is Availability.Unavailable -> return selected
                is Availability.Failed -> return selected
            }
        val expected = requireNotNull(contract.targetType)
        val readable = query.catalog.knownApplications(record.configuration).any { query.catalog.isReadableAs(it.use, expected) }
        if (!readable) {
            if (!contract.sourceIsReference ||
                record.configuration is com.typewritermc.authoring.TypeSelection.Pending
            ) {
                return Availability.Unavailable(listOf(location))
            }
            throw OperationFailure("incompatible_resource_reference", "The referenced resource does not match its checked target contract.")
        }
        return when (operation) {
            ExpressionQuery.Kind.RESOURCE_IDENTITY_WRAPPER -> {
                available(DataValue.named(com.typewritermc.types.ResourceIdDefinition.use, DataValue.StringValueWrapper(id.value)))
            }

            ExpressionQuery.Kind.RESOURCE_CONFIGURATION_WRAPPER -> {
                projected(readModel(record.configuration, fields))
            }

            ExpressionQuery.Kind.RESOURCE_VALUE_WRAPPER -> {
                var payload: DataValue = DataValue.record(record.fields)
                for (field in fields) {
                    step()
                    val current = payload.unwrapNamed()
                    if (current == DataValue.NULL || current == DataValue.UNFILLED) return Availability.Unavailable(listOf(location))
                    val currentRecord =
                        current as? DataValue.RecordWrapper
                            ?: throw OperationFailure("expected_record", "The expression value is not a record.")
                    payload =
                        currentRecord.field(field) ?: if (record.configuration is com.typewritermc.authoring.TypeSelection.Complete) {
                            throw OperationFailure("record_field_absent", "A complete record is missing a declared field.")
                        } else {
                            return Availability.Unavailable(listOf(location))
                        }
                }
                val configuration = record.configuration
                if (fields.isEmpty() &&
                    configuration is com.typewritermc.authoring.TypeSelection.Complete
                ) {
                    payload =
                        DataValue.named(configuration.use, payload)
                }
                if (fields.isEmpty()) chargeProjection(payload)
                projected(payload)
            }

            else -> {
                error("The canonical query operation is not a resource read.")
            }
        }
    }

    private fun chargeProjection(
        value: DataValue,
        depth: Int = 0,
    ) {
        if (depth >
            PortableExpressionLimits.MAX_DEPTH
        ) {
            throw OperationFailure("expression_depth_limit", "The projected value exceeded its depth limit.")
        }
        step()
        when (value) {
            is DataValue.NamedWrapper -> {
                chargeProjection(value.payload, depth + 1)
            }

            is DataValue.RecordWrapper -> {
                value.fields.forEach { chargeProjection(it.value, depth + 1) }
            }

            is DataValue.ListValueWrapper -> {
                consumeItems(value.items.size)
                value.items.forEach { chargeProjection(it.value, depth + 1) }
            }

            is DataValue.SetValueWrapper -> {
                consumeItems(value.items.size)
                value.items.forEach { chargeProjection(it.value, depth + 1) }
            }

            is DataValue.MapValueWrapper -> {
                consumeItems(value.rows.size)
                value.rows.forEach {
                    chargeProjection(it.key, depth + 1)
                    chargeProjection(
                        it.value,
                        depth + 1,
                    )
                }
            }

            else -> {
                Unit
            }
        }
    }

    /** Projects a type selection through its Skir read model. Temporary bridge until type selections are Skir values. */
    private fun readModel(
        selection: com.typewritermc.authoring.TypeSelection,
        fields: List<String>,
    ): DataValue = project(CanonicalReadModels.typeSelection.encode(SkirAuthoringValueCodec.encode(selection).getOrThrow(), fields))

    private fun project(value: skirout.editor.v1.type_catalog.DataValue): DataValue = value.requirePortable()

    private fun <T> CanonicalReadModel<T>.encode(
        value: T,
        fields: List<String>,
    ) = CanonicalReadModels.encode(value, serializer.typeDescriptor, fields, ::step, ::consumeItems)

    private fun projected(value: DataValue): Availability<DataValue> =
        if (value ==
            DataValue.UNFILLED
        ) {
            Availability.Unavailable(emptyList())
        } else {
            available(value)
        }

    private fun collectionUnique(
        value: DataValue,
        location: ValueLocation?,
    ): Availability<DataValue> {
        val entries = value.collectionEntries()
        val complete = entries.filterNot { it.value.containsUnfilled() }
        val keys = complete.map { it.value.canonicalValueKey() }
        if (keys.distinct().size != keys.size) return available(DataValue.BooleanWrapper(false))
        val unfinished = entries.filter { it.value.containsUnfilled() }
        if (unfinished.isNotEmpty()) {
            return Availability.Unavailable(
                unfinished.mapNotNull { entry -> location?.let(entry::location) },
            )
        }
        return available(DataValue.BooleanWrapper(true))
    }

    private fun collectionAccess(
        values: List<DataValue>,
        location: ValueLocation?,
    ): Availability<DataValue> {
        val collection = values[0].unwrapNamed()
        val key = values[1]
        val result =
            when {
                collection is DataValue.ListValueWrapper && key.unwrapNamed() is DataValue.IntegerWrapper -> {
                    val index = (key.unwrapNamed() as DataValue.IntegerWrapper).bigInteger.intValueExact()
                    val item =
                        collection.items.getOrNull(index)
                            ?: throw OperationFailure("collection_key_absent", "The collection key or index is absent.")
                    item.value to location?.append(ValuePath(listOf(PathSegment.Item(item.id))))
                }

                collection is DataValue.MapValueWrapper -> {
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

                collection is DataValue.RecordWrapper && key.unwrapNamed() is DataValue.StringValueWrapper -> {
                    val field = (key.unwrapNamed() as DataValue.StringValueWrapper).value
                    val value =
                        collection.field(field)
                            ?: throw OperationFailure("collection_key_absent", "The collection key or index is absent.")
                    value to location?.append(ValuePath(listOf(PathSegment.Field(field))))
                }

                collection is DataValue.StringValueWrapper && key.unwrapNamed() is DataValue.IntegerWrapper -> {
                    val index = (key.unwrapNamed() as DataValue.IntegerWrapper).bigInteger.intValueExact()
                    val value =
                        collection.value
                            .getOrNull(index)
                            ?.toString()
                            ?.let(DataValue::StringValueWrapper)
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
                is DataValue.ListValueWrapper -> {
                    collection.items.map { it.id to it.value }
                }

                is DataValue.SetValueWrapper -> {
                    collection.items.map { it.id to it.value }
                }

                is DataValue.MapValueWrapper -> {
                    collection.rows.map { it.id to it.key }
                }

                is DataValue.RecordWrapper -> {
                    val field =
                        (expected.unwrapNamed() as? DataValue.StringValueWrapper)?.value
                            ?: throw OperationFailure("expected_collection", "The expression value is not a collection.")
                    return available(DataValue.BooleanWrapper(collection.field(field) != null))
                }

                else -> {
                    throw OperationFailure("expected_collection", "The expression value is not a collection.")
                }
            }
        if (candidates.any { (_, value) -> !value.containsUnfilled() && value.canonicalValueKey() == key }) {
            return available(DataValue.BooleanWrapper(true))
        }
        val unfinished = candidates.filter { (_, value) -> value.containsUnfilled() }
        if (unfinished.isNotEmpty()) {
            return Availability.Unavailable(
                unfinished.mapNotNull { (id, _) -> location?.append(ValuePath(listOf(PathSegment.Item(id)))) },
            )
        }
        return available(DataValue.BooleanWrapper(false))
    }

    context(reads: AuthoredReads)
    private fun boolean(
        left: ExpressionNode,
        right: ExpressionNode,
        conjunction: Boolean,
    ): Availability<DataValue> {
        val first = child(left, 0)
        if (first !is Availability.Available) return first
        val value = first.value.boolean()
        if ((conjunction && !value) || (!conjunction && value)) return available(DataValue.BooleanWrapper(value))
        val second = child(right, 1)
        if (second !is Availability.Available) return second
        return available(DataValue.BooleanWrapper(second.value.boolean()))
    }

    context(reads: AuthoredReads)
    private fun conditional(expression: ConditionalExpression): Availability<DataValue> {
        val test = child(expression.test, 0)
        if (test !is Availability.Available) return test
        return if (test.value.boolean()) child(expression.yes, 1) else child(expression.no, 2)
    }

    context(reads: AuthoredReads)
    private fun orElse(expression: OrElseExpression): Availability<DataValue> =
        when (val input = child(expression.input, 0)) {
            is Availability.Available -> {
                if (input.value == DataValue.NULL || input.value == DataValue.UNFILLED) child(expression.fallback, 1) else input
            }

            is Availability.Unavailable -> {
                child(expression.fallback, 1)
            }

            is Availability.Failed -> {
                input
            }
        }

    context(reads: AuthoredReads)
    private fun collection(
        expression: ExpressionNode,
        source: ExpressionNode,
        arguments: List<ExpressionNode> = emptyList(),
        body: ExpressionNode? = null,
        bodyIndex: Int = 1,
    ): Availability<DataValue> {
        val previous = collectionBodyOccurrence
        collectionBodyOccurrence = currentOccurrence.child(bodyIndex)
        try {
            val input = child(source, 0)
            if (input !is Availability.Available) return input
            val entries = input.value.collectionEntries()
            val location = sourceLocation(source)
            val values = mutableListOf<DataValue>()
            for ((index, argument) in arguments.withIndex()) {
                when (val result = child(argument, index + 1)) {
                    is Availability.Available -> {
                        if (result.value.containsUnfilled()) return Availability.Unavailable(listOfNotNull(sourceLocation(argument)))
                        values += result.value
                    }

                    is Availability.Unavailable -> {
                        return result
                    }

                    is Availability.Failed -> {
                        return result
                    }
                }
            }
            return when (expression.kind) {
                ExpressionNode.Kind.TAKE_WRAPPER -> {
                    val count = nonnegativeCount(values.single())
                    consumeItems(minOf(count, entries.size))
                    available(input.value.reorder(entries.take(count)))
                }

                ExpressionNode.Kind.SKIP_WRAPPER -> {
                    val count = nonnegativeCount(values.single())
                    consumeItems(minOf(count, entries.size))
                    available(input.value.reorder(entries.drop(count)))
                }

                ExpressionNode.Kind.REVERSE_WRAPPER -> {
                    consumeItems(entries.size)
                    available(input.value.reorder(entries.reversed()))
                }

                ExpressionNode.Kind.DISTINCT_WRAPPER -> {
                    collectionDistinct(input.value, entries, location)
                }

                ExpressionNode.Kind.FOLD_WRAPPER, ExpressionNode.Kind.REDUCE_WRAPPER -> {
                    collectionFold(
                        expression.kind,
                        requireNotNull(body),
                        entries,
                        values,
                        arguments.singleOrNull()?.let(::sourceLocation),
                        location,
                    )
                }

                ExpressionNode.Kind.SORT_WITH_WRAPPER -> {
                    collectionSortWith(requireNotNull(body), input.value, entries, location)
                }

                else -> {
                    collectionWithUnaryBody(expression.kind, requireNotNull(body), input.value, entries, values, location)
                }
            }
        } finally {
            collectionBodyOccurrence = previous
        }
    }

    context(reads: AuthoredReads)
    private fun collectionWithUnaryBody(
        operation: ExpressionNode.Kind,
        bodyExpression: ExpressionNode,
        input: DataValue,
        entries: List<CollectionEntry>,
        arguments: List<DataValue>,
        sourceLocation: ValueLocation?,
    ): Availability<DataValue> {
        val results = mutableListOf<Pair<CollectionEntry, DataValue>>()
        val unavailable = linkedSetOf<ValueLocation>()
        for (entry in entries) {
            consumeItems(1)
            val body =
                evaluateWithLocals(
                    listOf(LocalBinding(entry.value, sourceLocation?.let(entry::location))),
                    bodyExpression,
                )
            when (body) {
                is Availability.Available -> {
                    if (body.value.containsUnfilled()) {
                        sourceLocation?.let { unavailable += entry.location(it) }
                        continue
                    }
                    results += entry to body.value
                    if (operation == ExpressionNode.Kind.ANY_WRAPPER && body.value.boolean()) {
                        return available(DataValue.BooleanWrapper(true))
                    }
                    if (operation == ExpressionNode.Kind.ALL_WRAPPER && !body.value.boolean()) {
                        return available(DataValue.BooleanWrapper(false))
                    }
                    if (operation == ExpressionNode.Kind.NONE_WRAPPER && body.value.boolean()) {
                        return available(DataValue.BooleanWrapper(false))
                    }
                    if (operation == ExpressionNode.Kind.FIND_WRAPPER && body.value.boolean()) {
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
        if (operation == ExpressionNode.Kind.UNIQUE_BY_WRAPPER) {
            val keys = results.map { it.second.canonicalValueKey() }
            if (keys.distinct().size != keys.size) return available(DataValue.BooleanWrapper(false))
        }
        if (unavailable.isNotEmpty()) return Availability.Unavailable(unavailable.toList())
        return when (operation) {
            ExpressionNode.Kind.ANY_WRAPPER -> {
                available(DataValue.BooleanWrapper(false))
            }

            ExpressionNode.Kind.ALL_WRAPPER, ExpressionNode.Kind.NONE_WRAPPER -> {
                available(DataValue.BooleanWrapper(true))
            }

            ExpressionNode.Kind.UNIQUE_BY_WRAPPER -> {
                available(DataValue.BooleanWrapper(true))
            }

            ExpressionNode.Kind.MAP_WRAPPER -> {
                available(DataValue.listValue(results.map { (entry, value) -> ListItem(id = entry.id, value = value) }))
            }

            ExpressionNode.Kind.FILTER_WRAPPER -> {
                val retained = results.filter { it.second.boolean() }.map { it.first }
                available(input.reorder(retained))
            }

            ExpressionNode.Kind.FIND_WRAPPER -> {
                available(DataValue.NULL)
            }

            ExpressionNode.Kind.FIND_LAST_WRAPPER -> {
                available(results.lastOrNull { it.second.boolean() }?.first?.value ?: DataValue.NULL)
            }

            ExpressionNode.Kind.COUNT_WRAPPER -> {
                available(DataValue.integer(results.count { it.second.boolean() }.toBigInteger()))
            }

            ExpressionNode.Kind.DISTINCT_BY_WRAPPER -> {
                val seen = hashSetOf<String>()
                available(input.reorder(results.filter { seen.add(it.second.canonicalValueKey()) }.map { it.first }))
            }

            ExpressionNode.Kind.SORT_BY_WRAPPER -> {
                val descending = arguments.singleOrNull()?.boolean() ?: false
                val sorted =
                    results.sortedWith { left, right ->
                        val comparison = comparePortable(left.second, right.second)
                        if (descending) -comparison else comparison
                    }
                available(input.reorder(sorted.map { it.first }))
            }

            ExpressionNode.Kind.GROUP_BY_WRAPPER -> {
                available(groupByKey(results))
            }

            ExpressionNode.Kind.FLAT_MAP_WRAPPER -> {
                val flattened =
                    results.flatMap { (outer, value) ->
                        value.collectionEntries().map { inner ->
                            ListItem(id = nestedItemId(outer.id, inner.id), value = inner.value)
                        }
                    }
                available(DataValue.listValue(flattened))
            }

            else -> {
                throw OperationFailure("unknown_collection_operation", "Unknown collection operation $operation.")
            }
        }
    }

    context(reads: AuthoredReads)
    private fun collectionFold(
        operation: ExpressionNode.Kind,
        body: ExpressionNode,
        entries: List<CollectionEntry>,
        arguments: List<DataValue>,
        initialLocation: ValueLocation?,
        sourceLocation: ValueLocation?,
    ): Availability<DataValue> {
        val fold = operation == ExpressionNode.Kind.FOLD_WRAPPER
        if (!fold && entries.isEmpty()) return available(DataValue.NULL)
        var accumulator = if (fold) arguments.single() else entries.first().value
        var accumulatorLocation =
            if (fold) {
                initialLocation
            } else {
                sourceLocation?.let(entries.first()::location)
            }
        val remaining = if (fold) entries else entries.drop(1)
        remaining.forEach { entry ->
            consumeItems(1)
            val result =
                evaluateWithLocals(
                    listOf(
                        LocalBinding(accumulator, accumulatorLocation),
                        LocalBinding(entry.value, sourceLocation?.let(entry::location)),
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
        body: ExpressionNode,
        input: DataValue,
        entries: List<CollectionEntry>,
        sourceLocation: ValueLocation?,
    ): Availability<DataValue> {
        val sorted = mutableListOf<CollectionEntry>()
        for (entry in entries) {
            var insertion = sorted.size
            while (insertion > 0) {
                consumeItems(2)
                val left = sorted[insertion - 1]
                val comparison =
                    evaluateWithLocals(
                        listOf(
                            LocalBinding(left.value, sourceLocation?.let(left::location)),
                            LocalBinding(entry.value, sourceLocation?.let(entry::location)),
                        ),
                        body,
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
        frames += values.toList()
        return try {
            evaluateAt(body, collectionBodyOccurrence)
        } finally {
            frames.removeAt(frames.lastIndex)
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

    private fun sourceLocation(expression: ExpressionNode): ValueLocation? {
        val projection = projection(expression) ?: return null
        return when (val root = projection.root) {
            is ExpressionNode.InputWrapper -> {
                bindings.locations[
                    ExpressionBindingId(
                        root.value.binding.value,
                    ),
                ]?.append(SkirAuthoringValueCodec.decode(root.value.path).getOrThrow())?.append(projection.path)
            }

            is ExpressionNode.LocalWrapper -> {
                local(
                    root.value.depth,
                    root.value.slot,
                ).location?.append(SkirAuthoringValueCodec.decode(root.value.path).getOrThrow())?.append(projection.path)
            }

            else -> {
                null
            }
        }
    }
}

context(reads: AuthoredReads)
fun ExpressionNode.evaluateWith(
    evaluator: ExpressionEvaluator,
    bindings: ExpressionBindings,
    budget: EvaluationBudget,
): Availability<DataValue> = evaluator.evaluate(this, bindings, budget)

internal class OperationFailure(
    val code: String,
    message: String,
) : IllegalArgumentException(message)

private data class CollectionEntry(
    val id: skirout.editor.v1.type_catalog.ItemId,
    val value: DataValue,
) {
    fun location(base: ValueLocation): ValueLocation = base.append(ValuePath(listOf(PathSegment.Item(id))))
}

private data class LocalBinding(
    val value: DataValue,
    val location: ValueLocation?,
)

private fun DataValue.collectionEntries(): List<CollectionEntry> =
    when (val value = unwrapNamed()) {
        is DataValue.ListValueWrapper -> {
            value.items.map { CollectionEntry(it.id, it.value) }
        }

        is DataValue.SetValueWrapper -> {
            value.items.map { CollectionEntry(it.id, it.value) }
        }

        is DataValue.MapValueWrapper -> {
            value.rows.map { row ->
                CollectionEntry(row.id, DataValue.record(mapOf("key" to row.key, "value" to row.value)))
            }
        }

        else -> {
            throw OperationFailure("expected_collection", "The expression value is not a collection.")
        }
    }

private fun DataValue.reorder(entries: List<CollectionEntry>): DataValue =
    when (this) {
        is DataValue.NamedWrapper -> {
            DataValue.named(actualType, payload.reorder(entries))
        }

        is DataValue.ListValueWrapper -> {
            val byId = items.associateBy(ListItem::id)
            DataValue.listValue(entries.map { entry -> requireNotNull(byId[entry.id]) })
        }

        is DataValue.SetValueWrapper -> {
            val byId = items.associateBy(ListItem::id)
            DataValue.setValue(entries.map { entry -> requireNotNull(byId[entry.id]) })
        }

        is DataValue.MapValueWrapper -> {
            val byId = rows.associateBy(MapRow::id)
            DataValue.mapValue(entries.map { entry -> requireNotNull(byId[entry.id]) })
        }

        else -> {
            throw OperationFailure("expected_collection", "The expression value is not a collection.")
        }
    }

private fun groupByKey(results: List<Pair<CollectionEntry, DataValue>>): DataValue.MapValueWrapper {
    val groups = linkedMapOf<String, Pair<DataValue, MutableList<CollectionEntry>>>()
    results.forEach { (entry, key) ->
        groups.getOrPut(key.canonicalValueKey()) { key to mutableListOf() }.second += entry
    }
    return DataValue.mapValue(
        groups.values.map { (key, entries) ->
            MapRow(
                id = entries.first().id,
                key = key,
                value = DataValue.listValue(entries.map { entry -> ListItem(id = entry.id, value = entry.value) }),
            )
        },
    )
}

private fun nestedItemId(
    outer: skirout.editor.v1.type_catalog.ItemId,
    inner: skirout.editor.v1.type_catalog.ItemId,
): skirout.editor.v1.type_catalog.ItemId =
    skirout.editor.v1.type_catalog
        .ItemId(value = "${outer.value.length}:${outer.value}${inner.value.length}:${inner.value}")

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
        first is DataValue.IntegerWrapper || first is DataValue.FloatWrapper || first is DataValue.DecimalWrapper -> {
            compareNumbers(
                listOf(first, second),
            )
        }

        first is DataValue.StringValueWrapper && second is DataValue.StringValueWrapper -> {
            compareCodePoints(first.value, second.value)
        }

        first is DataValue.BooleanWrapper && second is DataValue.BooleanWrapper -> {
            first.value.compareTo(second.value)
        }

        first is DataValue.TimestampWrapper && second is DataValue.TimestampWrapper -> {
            first.value.compareTo(second.value)
        }

        first is DataValue.DurationWrapper && second is DataValue.DurationWrapper -> {
            first.duration.compareTo(second.duration)
        }

        else -> {
            throw OperationFailure("collection_value_not_ordered", "The collection key does not have portable ordering semantics.")
        }
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
                    (current as? DataValue.RecordWrapper)?.field(segment.name)
                }

                is PathSegment.Item -> {
                    when (current) {
                        is DataValue.ListValueWrapper -> {
                            current.items.firstOrNull { it.id == segment.id }?.value
                        }

                        is DataValue.SetValueWrapper -> {
                            current.items.firstOrNull { it.id == segment.id }?.value
                        }

                        is DataValue.MapValueWrapper -> {
                            current.rows.firstOrNull { it.id == segment.id }?.let {
                                DataValue.record(mapOf("key" to it.key, "value" to it.value))
                            }
                        }

                        else -> {
                            null
                        }
                    }
                }

                PathSegment.MapKey -> {
                    (current as? DataValue.RecordWrapper)?.field("key")
                }

                PathSegment.MapValue -> {
                    (current as? DataValue.RecordWrapper)?.field("value")
                }
            } ?: throw OperationFailure("missing_expression_path", "The expression path does not exist.")
    }
    return current
}

private fun DataValue.boolean(): Boolean =
    (unwrapNamed() as? DataValue.BooleanWrapper)?.value
        ?: throw OperationFailure("expected_boolean", "The expression value is not Boolean.")

private fun available(value: DataValue): Availability<DataValue> = Availability.Available(value)

private fun scalarValue(
    node: ExpressionNode,
    values: List<DataValue>,
    consumeStep: () -> Unit,
    consumeItems: (Int) -> Unit,
): DataValue =
    when (node) {
        is ExpressionNode.TextUnaryWrapper -> {
            when (node.value.operation) {
                TextUnaryOperation.VALUE -> primitive(values) { DataValue.StringValueWrapper(text(it)) }
                TextUnaryOperation.TRIM -> primitive(values) { DataValue.StringValueWrapper(text(it).portableTrim()) }
                TextUnaryOperation.LOWER -> primitive(values) { DataValue.StringValueWrapper(text(it).lowercase()) }
                TextUnaryOperation.UPPER -> primitive(values) { DataValue.StringValueWrapper(text(it).uppercase()) }
                TextUnaryOperation.TITLE -> primitive(values) { DataValue.StringValueWrapper(text(it).titleCase()) }
                else -> unknownVariant()
            }
        }

        is ExpressionNode.TextCompareWrapper -> {
            when (node.value.operation) {
                TextCompareOperation.CONTAINS -> primitive(values) { DataValue.BooleanWrapper(text(it[0]).contains(text(it[1]))) }
                TextCompareOperation.STARTS_WITH -> primitive(values) { DataValue.BooleanWrapper(text(it[0]).startsWith(text(it[1]))) }
                TextCompareOperation.ENDS_WITH -> primitive(values) { DataValue.BooleanWrapper(text(it[0]).endsWith(text(it[1]))) }
                else -> unknownVariant()
            }
        }

        is ExpressionNode.ValueCompareWrapper -> {
            when (node.value.operation) {
                ValueCompareOperation.EQUAL -> {
                    primitive(values) {
                        DataValue.BooleanWrapper(it[0].canonicalValueKey() == it[1].canonicalValueKey())
                    }
                }

                ValueCompareOperation.NOT_EQUAL -> {
                    primitive(values) {
                        DataValue.BooleanWrapper(it[0].canonicalValueKey() != it[1].canonicalValueKey())
                    }
                }

                else -> {
                    unknownVariant()
                }
            }
        }

        is ExpressionNode.NumberCompareWrapper -> {
            when (node.value.operation) {
                NumberCompareOperation.GREATER -> primitive(values) { DataValue.BooleanWrapper(compareNumbers(it) > 0) }
                NumberCompareOperation.GREATER_EQUAL -> primitive(values) { DataValue.BooleanWrapper(compareNumbers(it) >= 0) }
                NumberCompareOperation.LESS -> primitive(values) { DataValue.BooleanWrapper(compareNumbers(it) < 0) }
                NumberCompareOperation.LESS_EQUAL -> primitive(values) { DataValue.BooleanWrapper(compareNumbers(it) <= 0) }
                else -> unknownVariant()
            }
        }

        is ExpressionNode.NumberArithmeticWrapper -> {
            when (node.value.operation) {
                NumberArithmeticOperation.ADD -> primitive(values) { arithmetic(it, Arithmetic.Add) }
                NumberArithmeticOperation.SUBTRACT -> primitive(values) { arithmetic(it, Arithmetic.Subtract) }
                NumberArithmeticOperation.MULTIPLY -> primitive(values) { arithmetic(it, Arithmetic.Multiply) }
                NumberArithmeticOperation.DIVIDE -> primitive(values) { arithmetic(it, Arithmetic.Divide) }
                NumberArithmeticOperation.REMAINDER -> primitive(values) { arithmetic(it, Arithmetic.Remainder) }
                else -> unknownVariant()
            }
        }

        is ExpressionNode.RuleUnaryWrapper -> {
            when (node.value.operation) {
                RuleUnaryOperation.NON_EMPTY -> {
                    primitive(values) { DataValue.BooleanWrapper(size(it.single()) > 0) }
                }

                RuleUnaryOperation.NON_BLANK -> {
                    primitive(values) { DataValue.BooleanWrapper(!text(it).portableIsBlank()) }
                }

                RuleUnaryOperation.SINGLE_LINE -> {
                    primitive(values) { DataValue.BooleanWrapper(!text(it).hasLineBreak()) }
                }

                RuleUnaryOperation.POSITIVE -> {
                    primitive(values) { DataValue.BooleanWrapper(number(it[0]) > BigDecimal.ZERO) }
                }

                RuleUnaryOperation.NON_NEGATIVE -> {
                    primitive(values) { DataValue.BooleanWrapper(number(it[0]) >= BigDecimal.ZERO) }
                }

                RuleUnaryOperation.UNIQUE -> {
                    primitive(values) {
                        val values = it.single().collectionEntries().map { entry -> entry.value.canonicalValueKey() }
                        DataValue.BooleanWrapper(values.distinct().size == values.size)
                    }
                }

                RuleUnaryOperation.NOT_NULL -> {
                    primitive(values) { DataValue.BooleanWrapper(it.single() != DataValue.NULL) }
                }

                RuleUnaryOperation.OPAQUE -> {
                    primitive(values) {
                        val bits =
                            (it.single().unwrapNamed() as? DataValue.IntegerWrapper)?.bigInteger
                                ?: throw OperationFailure("expected_color", "The color representation is not an integer.")
                        DataValue.BooleanWrapper(bits.shiftRight(24).and(java.math.BigInteger.valueOf(255)).toInt() == 255)
                    }
                }

                else -> {
                    unknownVariant()
                }
            }
        }

        is ExpressionNode.RegexTestWrapper -> {
            when (node.value.mode) {
                RegexMatchMode.SEARCH -> {
                    primitiveWithSteps(values, consumeStep) { values, consumeStep ->
                        DataValue.BooleanWrapper(regex(values).containsMatchIn(text(values[0]), consumeStep))
                    }
                }

                RegexMatchMode.FULL_MATCH -> {
                    primitiveWithSteps(values, consumeStep) { values, consumeStep ->
                        DataValue.BooleanWrapper(regex(values).matches(text(values), consumeStep))
                    }
                }

                else -> {
                    unknownVariant()
                }
            }
        }

        is ExpressionNode.RuleTimestampBoundWrapper -> {
            when (node.value.direction) {
                TimestampBoundDirection.NOT_BEFORE -> primitive(values) { DataValue.BooleanWrapper(timestamp(it[0]) >= timestamp(it[1])) }
                TimestampBoundDirection.NOT_AFTER -> primitive(values) { DataValue.BooleanWrapper(timestamp(it[0]) <= timestamp(it[1])) }
                else -> unknownVariant()
            }
        }

        is ExpressionNode.RuleNumericBoundWrapper -> {
            when (node.value.direction) {
                BoundDirection.MINIMUM -> {
                    primitive(values) {
                        DataValue.BooleanWrapper(if (it[2].boolean()) compareNumbers(it) >= 0 else compareNumbers(it) > 0)
                    }
                }

                BoundDirection.MAXIMUM -> {
                    primitive(values) {
                        DataValue.BooleanWrapper(if (it[2].boolean()) compareNumbers(it) <= 0 else compareNumbers(it) < 0)
                    }
                }

                else -> {
                    unknownVariant()
                }
            }
        }

        is ExpressionNode.TextLengthWrapper -> {
            primitive(values) { DataValue.integer(text(it).codePointCount().toBigInteger()) }
        }

        is ExpressionNode.TextHasLineBreakWrapper -> {
            primitive(values) { DataValue.BooleanWrapper(text(it).hasLineBreak()) }
        }

        is ExpressionNode.TextReplaceWrapper -> {
            primitiveWithBudgets(values, consumeStep, consumeItems) { values, consumeStep, _ ->
                val source = text(values[0])
                val target = text(values[1])
                val replacement = text(values[2])
                chargeLiteralReplacement(source, target, replacement, consumeStep)
                DataValue.StringValueWrapper(
                    if (target.isEmpty()) {
                        replaceBetweenCodePoints(source, replacement)
                    } else {
                        source.replace(target, replacement)
                    },
                )
            }
        }

        is ExpressionNode.TextSplitWrapper -> {
            primitiveWithBudgets(values, consumeStep, consumeItems) { values, _, consumeItems ->
                val source = text(values[0])
                val separator = text(values[1])
                consumeItems(literalSplitItemCount(source, separator))
                val parts = if (separator.isEmpty()) source.splitIntoCodePoints() else source.split(separator)
                DataValue.listValue(
                    parts.mapIndexed { index, value ->
                        ListItem(
                            id =
                                skirout.editor.v1.type_catalog
                                    .ItemId(value = "split.$index"),
                            value = DataValue.StringValueWrapper(value),
                        )
                    },
                )
            }
        }

        is ExpressionNode.TextJoinWrapper -> {
            primitiveWithBudgets(values, consumeStep, consumeItems) { arguments, consumeStep, _ ->
                val values = arguments[0].collectionEntries().map { entry -> text(entry.value) }
                val separator = text(arguments[1])
                values.forEachIndexed { index, value ->
                    if (index > 0) chargeCodePoints(separator, consumeStep)
                    chargeCodePoints(value, consumeStep)
                }
                DataValue.StringValueWrapper(values.joinToString(separator))
            }
        }

        is ExpressionNode.TextSubstringWrapper -> {
            primitive(values) { substring(it) }
        }

        is ExpressionNode.RegexCaptureWrapper -> {
            primitiveWithSteps(values, consumeStep) { values, consumeStep ->
                val group = integer(values[2])
                require(group in 0..32) { "Regular expression capture group is out of range." }
                val input = text(values[0])
                val match =
                    regex(values).find(input, consumeStep)
                        ?: throw OperationFailure("regex_no_match", "The regular expression did not match.")
                DataValue.StringValueWrapper(
                    match.group(input, group)
                        ?: throw OperationFailure("regex_group_absent", "The regular expression capture group is absent."),
                )
            }
        }

        is ExpressionNode.RegexReplaceWrapper -> {
            primitiveWithSteps(values, consumeStep) { values, consumeStep ->
                val pattern = regex(values)
                try {
                    DataValue.StringValueWrapper(pattern.replace(text(values[0]), text(values[2]), consumeStep))
                } catch (_: PortableRegexCompileFailure) {
                    throw OperationFailure("invalid_regex_replacement", "The regular expression replacement is invalid.")
                }
            }
        }

        is ExpressionNode.IsNullWrapper -> {
            primitive(values) { DataValue.BooleanWrapper(it.single() == DataValue.NULL) }
        }

        is ExpressionNode.LinkTargetWrapper -> {
            primitive(values) {
                val link =
                    it.single().unwrapNamed() as? DataValue.LinkWrapper
                        ?: throw OperationFailure("expected_link", "The expression value is not a relationship link.")
                DataValue.named(
                    com.typewritermc.types.ResourceIdDefinition.use,
                    DataValue.StringValueWrapper(link.value.target.resource.value),
                )
            }
        }

        is ExpressionNode.BooleanNotWrapper -> {
            primitive(values) { DataValue.BooleanWrapper(!it.single().boolean()) }
        }

        is ExpressionNode.NumberNegateWrapper -> {
            primitive(values) { arithmetic(it, Arithmetic.Negate) }
        }

        is ExpressionNode.NumberRoundWrapper -> {
            primitive(values) { roundPortableNumber(it) }
        }

        is ExpressionNode.NumberFormatWrapper -> {
            primitiveWithBudgets(values, consumeStep, consumeItems) { values, consumeStep, _ ->
                formatPortableNumber(values).also { result ->
                    chargeCodePoints((result as DataValue.StringValueWrapper).value, consumeStep)
                }
            }
        }

        is ExpressionNode.DurationFormatWrapper -> {
            primitiveWithBudgets(values, consumeStep, consumeItems) { values, consumeStep, _ ->
                formatPortableDuration(values).also { result ->
                    chargeCodePoints((result as DataValue.StringValueWrapper).value, consumeStep)
                }
            }
        }

        is ExpressionNode.TimestampFormatWrapper -> {
            primitiveWithBudgets(values, consumeStep, consumeItems) { values, consumeStep, _ ->
                formatPortableTimestamp(values).also { result ->
                    chargeCodePoints((result as DataValue.StringValueWrapper).value, consumeStep)
                }
            }
        }

        is ExpressionNode.CollectionSizeWrapper -> {
            primitive(values) { DataValue.integer(size(it.single()).toBigInteger()) }
        }

        is ExpressionNode.CollectionAccessWrapper -> {
            primitive(values) { collectionAccess(it) }
        }

        is ExpressionNode.CollectionContainsWrapper -> {
            primitive(values) { collectionContains(it) }
        }

        is ExpressionNode.ColorWithAlphaWrapper -> {
            primitive(values) { colorWithAlpha(it) }
        }

        is ExpressionNode.RuleOneOfWrapper -> {
            primitive(values) { values ->
                DataValue.BooleanWrapper(
                    values.drop(1).any { it.canonicalValueKey() == values[0].canonicalValueKey() },
                )
            }
        }

        is ExpressionNode.RuleNumericRangeWrapper -> {
            primitive(values) {
                DataValue.BooleanWrapper(number(it[0]) >= number(it[1]) && number(it[0]) <= number(it[2]))
            }
        }

        is ExpressionNode.RuleMultipleOfWrapper -> {
            primitive(values) {
                val divisor = number(it[1])
                DataValue.BooleanWrapper(
                    divisor.compareTo(BigDecimal.ZERO) != 0 && number(it[0]).remainder(divisor).compareTo(BigDecimal.ZERO) == 0,
                )
            }
        }

        is ExpressionNode.RuleMaximumScaleWrapper -> {
            primitive(values) {
                DataValue.BooleanWrapper(number(it[0]).stripTrailingZeros().scale() <= integer(it[1]))
            }
        }

        is ExpressionNode.TextInterpolateWrapper -> {
            values.map(DataValue::displayText).let { rendered ->
                rendered.forEach { chargeCodePoints(it, consumeStep) }
                DataValue.StringValueWrapper(rendered.joinToString(""))
            }
        }

        is ExpressionNode.RuleSizeBoundWrapper -> {
            run {
                val measured =
                    when (node.value.metric) {
                        SizeBoundMetric.TEXT_LENGTH, SizeBoundMetric.COLLECTION_ITEMS -> size(values[0])
                        SizeBoundMetric.TEXT_LINES -> lineCount(text(values[0]))
                        else -> unknownVariant()
                    }
                DataValue.BooleanWrapper(
                    when (node.value.direction) {
                        BoundDirection.MINIMUM -> measured >= integer(values[1])
                        BoundDirection.MAXIMUM -> measured <= integer(values[1])
                        else -> unknownVariant()
                    },
                )
            }
        }

        is ExpressionNode.RuleSizeRangeWrapper -> {
            run {
                when (node.value.metric) {
                    SizeRangeMetric.TEXT_LENGTH, SizeRangeMetric.COLLECTION_ITEMS -> Unit
                    else -> unknownVariant()
                }
                DataValue.BooleanWrapper(size(values[0]) in integer(values[1])..integer(values[2]))
            }
        }

        else -> {
            unknownVariant()
        }
    }

private fun unknownVariant(): Nothing = throw OperationFailure("unknown_expression_operation", "Unknown expression operator.")

private fun primitive(
    values: List<DataValue>,
    body: (List<DataValue>) -> DataValue,
): DataValue = body(values)

private fun primitiveWithSteps(
    values: List<DataValue>,
    consumeStep: () -> Unit,
    body: (List<DataValue>, () -> Unit) -> DataValue,
): DataValue = body(values, consumeStep)

private fun primitiveWithBudgets(
    values: List<DataValue>,
    consumeStep: () -> Unit,
    consumeItems: (Int) -> Unit,
    body: (List<DataValue>, () -> Unit, (Int) -> Unit) -> DataValue,
): DataValue = body(values, consumeStep, consumeItems)

private fun compareNumbers(values: List<DataValue>): Int = number(values[0]).compareTo(number(values[1]))

private enum class Arithmetic { Add, Subtract, Multiply, Divide, Remainder, Negate }

private fun arithmetic(
    values: List<DataValue>,
    operation: Arithmetic,
): DataValue {
    val unwrapped = values.map(DataValue::unwrapNamed)
    if (operation == Arithmetic.Negate) {
        return when (val value = unwrapped.single()) {
            is DataValue.IntegerWrapper -> {
                DataValue.integer(value.bigInteger.negate())
            }

            is DataValue.FloatWrapper -> {
                DataValue.FloatWrapper(finite(-value.value))
            }

            is DataValue.DecimalWrapper -> {
                DataValue.DecimalWrapper(
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
    if (unwrapped.all { it is DataValue.IntegerWrapper }) {
        var result = (unwrapped.first() as DataValue.IntegerWrapper).bigInteger
        unwrapped.drop(1).map { (it as DataValue.IntegerWrapper).bigInteger }.forEach { operand ->
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
        return DataValue.integer(result)
    }
    if (unwrapped.all { it is DataValue.FloatWrapper }) {
        var result = (unwrapped.first() as DataValue.FloatWrapper).value
        unwrapped.drop(1).map { (it as DataValue.FloatWrapper).value }.forEach { operand ->
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
        return DataValue.FloatWrapper(result)
    }
    if (unwrapped.all { it is DataValue.DecimalWrapper }) {
        var result = (unwrapped.first() as DataValue.DecimalWrapper).value.toBigDecimal()
        unwrapped.drop(1).map { (it as DataValue.DecimalWrapper).value.toBigDecimal() }.forEach { operand ->
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
        return DataValue.DecimalWrapper(result.canonicalString())
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
    return DataValue.StringValueWrapper(source.substring(startIndex, endIndex))
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
        collection is DataValue.ListValueWrapper && key is DataValue.IntegerWrapper -> {
            collection.items.getOrNull(key.bigInteger.intValueExact())?.value
        }

        collection is DataValue.MapValueWrapper -> {
            collection.rows.firstOrNull { it.key.canonicalValueKey() == key.canonicalValueKey() }?.value
        }

        collection is DataValue.RecordWrapper && key is DataValue.StringValueWrapper -> {
            collection.field(key.value)
        }

        collection is DataValue.StringValueWrapper && key is DataValue.IntegerWrapper -> {
            val index = key.bigInteger.intValueExact()
            collection.value
                .getOrNull(index)
                ?.toString()
                ?.let(DataValue::StringValueWrapper)
        }

        else -> {
            null
        }
    } ?: throw OperationFailure("collection_key_absent", "The collection key or index is absent.")
}

private fun collectionContains(values: List<DataValue>): DataValue.BooleanWrapper {
    val collection = values[0].unwrapNamed()
    val expected = values[1].unwrapNamed()
    val key = expected.canonicalValueKey()
    val contains =
        when (collection) {
            is DataValue.ListValueWrapper -> collection.items.any { it.value.canonicalValueKey() == key }
            is DataValue.SetValueWrapper -> collection.items.any { it.value.canonicalValueKey() == key }
            is DataValue.MapValueWrapper -> collection.rows.any { it.key.canonicalValueKey() == key }
            is DataValue.RecordWrapper -> (expected as? DataValue.StringValueWrapper)?.value?.let(collection::field) != null
            else -> throw OperationFailure("expected_collection", "The expression value is not a collection.")
        }
    return DataValue.BooleanWrapper(contains)
}

private fun colorWithAlpha(values: List<DataValue>): DataValue {
    val original = values[0]
    val color =
        (original.unwrapNamed() as? DataValue.IntegerWrapper)?.bigInteger
            ?: throw OperationFailure("expected_color", "The color representation is not an integer.")
    val alpha = integer(values[1])
    if (alpha !in 0..255) throw OperationFailure("color_alpha_range", "Color alpha must be between zero and 255.")
    val replaced =
        color.and(java.math.BigInteger.valueOf(0x00ffffff)).or(
            java.math.BigInteger
                .valueOf(alpha.toLong())
                .shiftLeft(24),
        )
    val payload = DataValue.integer(replaced)
    return if (original is DataValue.NamedWrapper) DataValue.named(original.actualType, payload) else payload
}

private fun DataValue.displayText(): String =
    when (val value = unwrapNamed()) {
        DataValue.UNFILLED, DataValue.NULL, DataValue.UNIT -> ""
        is DataValue.BooleanWrapper -> value.value.toString()
        is DataValue.IntegerWrapper -> value.value.toString()
        is DataValue.FloatWrapper -> value.value.toString()
        is DataValue.DecimalWrapper -> value.value
        is DataValue.StringValueWrapper -> value.value
        is DataValue.BytesWrapper -> "${value.value.size} bytes"
        is DataValue.TimestampWrapper -> value.instant.toString()
        is DataValue.DurationWrapper -> value.duration.toString()
        is DataValue.EnumCaseWrapper -> value.value
        is DataValue.ListValueWrapper -> "${value.items.size} items"
        is DataValue.SetValueWrapper -> "${value.items.size} items"
        is DataValue.MapValueWrapper -> "${value.rows.size} entries"
        is DataValue.RecordWrapper -> "record"
        is DataValue.LinkWrapper -> value.linkTarget.toString()
        is DataValue.NamedWrapper -> error("Named values are unwrapped recursively.")
        else -> unknownVariant(value)
    }

private fun String.titleCase(): String =
    split(Regex("(\\s+)"))
        .joinToString(" ") { word -> word.lowercase().replaceFirstChar { character -> character.titlecase() } }

private fun number(value: DataValue): BigDecimal =
    when (val scalar = value.unwrapNamed()) {
        is DataValue.IntegerWrapper -> scalar.value.toBigDecimal()
        is DataValue.FloatWrapper -> BigDecimal.valueOf(scalar.value)
        is DataValue.DecimalWrapper -> scalar.value.toBigDecimal()
        else -> throw OperationFailure("expected_number", "The expression value is not numeric.")
    }

private fun integer(value: DataValue): Int =
    (value.unwrapNamed() as? DataValue.IntegerWrapper)?.bigInteger?.intValueExact()
        ?: throw OperationFailure("expected_integer", "The expression value is not an integer.")

private fun text(values: List<DataValue>): String = text(values.first())

private fun text(value: DataValue): String =
    (value.unwrapNamed() as? DataValue.StringValueWrapper)?.value
        ?: throw OperationFailure("expected_text", "The expression value is not text.")

private fun timestamp(value: DataValue): kotlin.time.Instant =
    (value.unwrapNamed() as? DataValue.TimestampWrapper)?.instant
        ?: throw OperationFailure("expected_timestamp", "The expression value is not a timestamp.")

private fun size(value: DataValue): Int =
    when (val unwrapped = value.unwrapNamed()) {
        is DataValue.StringValueWrapper -> unwrapped.value.codePointCount()
        is DataValue.BytesWrapper -> unwrapped.value.size
        is DataValue.ListValueWrapper -> unwrapped.items.size
        is DataValue.SetValueWrapper -> unwrapped.items.size
        is DataValue.MapValueWrapper -> unwrapped.rows.size
        is DataValue.RecordWrapper -> unwrapped.fields.size
        else -> throw OperationFailure("expected_sized_value", "The expression value has no size.")
    }

private fun String.codePointCount(): Int = codePointCount(0, length)

private fun String.portableTrim(): String = trim { character -> character.code in PORTABLE_WHITESPACE }

private fun String.portableIsBlank(): Boolean = all { character -> character.code in PORTABLE_WHITESPACE }

private fun String.hasLineBreak(): Boolean = any { it == '\n' || it == '\r' || it == '\u2028' || it == '\u2029' }

private fun DataValue.containsUnfilled(): Boolean =
    when (this) {
        DataValue.UNFILLED -> true
        is DataValue.NamedWrapper -> payload.containsUnfilled()
        is DataValue.RecordWrapper -> fields.any { it.value.containsUnfilled() }
        is DataValue.ListValueWrapper -> items.any { it.value.containsUnfilled() }
        is DataValue.SetValueWrapper -> items.any { it.value.containsUnfilled() }
        is DataValue.MapValueWrapper -> rows.any { it.key.containsUnfilled() || it.value.containsUnfilled() }
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

private fun EntryBranch.pathSegment(): PathSegment =
    when (this) {
        EntryBranch.KEY -> PathSegment.MapKey
        EntryBranch.VALUE -> PathSegment.MapValue
        else -> throw OperationFailure("unknown_expression_variant", "Unknown entry branch.")
    }

private fun decodeLiteral(value: DataValue): DataValue =
    try {
        value.requirePortable()
    } catch (invalid: IllegalArgumentException) {
        // Retain specific numeric budget failures without admitting malformed scalar payloads.
        when (value) {
            is DataValue.FloatWrapper -> value.displayDecimal()
            is DataValue.DecimalWrapper -> value.displayDecimal()
            else -> Unit
        }
        throw OperationFailure("invalid_expression_literal", invalid.message ?: "The expression literal is not portable.")
    }
