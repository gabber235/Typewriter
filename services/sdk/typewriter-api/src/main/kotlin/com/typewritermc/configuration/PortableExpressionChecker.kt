package com.typewritermc.configuration

import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.ValuePath
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.expression.OperationId
import com.typewritermc.expression.PortableOperationRegistry
import com.typewritermc.expression.PortableOperationSemantics
import com.typewritermc.presentation.ExpressionNode
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.DataValue
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.DeclarationDiagnostic
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.ResolvedRepresentation
import com.typewritermc.types.catalog.resolve
import java.math.BigDecimal

/** A checked portable expression keeps its authored tree and required result contract. */
data class CheckedExpression(val body: ExpressionNode, val result: com.typewritermc.expression.ExpressionType)

/** Checks the same expression language for rules and value mappings under explicit lexical bindings. */
class PortableExpressionChecker(
    private val resolveType: (TypeUse) -> Resolution<CheckedType>,
    private val owner: TypeDefinitionId? = null,
    private val operations: PortableOperationRegistry = PortableOperationRegistry.Standard,
) {
    fun checkExpression(
        body: ExpressionNode,
        bindings: Map<ExpressionBindingId, com.typewritermc.expression.ExpressionType>,
        expectedOutput: com.typewritermc.expression.ExpressionType,
        affected: TypeDefinitionId,
    ): Resolution<CheckedExpression> {
        val codes = checkExpressionCodes(body, bindings, expectedOutput)
        return if (codes.isEmpty()) Resolution.Ready(CheckedExpression(body, expectedOutput)) else Resolution.Invalid(codes.map { DeclarationDiagnostic(affected, it) })
    }

    fun checkExpressionStructure(body: ExpressionNode, bindings: Set<ExpressionBindingId>): List<String> {
        val diagnostics = mutableListOf<String>()
        validateSymbols(body, bindings.toMutableSet(), owner, diagnostics)
        return diagnostics.distinct()
    }

    /** Allows presentation builders to report errors without inventing a catalog type identity. */
    fun checkExpressionCodes(
        body: ExpressionNode,
        bindings: Map<ExpressionBindingId, com.typewritermc.expression.ExpressionType>,
        expectedOutput: com.typewritermc.expression.ExpressionType,
    ): List<String> {
        val diagnostics = mutableListOf<String>()
        validateSymbols(body, bindings.keys.toMutableSet(), owner, diagnostics)
        val locals = bindings.mapValues { (_, type) -> resolveType(type.value).toInferredType() }.toMutableMap()
        val inferred = validate(body, locals, owner, diagnostics)
        val expected = resolveType(expectedOutput.value).toInferredType()
        compatible(inferred, expected, owner, diagnostics)
        if (!expectedOutput.mayBeMissing && body.mayBeMissing(bindings)) diagnostics += diagnostic(owner, "expression_result_may_be_missing")
        if (inferred.kind == InferredKind.Invalid && diagnostics.isEmpty()) diagnostics += "expression_type_inference_failed"
        if (expected.kind == InferredKind.Invalid) diagnostics += "invalid_expression_result_type"
        return diagnostics.distinct()
    }

    internal fun checkRule(body: ExpressionNode, subject: CheckedType): List<DeclarationDiagnostic> {
        val diagnostics = mutableListOf<String>()
        val id = ExpressionBindingId("configured_value")
        validateSymbols(body, mutableSetOf(id), owner, diagnostics)
        val result = validate(body, mutableMapOf(id to InferredType.Value(subject)), owner, diagnostics)
        if (result.kind == InferredKind.Invalid && diagnostics.isEmpty()) diagnostics += diagnostic(owner, "rule_type_inference_failed")
        if (result.kind != InferredKind.Boolean && result.kind != InferredKind.Invalid) diagnostics += diagnostic(owner, "rule_predicate_must_be_boolean")
        return diagnostics.distinct().map { DeclarationDiagnostic(requireNotNull(owner), it) }
    }

    internal fun checkRuleStructure(body: ExpressionNode): List<DeclarationDiagnostic> {
        val diagnostics = mutableListOf<String>()
        validateSymbols(body, mutableSetOf(ExpressionBindingId("configured_value")), owner, diagnostics)
        return diagnostics.distinct().map { DeclarationDiagnostic(requireNotNull(owner), it) }
    }

    private fun validateSymbols(
        expression: ExpressionNode,
        localBindings: MutableSet<ExpressionBindingId>,
        owner: TypeDefinitionId?,
        diagnostics: MutableList<String>,
    ) {
        when (expression) {
            is ExpressionNode.Literal -> {}

            is ExpressionNode.Read -> {
                if (expression.binding !in localBindings) {
                    diagnostics += diagnostic(owner, "unknown_rule_binding")
                }
            }

            is ExpressionNode.Call -> {
                val semantics = operations.semantics(expression.operation)
                if (semantics == null) {
                    diagnostics += diagnostic(owner, "unknown_rule_operation")
                } else if (expression.arguments.size !in semantics.minimumArguments..semantics.maximumArguments) {
                    diagnostics += diagnostic(owner, "invalid_rule_operation_arity")
                }
                expression.arguments.forEach { validateSymbols(it, localBindings, owner, diagnostics) }
            }

            is ExpressionNode.And -> {
                validateSymbols(expression.left, localBindings, owner, diagnostics)
                validateSymbols(expression.right, localBindings, owner, diagnostics)
            }

            is ExpressionNode.Or -> {
                validateSymbols(expression.left, localBindings, owner, diagnostics)
                validateSymbols(expression.right, localBindings, owner, diagnostics)
            }

            is ExpressionNode.Conditional -> {
                validateSymbols(expression.test, localBindings, owner, diagnostics)
                validateSymbols(expression.yes, localBindings, owner, diagnostics)
                validateSymbols(expression.no, localBindings, owner, diagnostics)
            }

            is ExpressionNode.OrElse -> {
                validateSymbols(expression.input, localBindings, owner, diagnostics)
                validateSymbols(expression.fallback, localBindings, owner, diagnostics)
            }

            is ExpressionNode.Collection -> {
                val shape = COLLECTION_OPERATIONS[expression.operation]
                if (shape == null) {
                    diagnostics += diagnostic(owner, "unknown_collection_rule_operation")
                } else {
                    if (expression.bindings.size != shape.bindings || expression.arguments.size !in shape.arguments) {
                        diagnostics += diagnostic(owner, "invalid_collection_rule_operation_arity")
                    }
                    if ((shape.bodyRequired && expression.body == null) || (!shape.bodyAllowed && expression.body != null)) {
                        diagnostics += diagnostic(owner, "invalid_collection_rule_operation_body")
                    }
                }
                validateSymbols(expression.input, localBindings, owner, diagnostics)
                expression.arguments.forEach { validateSymbols(it, localBindings, owner, diagnostics) }
                if (expression.bindings.distinct().size != expression.bindings.size || expression.bindings.any(localBindings::contains)) {
                    diagnostics += diagnostic(owner, "duplicate_collection_rule_binding")
                }
                localBindings += expression.bindings
                expression.body?.let { validateSymbols(it, localBindings, owner, diagnostics) }
                localBindings -= expression.bindings.toSet()
            }
        }
    }

    private fun validate(
        expression: ExpressionNode,
        localBindings: MutableMap<ExpressionBindingId, InferredType>,
        owner: TypeDefinitionId?,
        diagnostics: MutableList<String>,
    ): InferredType =
        when (expression) {
            is ExpressionNode.Literal -> {
                expression.value.expressionType(resolveType)
            }

            is ExpressionNode.Read -> {
                val base = localBindings[expression.binding]
                if (base == null) {
                    InferredType.Invalid
                } else {
                    base.at(expression.path, owner, diagnostics)
                }
            }

            is ExpressionNode.Call -> {
                val arguments = expression.arguments.map { validate(it, localBindings, owner, diagnostics) }
                validateCall(expression.operation, arguments, owner, diagnostics)
            }

            is ExpressionNode.And -> {
                requireBoolean(validate(expression.left, localBindings, owner, diagnostics), owner, diagnostics)
                requireBoolean(validate(expression.right, localBindings, owner, diagnostics), owner, diagnostics)
                InferredType.Boolean
            }

            is ExpressionNode.Or -> {
                requireBoolean(validate(expression.left, localBindings, owner, diagnostics), owner, diagnostics)
                requireBoolean(validate(expression.right, localBindings, owner, diagnostics), owner, diagnostics)
                InferredType.Boolean
            }

            is ExpressionNode.Conditional -> {
                requireBoolean(validate(expression.test, localBindings, owner, diagnostics), owner, diagnostics)
                val yes = validate(expression.yes, localBindings, owner, diagnostics)
                val no = validate(expression.no, localBindings, owner, diagnostics)
                compatible(yes, no, owner, diagnostics)
            }

            is ExpressionNode.OrElse -> {
                val input = validate(expression.input, localBindings, owner, diagnostics)
                val fallback = validate(expression.fallback, localBindings, owner, diagnostics)
                compatible(input, fallback, owner, diagnostics)
            }

            is ExpressionNode.Collection -> {
                val input = validate(expression.input, localBindings, owner, diagnostics)
                val item = input.collectionItem(owner, diagnostics)
                val arguments = expression.arguments.map { validate(it, localBindings, owner, diagnostics) }
                val bindingTypes = collectionBindingTypes(expression.operation, item, arguments, owner, diagnostics)
                expression.bindings.zip(bindingTypes).forEach { (binding, type) -> localBindings[binding] = type }
                val body = expression.body?.let { validate(it, localBindings, owner, diagnostics) }
                expression.bindings.forEach(localBindings::remove)
                when (expression.operation.value) {
                    "typewriter.collection.any", "typewriter.collection.all", "typewriter.collection.none" -> {
                        requireBoolean(body ?: missingCollectionBody(owner, diagnostics), owner, diagnostics)
                        InferredType.Boolean
                    }

                    "typewriter.collection.filter" -> {
                        requireBoolean(body ?: missingCollectionBody(owner, diagnostics), owner, diagnostics)
                        input
                    }

                    "typewriter.collection.find", "typewriter.collection.find_last" -> {
                        requireBoolean(body ?: missingCollectionBody(owner, diagnostics), owner, diagnostics)
                        item
                    }

                    "typewriter.collection.count" -> {
                        requireBoolean(body ?: missingCollectionBody(owner, diagnostics), owner, diagnostics)
                        InferredType.Integer
                    }

                    "typewriter.collection.unique_by" -> {
                        InferredType.Boolean
                    }

                    "typewriter.collection.map" -> {
                        InferredType.Collection(body ?: missingCollectionBody(owner, diagnostics))
                    }

                    "typewriter.collection.flat_map" -> {
                        val nested = body ?: missingCollectionBody(owner, diagnostics)
                        if (nested is InferredType.Collection) InferredType.Collection(nested.item) else InferredType.Invalid
                    }

                    "typewriter.collection.distinct_by", "typewriter.collection.sort_by",
                    "typewriter.collection.take", "typewriter.collection.skip", "typewriter.collection.reverse",
                    "typewriter.collection.distinct",
                    -> {
                        input
                    }

                    "typewriter.collection.sort_with" -> {
                        val comparison = body ?: missingCollectionBody(owner, diagnostics)
                        if (comparison.kind !in setOf(InferredKind.Integer, InferredKind.Number, InferredKind.Invalid)) {
                            diagnostics += diagnostic(owner, "invalid_collection_comparator_type")
                        }
                        input
                    }

                    "typewriter.collection.group_by" -> {
                        InferredType.Collection(
                            InferredType.MapEntry(
                                body ?: missingCollectionBody(owner, diagnostics),
                                InferredType.Collection(item),
                            ),
                        )
                    }

                    "typewriter.collection.reduce" -> {
                        compatible(item, body ?: missingCollectionBody(owner, diagnostics), owner, diagnostics)
                    }

                    "typewriter.collection.fold" -> {
                        val initial = arguments.singleOrNull() ?: InferredType.Invalid
                        compatible(initial, body ?: missingCollectionBody(owner, diagnostics), owner, diagnostics)
                    }

                    else -> {
                        InferredType.Invalid
                    }
                }
            }
        }

    private fun collectionBindingTypes(
        operation: OperationId,
        item: InferredType,
        arguments: List<InferredType>,
        owner: TypeDefinitionId?,
        diagnostics: MutableList<String>,
    ): List<InferredType> {
        val shape = COLLECTION_OPERATIONS[operation]
        if (shape == null) return emptyList()
        if (operation.value in setOf("typewriter.collection.take", "typewriter.collection.skip")) {
            val count = arguments.singleOrNull()
            if (count?.kind != InferredKind.Integer) diagnostics += diagnostic(owner, "invalid_collection_argument_type")
        }
        if (operation.value == "typewriter.collection.sort_by" && arguments.singleOrNull()?.kind !in setOf(null, InferredKind.Boolean)) {
            diagnostics += diagnostic(owner, "invalid_collection_argument_type")
        }
        return when (operation.value) {
            "typewriter.collection.fold" -> listOf(arguments.singleOrNull() ?: InferredType.Invalid, item)
            "typewriter.collection.reduce", "typewriter.collection.sort_with" -> listOf(item, item)
            else -> List(shape.bindings) { item }
        }
    }

    private fun missingCollectionBody(
        owner: TypeDefinitionId?,
        diagnostics: MutableList<String>,
    ): InferredType {
        diagnostics += diagnostic(owner, "missing_collection_rule_body")
        return InferredType.Invalid
    }

    private fun validateCall(
        operation: OperationId,
        arguments: List<InferredType>,
        owner: TypeDefinitionId?,
        diagnostics: MutableList<String>,
    ): InferredType {
        if (operation.value in com.typewritermc.expression.SharedOperationSignatures.supportedIds) {
            val uses = arguments.map { it.scalarUse() }
            if (uses.all { it != null } && com.typewritermc.expression.SharedOperationSignatures.resolveOrNull(operation, uses.map { com.typewritermc.expression.ExpressionType(requireNotNull(it), false) }) == null) {
                diagnostics += "invalid_expression_operand_type"
            }
        }
        val expectation = OPERATION_TYPES[operation.value]
        if (expectation == null) {
            diagnostics += diagnostic(owner, "unsupported_rule_operation_type")
            return InferredType.Invalid
        }
        arguments.forEachIndexed { index, argument ->
            val expected = expectation.inputs.getOrNull(index) ?: expectation.repeated ?: InferredKind.Any
            if (!expected.accepts(argument.kind)) diagnostics += diagnostic(owner, "invalid_rule_operand_type")
        }
        if (operation.value in EQUALITY_OPERATIONS && arguments.isNotEmpty()) {
            arguments.drop(1).fold(arguments.first()) { current, next -> compatible(current, next, owner, diagnostics) }
        }
        if (operation.value == "typewriter.number.round_to" && arguments.size >= 2) compatible(arguments[0], arguments[1], owner, diagnostics)
        if (operation.value in NUMERIC_FAMILY_OPERATIONS && arguments.isNotEmpty()) {
            arguments.drop(1).fold(arguments.first()) { current, next -> compatible(current, next, owner, diagnostics) }
        }
        return if (operation.value in NUMERIC_FAMILY_OPERATIONS || operation.value in setOf("typewriter.number.negate", "typewriter.number.round_to")) {
            arguments.firstOrNull() ?: InferredType.Invalid
        } else expressionType(expectation.output)
    }

    private fun requireBoolean(
        type: InferredType,
        owner: TypeDefinitionId?,
        diagnostics: MutableList<String>,
    ) {
        if (type.kind !in setOf(InferredKind.Boolean, InferredKind.Invalid)) {
            diagnostics += diagnostic(owner, "invalid_boolean_operand")
        }
    }

    private fun compatible(
        first: InferredType,
        second: InferredType,
        owner: TypeDefinitionId?,
        diagnostics: MutableList<String>,
    ): InferredType {
        if (first.kind == InferredKind.Invalid || second.kind == InferredKind.Invalid) return InferredType.Invalid
        if (first.kind == InferredKind.Any) return second
        if (second.kind == InferredKind.Any) return first
        val numericLiteralPair = first is InferredType.NumericLiteral || second is InferredType.NumericLiteral
        val sameFamily = first.numericFamily() != null && first.numericFamily() == second.numericFamily()
        if (first.kind != second.kind || (first.use != null && second.use != null && first.use != second.use && !(numericLiteralPair && sameFamily))) {
            diagnostics += diagnostic(owner, "incompatible_rule_operand_types")
            return InferredType.Invalid
        }
        return if (first is InferredType.NumericLiteral && second is InferredType.Value) second else first
    }

    private fun diagnostic(
        owner: TypeDefinitionId?,
        code: String,
    ): String = code
}

private enum class InferredKind {
    Any,
    Boolean,
    Integer,
    Number,
    Text,
    Bytes,
    Collection,
    Sized,
    Timestamp,
    Duration,
    Invalid,
}

private sealed interface InferredType {
    val kind: InferredKind
    val use: TypeUse?
        get() = null

    data class Value(
        val checked: CheckedType,
    ) : InferredType {
        override val kind: InferredKind = checked.expressionKind()
        override val use: TypeUse = checked.use
    }

    data class Collection(
        val item: InferredType,
    ) : InferredType {
        override val kind: InferredKind = InferredKind.Collection
    }

    data class MapEntry(
        val key: InferredType,
        val value: InferredType,
    ) : InferredType {
        override val kind: InferredKind = InferredKind.Any
    }

    data object Any : InferredType {
        override val kind: InferredKind = InferredKind.Any
    }

    data object Boolean : InferredType {
        override val kind: InferredKind = InferredKind.Boolean
    }

    data object Integer : InferredType {
        override val kind: InferredKind = InferredKind.Integer
    }

    data class NumericLiteral(val scalar: ScalarKind) : InferredType {
        override val kind: InferredKind = InferredKind.Number
        override val use: TypeUse = TypeUse.Scalar(scalar)
    }

    data object Number : InferredType {
        override val kind: InferredKind = InferredKind.Number
    }

    data object Text : InferredType {
        override val kind: InferredKind = InferredKind.Text
    }

    data object Bytes : InferredType {
        override val kind: InferredKind = InferredKind.Bytes
    }

    data object Timestamp : InferredType {
        override val kind: InferredKind = InferredKind.Timestamp
    }

    data object Duration : InferredType {
        override val kind: InferredKind = InferredKind.Duration
    }

    data object Invalid : InferredType {
        override val kind: InferredKind = InferredKind.Invalid
    }
}

private fun CheckedType.expressionKind(): InferredKind =
    when (val representation = schema.representation) {
        is ResolvedRepresentation.Scalar -> {
            when (representation.kind) {
                ScalarKind.Boolean -> InferredKind.Boolean
                is ScalarKind.Integer -> InferredKind.Integer
                is ScalarKind.Float, ScalarKind.Decimal -> InferredKind.Number
                ScalarKind.Text -> InferredKind.Text
                ScalarKind.Bytes -> InferredKind.Bytes
                ScalarKind.Timestamp -> InferredKind.Timestamp
                ScalarKind.Duration -> InferredKind.Duration
                else -> InferredKind.Any
            }
        }

        is ResolvedRepresentation.Sequence, is ResolvedRepresentation.Mapping -> {
            InferredKind.Collection
        }

        else -> {
            InferredKind.Any
        }
    }

private fun DataValue.expressionType(resolveType: (TypeUse) -> Resolution<CheckedType>): InferredType =
    when (this) {
        is DataValue.Named -> {
            when (val resolved = resolveType(actualType)) {
                is Resolution.Ready -> InferredType.Value(resolved.value)
                is Resolution.Invalid -> InferredType.Invalid
            }
        }

        is DataValue.Boolean -> {
            InferredType.Boolean
        }

        is DataValue.Integer -> {
            InferredType.Integer
        }

        is DataValue.Float -> InferredType.NumericLiteral(ScalarKind.Float(com.typewritermc.types.FloatWidth.FLOAT_64))
        is DataValue.Decimal -> InferredType.NumericLiteral(ScalarKind.Decimal)

        is DataValue.StringValue -> {
            InferredType.Text
        }

        is DataValue.Bytes -> {
            InferredType.Bytes
        }

        is DataValue.Timestamp -> {
            InferredType.Timestamp
        }
        is DataValue.Duration -> InferredType.Duration

        is DataValue.ListValue, is DataValue.SetValue, is DataValue.MapValue -> {
            InferredType.Collection(InferredType.Any)
        }

        else -> {
            InferredType.Any
        }
    }

private fun InferredType.at(
    path: ValuePath,
    owner: TypeDefinitionId?,
    diagnostics: MutableList<String>,
): InferredType {
    var current = this
    path.segments.forEach { segment ->
        current =
            when (segment) {
                is PathSegment.Field -> {
                    val value = current as? InferredType.Value
                    val field =
                        value
                            ?.checked
                            ?.schema
                            ?.fields
                            ?.singleOrNull { it.key == segment.name }
                    if (value == null || field == null) {
                        diagnostics += "invalid_rule_field_path"
                        InferredType.Invalid
                    } else {
                        value.checked.resolve(field.type).toInferredType()
                    }
                }

                is PathSegment.Item -> {
                    current.collectionItem(owner, diagnostics)
                }

                PathSegment.MapKey -> {
                    (current as? InferredType.MapEntry)?.key ?: run {
                        diagnostics += "invalid_rule_map_path"
                        InferredType.Invalid
                    }
                }

                PathSegment.MapValue -> {
                    (current as? InferredType.MapEntry)?.value ?: run {
                        diagnostics += "invalid_rule_map_path"
                        InferredType.Invalid
                    }
                }
            }
    }
    return current
}

private fun InferredType.collectionItem(
    owner: TypeDefinitionId?,
    diagnostics: MutableList<String>,
): InferredType =
    when (this) {
        is InferredType.Collection -> {
            item
        }

        is InferredType.Value -> {
            when (val representation = checked.schema.representation) {
                is ResolvedRepresentation.Sequence -> {
                    checked.resolve(representation.item).toInferredType()
                }

                is ResolvedRepresentation.Mapping -> {
                    InferredType.MapEntry(
                        checked.resolve(representation.key).toInferredType(),
                        checked.resolve(representation.value).toInferredType(),
                    )
                }

                else -> {
                    diagnostics += "rule_collection_expected"
                    InferredType.Invalid
                }
            }
        }

        else -> {
            diagnostics += "rule_collection_expected"
            InferredType.Invalid
        }
    }

private fun Resolution<CheckedType>.toInferredType(): InferredType =
    when (this) {
        is Resolution.Ready -> InferredType.Value(value)
        is Resolution.Invalid -> InferredType.Invalid
    }

private fun expressionType(kind: InferredKind): InferredType =
    when (kind) {
        InferredKind.Any, InferredKind.Sized -> InferredType.Any
        InferredKind.Boolean -> InferredType.Boolean
        InferredKind.Integer -> InferredType.Integer
        InferredKind.Number -> InferredType.Number
        InferredKind.Text -> InferredType.Text
        InferredKind.Bytes -> InferredType.Bytes
        InferredKind.Collection -> InferredType.Collection(InferredType.Any)
        InferredKind.Timestamp -> InferredType.Timestamp
        InferredKind.Duration -> InferredType.Duration
        InferredKind.Invalid -> InferredType.Invalid
    }

private data class OperationType(
    val inputs: List<InferredKind>,
    val output: InferredKind,
    val repeated: InferredKind? = null,
)

private fun InferredKind.accepts(actual: InferredKind): Boolean =
    actual == InferredKind.Invalid ||
        this == InferredKind.Any ||
        this == actual ||
        (this == InferredKind.Number && actual == InferredKind.Integer) ||
        (this == InferredKind.Sized && actual in setOf(InferredKind.Text, InferredKind.Bytes, InferredKind.Collection))

private val EQUALITY_OPERATIONS = setOf("typewriter.value.eq", "typewriter.value.neq", "typewriter.rule.one_of")
private val NUMERIC_FAMILY_OPERATIONS =
    setOf(
        "typewriter.number.add",
        "typewriter.number.subtract",
        "typewriter.number.multiply",
        "typewriter.number.divide",
        "typewriter.number.remainder",
    )

private val OPERATION_TYPES =
    mapOf(
        "typewriter.value.eq" to OperationType(listOf(InferredKind.Any, InferredKind.Any), InferredKind.Boolean),
        "typewriter.value.neq" to OperationType(listOf(InferredKind.Any, InferredKind.Any), InferredKind.Boolean),
        "typewriter.value.is_null" to OperationType(listOf(InferredKind.Any), InferredKind.Boolean),
        "typewriter.link.target" to OperationType(listOf(InferredKind.Any), InferredKind.Text),
        "typewriter.record.field" to OperationType(listOf(InferredKind.Any, InferredKind.Text), InferredKind.Any),
        "typewriter.boolean.not" to OperationType(listOf(InferredKind.Boolean), InferredKind.Boolean),
        "typewriter.number.gt" to OperationType(listOf(InferredKind.Number, InferredKind.Number), InferredKind.Boolean),
        "typewriter.number.gte" to OperationType(listOf(InferredKind.Number, InferredKind.Number), InferredKind.Boolean),
        "typewriter.number.lt" to OperationType(listOf(InferredKind.Number, InferredKind.Number), InferredKind.Boolean),
        "typewriter.number.lte" to OperationType(listOf(InferredKind.Number, InferredKind.Number), InferredKind.Boolean),
        "typewriter.number.add" to OperationType(listOf(InferredKind.Number), InferredKind.Number, InferredKind.Number),
        "typewriter.number.subtract" to OperationType(listOf(InferredKind.Number), InferredKind.Number, InferredKind.Number),
        "typewriter.number.multiply" to OperationType(listOf(InferredKind.Number), InferredKind.Number, InferredKind.Number),
        "typewriter.number.divide" to OperationType(listOf(InferredKind.Number), InferredKind.Number, InferredKind.Number),
        "typewriter.number.remainder" to OperationType(listOf(InferredKind.Number), InferredKind.Number, InferredKind.Number),
        "typewriter.number.negate" to OperationType(listOf(InferredKind.Number), InferredKind.Number),
        "typewriter.number.round_to" to OperationType(listOf(InferredKind.Number, InferredKind.Number, InferredKind.Text), InferredKind.Number),
        "typewriter.number.format" to OperationType(listOf(InferredKind.Number, InferredKind.Integer, InferredKind.Text), InferredKind.Text),
        "typewriter.duration.format" to OperationType(listOf(InferredKind.Duration, InferredKind.Text, InferredKind.Integer), InferredKind.Text),
        "typewriter.timestamp.format" to OperationType(listOf(InferredKind.Timestamp, InferredKind.Text, InferredKind.Text, InferredKind.Text), InferredKind.Text),
        "typewriter.text.length" to OperationType(listOf(InferredKind.Text), InferredKind.Integer),
        "typewriter.text.has_line_break" to OperationType(listOf(InferredKind.Text), InferredKind.Boolean),
        "typewriter.text.trim" to OperationType(listOf(InferredKind.Text), InferredKind.Text),
        "typewriter.text.lower" to OperationType(listOf(InferredKind.Text), InferredKind.Text),
        "typewriter.text.upper" to OperationType(listOf(InferredKind.Text), InferredKind.Text),
        "typewriter.text.title" to OperationType(listOf(InferredKind.Text), InferredKind.Text),
        "typewriter.text.replace" to
            OperationType(listOf(InferredKind.Text, InferredKind.Text, InferredKind.Text), InferredKind.Text),
        "typewriter.text.split" to OperationType(listOf(InferredKind.Text, InferredKind.Text), InferredKind.Collection),
        "typewriter.text.join" to OperationType(listOf(InferredKind.Collection, InferredKind.Text), InferredKind.Text),
        "typewriter.text.substring" to
            OperationType(listOf(InferredKind.Text, InferredKind.Integer), InferredKind.Text, InferredKind.Integer),
        "typewriter.text.contains" to OperationType(listOf(InferredKind.Text, InferredKind.Text), InferredKind.Boolean),
        "typewriter.text.starts_with" to OperationType(listOf(InferredKind.Text, InferredKind.Text), InferredKind.Boolean),
        "typewriter.text.ends_with" to OperationType(listOf(InferredKind.Text, InferredKind.Text), InferredKind.Boolean),
        "typewriter.text.interpolate" to OperationType(emptyList(), InferredKind.Text, InferredKind.Any),
        "typewriter.regex.matches" to OperationType(listOf(InferredKind.Text, InferredKind.Text), InferredKind.Boolean),
        "typewriter.regex.capture" to
            OperationType(listOf(InferredKind.Text, InferredKind.Text, InferredKind.Integer), InferredKind.Text),
        "typewriter.regex.replace" to
            OperationType(listOf(InferredKind.Text, InferredKind.Text, InferredKind.Text), InferredKind.Text),
        "typewriter.collection.size" to OperationType(listOf(InferredKind.Collection), InferredKind.Integer),
        "typewriter.collection.access" to OperationType(listOf(InferredKind.Collection, InferredKind.Any), InferredKind.Any),
        "typewriter.collection.contains" to OperationType(listOf(InferredKind.Collection, InferredKind.Any), InferredKind.Boolean),
        "typewriter.color.with_alpha" to OperationType(listOf(InferredKind.Integer, InferredKind.Integer), InferredKind.Integer),
        "typewriter.rule.one_of" to OperationType(listOf(InferredKind.Any), InferredKind.Boolean, InferredKind.Any),
        "typewriter.rule.nonEmpty" to OperationType(listOf(InferredKind.Sized), InferredKind.Boolean),
        "typewriter.rule.nonBlank" to OperationType(listOf(InferredKind.Text), InferredKind.Boolean),
        "typewriter.rule.minimumLength" to OperationType(listOf(InferredKind.Sized, InferredKind.Integer), InferredKind.Boolean),
        "typewriter.rule.maximumLength" to OperationType(listOf(InferredKind.Sized, InferredKind.Integer), InferredKind.Boolean),
        "typewriter.rule.lengthBetween" to
            OperationType(listOf(InferredKind.Sized, InferredKind.Integer, InferredKind.Integer), InferredKind.Boolean),
        "typewriter.rule.minimumLines" to OperationType(listOf(InferredKind.Text, InferredKind.Integer), InferredKind.Boolean),
        "typewriter.rule.maximumLines" to OperationType(listOf(InferredKind.Text, InferredKind.Integer), InferredKind.Boolean),
        "typewriter.rule.singleLine" to OperationType(listOf(InferredKind.Text), InferredKind.Boolean),
        "typewriter.rule.regex" to OperationType(listOf(InferredKind.Text, InferredKind.Text), InferredKind.Boolean),
        "typewriter.rule.startsWith" to OperationType(listOf(InferredKind.Text, InferredKind.Text), InferredKind.Boolean),
        "typewriter.rule.endsWith" to OperationType(listOf(InferredKind.Text, InferredKind.Text), InferredKind.Boolean),
        "typewriter.rule.minimum" to
            OperationType(listOf(InferredKind.Number, InferredKind.Number, InferredKind.Boolean), InferredKind.Boolean),
        "typewriter.rule.maximum" to
            OperationType(listOf(InferredKind.Number, InferredKind.Number, InferredKind.Boolean), InferredKind.Boolean),
        "typewriter.rule.between" to
            OperationType(listOf(InferredKind.Number, InferredKind.Number, InferredKind.Number), InferredKind.Boolean),
        "typewriter.rule.positive" to OperationType(listOf(InferredKind.Number), InferredKind.Boolean),
        "typewriter.rule.nonNegative" to OperationType(listOf(InferredKind.Number), InferredKind.Boolean),
        "typewriter.rule.multipleOf" to OperationType(listOf(InferredKind.Number, InferredKind.Number), InferredKind.Boolean),
        "typewriter.rule.maximumScale" to OperationType(listOf(InferredKind.Number, InferredKind.Integer), InferredKind.Boolean),
        "typewriter.rule.minimumItems" to OperationType(listOf(InferredKind.Collection, InferredKind.Integer), InferredKind.Boolean),
        "typewriter.rule.maximumItems" to OperationType(listOf(InferredKind.Collection, InferredKind.Integer), InferredKind.Boolean),
        "typewriter.rule.itemsBetween" to
            OperationType(listOf(InferredKind.Collection, InferredKind.Integer, InferredKind.Integer), InferredKind.Boolean),
        "typewriter.rule.unique" to OperationType(listOf(InferredKind.Collection), InferredKind.Boolean),
        "typewriter.rule.notNull" to OperationType(listOf(InferredKind.Any), InferredKind.Boolean),
        "typewriter.rule.notBefore" to OperationType(listOf(InferredKind.Timestamp, InferredKind.Timestamp), InferredKind.Boolean),
        "typewriter.rule.notAfter" to OperationType(listOf(InferredKind.Timestamp, InferredKind.Timestamp), InferredKind.Boolean),
        "typewriter.rule.opaque" to OperationType(listOf(InferredKind.Integer), InferredKind.Boolean),
    )

internal fun untypedPortableOperations(registry: PortableOperationRegistry = PortableOperationRegistry.Standard): Set<OperationId> =
    registry.semantics.map(PortableOperationSemantics::id).toSet() - OPERATION_TYPES.keys.map(::OperationId).toSet()


private fun ExpressionNode.mayBeMissing(bindings: Map<ExpressionBindingId, com.typewritermc.expression.ExpressionType>): Boolean = when (this) {
    is ExpressionNode.Literal -> value == DataValue.Unfilled
    is ExpressionNode.Read -> bindings[binding]?.mayBeMissing ?: true
    is ExpressionNode.Call -> arguments.any { it.mayBeMissing(bindings) }
    is ExpressionNode.And -> left.mayBeMissing(bindings) || right.mayBeMissing(bindings)
    is ExpressionNode.Or -> left.mayBeMissing(bindings) || right.mayBeMissing(bindings)
    is ExpressionNode.Conditional -> test.mayBeMissing(bindings) || yes.mayBeMissing(bindings) || no.mayBeMissing(bindings)
    is ExpressionNode.OrElse -> input.mayBeMissing(bindings) && fallback.mayBeMissing(bindings)
    is ExpressionNode.Collection -> input.mayBeMissing(bindings) || arguments.any { it.mayBeMissing(bindings) } ||
        (body?.mayBeMissing(bindings + this.bindings.associateWith { com.typewritermc.expression.ExpressionType(TypeUse.Scalar(ScalarKind.Unit), false) }) ?: false)
}

private fun InferredType.numericFamily(): String? {
    val scalar = if (this is InferredType.Value) (checked.schema.representation as? ResolvedRepresentation.Scalar)?.kind else (use as? TypeUse.Scalar)?.kind
    return when (scalar) {
        is ScalarKind.Integer -> "integer"
        is ScalarKind.Float -> "float"
        ScalarKind.Decimal -> "decimal"
        else -> null
    }
}

private data class CollectionOperationShape(
    val bindings: Int,
    val arguments: IntRange,
    val bodyRequired: Boolean,
    val bodyAllowed: Boolean = bodyRequired,
)

private val COLLECTION_OPERATIONS =
    buildMap {
        listOf(
            "any",
            "all",
            "none",
            "map",
            "filter",
            "find",
            "find_last",
            "count",
            "distinct_by",
            "group_by",
            "flat_map",
            "unique_by",
        ).forEach { name ->
            put(OperationId("typewriter.collection.$name"), CollectionOperationShape(1, 0..0, bodyRequired = true))
        }
        put(OperationId("typewriter.collection.sort_by"), CollectionOperationShape(1, 0..1, bodyRequired = true))
        put(OperationId("typewriter.collection.sort_with"), CollectionOperationShape(2, 0..0, bodyRequired = true))
        put(OperationId("typewriter.collection.reduce"), CollectionOperationShape(2, 0..0, bodyRequired = true))
        put(OperationId("typewriter.collection.fold"), CollectionOperationShape(2, 1..1, bodyRequired = true))
        put(OperationId("typewriter.collection.take"), CollectionOperationShape(0, 1..1, bodyRequired = false))
        put(OperationId("typewriter.collection.skip"), CollectionOperationShape(0, 1..1, bodyRequired = false))
        put(OperationId("typewriter.collection.reverse"), CollectionOperationShape(0, 0..0, bodyRequired = false))
        put(OperationId("typewriter.collection.distinct"), CollectionOperationShape(0, 0..0, bodyRequired = false))
    }

private fun InferredType.scalarUse(): TypeUse? = when (this) {
    is InferredType.Value -> (checked.schema.representation as? ResolvedRepresentation.Scalar)?.kind?.let(TypeUse::Scalar)
    is InferredType.NumericLiteral -> TypeUse.Scalar(scalar)
    InferredType.Integer -> TypeUse.Scalar(ScalarKind.Integer(com.typewritermc.types.IntegerWidth.SIGNED_64))
    InferredType.Text -> TypeUse.Scalar(ScalarKind.Text)
    InferredType.Boolean -> TypeUse.Scalar(ScalarKind.Boolean)
    InferredType.Duration -> TypeUse.Scalar(ScalarKind.Duration)
    InferredType.Timestamp -> TypeUse.Scalar(ScalarKind.Timestamp)
    else -> null
}
