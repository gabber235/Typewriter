package com.typewritermc.configuration

import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.ValuePath
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.expression.OperationId
import com.typewritermc.expression.PortableOperationRegistry
import com.typewritermc.expression.PortableOperationSemantics
import com.typewritermc.presentation.ExpressionNode
import com.typewritermc.types.DataValue
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.DeclarationDiagnostic
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.ResolvedRepresentation
import com.typewritermc.types.catalog.resolve
import java.math.BigDecimal

class DefaultPortableRuleCompiler(
    private val operations: PortableOperationRegistry = PortableOperationRegistry.Standard,
) : PortableRuleCompiler {
    override fun compile(
        rule: OwnedRule,
        subject: CheckedType,
    ): Resolution<CheckedRule> {
        val diagnostics = mutableListOf<DeclarationDiagnostic>()
        validateSymbols(rule.descriptor.predicate, mutableSetOf(), rule, diagnostics)
        val result =
            validate(
                rule.descriptor.predicate,
                subject,
                mutableMapOf(),
                rule,
                diagnostics,
            )
        if (result.kind == ExpressionKind.Invalid && diagnostics.isEmpty()) {
            diagnostics += diagnostic(rule, "rule_type_inference_failed")
        }
        if (result.kind != ExpressionKind.Boolean && result.kind != ExpressionKind.Invalid) {
            diagnostics += diagnostic(rule, "rule_predicate_must_be_boolean")
        }
        return if (diagnostics.isEmpty()) {
            Resolution.Ready(CheckedRule(subject.catalog, rule, subject))
        } else {
            Resolution.Invalid(diagnostics.distinct())
        }
    }

    internal fun validateStructure(rule: OwnedRule): List<DeclarationDiagnostic> {
        val diagnostics = mutableListOf<DeclarationDiagnostic>()
        validateSymbols(rule.descriptor.predicate, mutableSetOf(), rule, diagnostics)
        return diagnostics.distinct()
    }

    private fun validateSymbols(
        expression: ExpressionNode,
        localBindings: MutableSet<ExpressionBindingId>,
        rule: OwnedRule,
        diagnostics: MutableList<DeclarationDiagnostic>,
    ) {
        when (expression) {
            is ExpressionNode.Literal -> {}

            is ExpressionNode.Read -> {
                if (expression.binding.value != "configured_value" && expression.binding !in localBindings) {
                    diagnostics += diagnostic(rule, "unknown_rule_binding")
                }
            }

            is ExpressionNode.Call -> {
                val semantics = operations.semantics(expression.operation)
                if (semantics == null) {
                    diagnostics += diagnostic(rule, "unknown_rule_operation")
                } else if (expression.arguments.size !in semantics.minimumArguments..semantics.maximumArguments) {
                    diagnostics += diagnostic(rule, "invalid_rule_operation_arity")
                }
                expression.arguments.forEach { validateSymbols(it, localBindings, rule, diagnostics) }
            }

            is ExpressionNode.And -> {
                validateSymbols(expression.left, localBindings, rule, diagnostics)
                validateSymbols(expression.right, localBindings, rule, diagnostics)
            }

            is ExpressionNode.Or -> {
                validateSymbols(expression.left, localBindings, rule, diagnostics)
                validateSymbols(expression.right, localBindings, rule, diagnostics)
            }

            is ExpressionNode.Conditional -> {
                validateSymbols(expression.test, localBindings, rule, diagnostics)
                validateSymbols(expression.yes, localBindings, rule, diagnostics)
                validateSymbols(expression.no, localBindings, rule, diagnostics)
            }

            is ExpressionNode.OrElse -> {
                validateSymbols(expression.input, localBindings, rule, diagnostics)
                validateSymbols(expression.fallback, localBindings, rule, diagnostics)
            }

            is ExpressionNode.Collection -> {
                val shape = COLLECTION_OPERATIONS[expression.operation]
                if (shape == null) {
                    diagnostics += diagnostic(rule, "unknown_collection_rule_operation")
                } else {
                    if (expression.bindings.size != shape.bindings || expression.arguments.size !in shape.arguments) {
                        diagnostics += diagnostic(rule, "invalid_collection_rule_operation_arity")
                    }
                    if ((shape.bodyRequired && expression.body == null) || (!shape.bodyAllowed && expression.body != null)) {
                        diagnostics += diagnostic(rule, "invalid_collection_rule_operation_body")
                    }
                }
                validateSymbols(expression.input, localBindings, rule, diagnostics)
                expression.arguments.forEach { validateSymbols(it, localBindings, rule, diagnostics) }
                if (expression.bindings.distinct().size != expression.bindings.size || expression.bindings.any(localBindings::contains)) {
                    diagnostics += diagnostic(rule, "duplicate_collection_rule_binding")
                }
                localBindings += expression.bindings
                expression.body?.let { validateSymbols(it, localBindings, rule, diagnostics) }
                localBindings -= expression.bindings.toSet()
            }
        }
    }

    private fun validate(
        expression: ExpressionNode,
        subject: CheckedType,
        localBindings: MutableMap<ExpressionBindingId, ExpressionType>,
        rule: OwnedRule,
        diagnostics: MutableList<DeclarationDiagnostic>,
    ): ExpressionType =
        when (expression) {
            is ExpressionNode.Literal -> {
                expression.value.expressionType(subject)
            }

            is ExpressionNode.Read -> {
                val base =
                    if (expression.binding.value == "configured_value") {
                        ExpressionType.Value(subject)
                    } else {
                        localBindings[expression.binding]
                    }
                if (base == null) {
                    ExpressionType.Invalid
                } else {
                    base.at(expression.path, rule, diagnostics)
                }
            }

            is ExpressionNode.Call -> {
                val arguments = expression.arguments.map { validate(it, subject, localBindings, rule, diagnostics) }
                validateCall(expression.operation, arguments, rule, diagnostics)
            }

            is ExpressionNode.And -> {
                requireBoolean(validate(expression.left, subject, localBindings, rule, diagnostics), rule, diagnostics)
                requireBoolean(validate(expression.right, subject, localBindings, rule, diagnostics), rule, diagnostics)
                ExpressionType.Boolean
            }

            is ExpressionNode.Or -> {
                requireBoolean(validate(expression.left, subject, localBindings, rule, diagnostics), rule, diagnostics)
                requireBoolean(validate(expression.right, subject, localBindings, rule, diagnostics), rule, diagnostics)
                ExpressionType.Boolean
            }

            is ExpressionNode.Conditional -> {
                requireBoolean(validate(expression.test, subject, localBindings, rule, diagnostics), rule, diagnostics)
                val yes = validate(expression.yes, subject, localBindings, rule, diagnostics)
                val no = validate(expression.no, subject, localBindings, rule, diagnostics)
                compatible(yes, no, rule, diagnostics)
            }

            is ExpressionNode.OrElse -> {
                val input = validate(expression.input, subject, localBindings, rule, diagnostics)
                val fallback = validate(expression.fallback, subject, localBindings, rule, diagnostics)
                compatible(input, fallback, rule, diagnostics)
            }

            is ExpressionNode.Collection -> {
                val input = validate(expression.input, subject, localBindings, rule, diagnostics)
                val item = input.collectionItem(rule, diagnostics)
                val arguments = expression.arguments.map { validate(it, subject, localBindings, rule, diagnostics) }
                val bindingTypes = collectionBindingTypes(expression.operation, item, arguments, rule, diagnostics)
                expression.bindings.zip(bindingTypes).forEach { (binding, type) -> localBindings[binding] = type }
                val body = expression.body?.let { validate(it, subject, localBindings, rule, diagnostics) }
                expression.bindings.forEach(localBindings::remove)
                when (expression.operation.value) {
                    "typewriter.collection.any", "typewriter.collection.all", "typewriter.collection.none" -> {
                        requireBoolean(body ?: missingCollectionBody(rule, diagnostics), rule, diagnostics)
                        ExpressionType.Boolean
                    }

                    "typewriter.collection.filter" -> {
                        requireBoolean(body ?: missingCollectionBody(rule, diagnostics), rule, diagnostics)
                        input
                    }

                    "typewriter.collection.find", "typewriter.collection.find_last" -> {
                        requireBoolean(body ?: missingCollectionBody(rule, diagnostics), rule, diagnostics)
                        item
                    }

                    "typewriter.collection.count" -> {
                        requireBoolean(body ?: missingCollectionBody(rule, diagnostics), rule, diagnostics)
                        ExpressionType.Integer
                    }

                    "typewriter.collection.unique_by" -> {
                        ExpressionType.Boolean
                    }

                    "typewriter.collection.map" -> {
                        ExpressionType.Collection(body ?: missingCollectionBody(rule, diagnostics))
                    }

                    "typewriter.collection.flat_map" -> {
                        val nested = body ?: missingCollectionBody(rule, diagnostics)
                        if (nested is ExpressionType.Collection) ExpressionType.Collection(nested.item) else ExpressionType.Invalid
                    }

                    "typewriter.collection.distinct_by", "typewriter.collection.sort_by",
                    "typewriter.collection.take", "typewriter.collection.skip", "typewriter.collection.reverse",
                    "typewriter.collection.distinct",
                    -> {
                        input
                    }

                    "typewriter.collection.sort_with" -> {
                        val comparison = body ?: missingCollectionBody(rule, diagnostics)
                        if (comparison.kind !in setOf(ExpressionKind.Integer, ExpressionKind.Number, ExpressionKind.Invalid)) {
                            diagnostics += diagnostic(rule, "invalid_collection_comparator_type")
                        }
                        input
                    }

                    "typewriter.collection.group_by" -> {
                        ExpressionType.Collection(
                            ExpressionType.MapEntry(
                                body ?: missingCollectionBody(rule, diagnostics),
                                ExpressionType.Collection(item),
                            ),
                        )
                    }

                    "typewriter.collection.reduce" -> {
                        compatible(item, body ?: missingCollectionBody(rule, diagnostics), rule, diagnostics)
                    }

                    "typewriter.collection.fold" -> {
                        val initial = arguments.singleOrNull() ?: ExpressionType.Invalid
                        compatible(initial, body ?: missingCollectionBody(rule, diagnostics), rule, diagnostics)
                    }

                    else -> {
                        ExpressionType.Invalid
                    }
                }
            }
        }

    private fun collectionBindingTypes(
        operation: OperationId,
        item: ExpressionType,
        arguments: List<ExpressionType>,
        rule: OwnedRule,
        diagnostics: MutableList<DeclarationDiagnostic>,
    ): List<ExpressionType> {
        val shape = COLLECTION_OPERATIONS[operation]
        if (shape == null) return emptyList()
        if (operation.value in setOf("typewriter.collection.take", "typewriter.collection.skip")) {
            val count = arguments.singleOrNull()
            if (count?.kind != ExpressionKind.Integer) diagnostics += diagnostic(rule, "invalid_collection_argument_type")
        }
        if (operation.value == "typewriter.collection.sort_by" && arguments.singleOrNull()?.kind !in setOf(null, ExpressionKind.Boolean)) {
            diagnostics += diagnostic(rule, "invalid_collection_argument_type")
        }
        return when (operation.value) {
            "typewriter.collection.fold" -> listOf(arguments.singleOrNull() ?: ExpressionType.Invalid, item)
            "typewriter.collection.reduce", "typewriter.collection.sort_with" -> listOf(item, item)
            else -> List(shape.bindings) { item }
        }
    }

    private fun missingCollectionBody(
        rule: OwnedRule,
        diagnostics: MutableList<DeclarationDiagnostic>,
    ): ExpressionType {
        diagnostics += diagnostic(rule, "missing_collection_rule_body")
        return ExpressionType.Invalid
    }

    private fun validateCall(
        operation: OperationId,
        arguments: List<ExpressionType>,
        rule: OwnedRule,
        diagnostics: MutableList<DeclarationDiagnostic>,
    ): ExpressionType {
        val expectation = OPERATION_TYPES[operation.value]
        if (expectation == null) {
            diagnostics += diagnostic(rule, "unsupported_rule_operation_type")
            return ExpressionType.Invalid
        }
        arguments.forEachIndexed { index, argument ->
            val expected = expectation.inputs.getOrNull(index) ?: expectation.repeated ?: ExpressionKind.Any
            if (!expected.accepts(argument.kind)) diagnostics += diagnostic(rule, "invalid_rule_operand_type")
        }
        if (operation.value in EQUALITY_OPERATIONS && arguments.isNotEmpty()) {
            arguments.drop(1).fold(arguments.first()) { current, next -> compatible(current, next, rule, diagnostics) }
        }
        if (operation.value in NUMERIC_FAMILY_OPERATIONS && arguments.isNotEmpty()) {
            arguments.drop(1).fold(arguments.first()) { current, next -> compatible(current, next, rule, diagnostics) }
        }
        return expressionType(expectation.output)
    }

    private fun requireBoolean(
        type: ExpressionType,
        rule: OwnedRule,
        diagnostics: MutableList<DeclarationDiagnostic>,
    ) {
        if (type.kind !in setOf(ExpressionKind.Boolean, ExpressionKind.Invalid)) {
            diagnostics += diagnostic(rule, "invalid_boolean_operand")
        }
    }

    private fun compatible(
        first: ExpressionType,
        second: ExpressionType,
        rule: OwnedRule,
        diagnostics: MutableList<DeclarationDiagnostic>,
    ): ExpressionType {
        if (first.kind == ExpressionKind.Invalid || second.kind == ExpressionKind.Invalid) return ExpressionType.Invalid
        if (first.kind == ExpressionKind.Any) return second
        if (second.kind == ExpressionKind.Any) return first
        if (first.kind != second.kind || (first.use != null && second.use != null && first.use != second.use)) {
            diagnostics += diagnostic(rule, "incompatible_rule_operand_types")
            return ExpressionType.Invalid
        }
        return first
    }

    private fun diagnostic(
        rule: OwnedRule,
        code: String,
    ): DeclarationDiagnostic = DeclarationDiagnostic(rule.id.origin.owner, code)
}

private enum class ExpressionKind {
    Any,
    Boolean,
    Integer,
    Number,
    Text,
    Bytes,
    Collection,
    Sized,
    Timestamp,
    Invalid,
}

private sealed interface ExpressionType {
    val kind: ExpressionKind
    val use: TypeUse?
        get() = null

    data class Value(
        val checked: CheckedType,
    ) : ExpressionType {
        override val kind: ExpressionKind = checked.expressionKind()
        override val use: TypeUse = checked.use
    }

    data class Collection(
        val item: ExpressionType,
    ) : ExpressionType {
        override val kind: ExpressionKind = ExpressionKind.Collection
    }

    data class MapEntry(
        val key: ExpressionType,
        val value: ExpressionType,
    ) : ExpressionType {
        override val kind: ExpressionKind = ExpressionKind.Any
    }

    data object Any : ExpressionType {
        override val kind: ExpressionKind = ExpressionKind.Any
    }

    data object Boolean : ExpressionType {
        override val kind: ExpressionKind = ExpressionKind.Boolean
    }

    data object Integer : ExpressionType {
        override val kind: ExpressionKind = ExpressionKind.Integer
    }

    data object Number : ExpressionType {
        override val kind: ExpressionKind = ExpressionKind.Number
    }

    data object Text : ExpressionType {
        override val kind: ExpressionKind = ExpressionKind.Text
    }

    data object Bytes : ExpressionType {
        override val kind: ExpressionKind = ExpressionKind.Bytes
    }

    data object Timestamp : ExpressionType {
        override val kind: ExpressionKind = ExpressionKind.Timestamp
    }

    data object Invalid : ExpressionType {
        override val kind: ExpressionKind = ExpressionKind.Invalid
    }
}

private fun CheckedType.expressionKind(): ExpressionKind =
    when (val representation = schema.representation) {
        is ResolvedRepresentation.Scalar -> {
            when (representation.kind) {
                ScalarKind.Boolean -> ExpressionKind.Boolean
                is ScalarKind.Integer -> ExpressionKind.Integer
                is ScalarKind.Float, ScalarKind.Decimal -> ExpressionKind.Number
                ScalarKind.Text -> ExpressionKind.Text
                ScalarKind.Bytes -> ExpressionKind.Bytes
                ScalarKind.Timestamp -> ExpressionKind.Timestamp
                else -> ExpressionKind.Any
            }
        }

        is ResolvedRepresentation.Sequence, is ResolvedRepresentation.Mapping -> {
            ExpressionKind.Collection
        }

        else -> {
            ExpressionKind.Any
        }
    }

private fun DataValue.expressionType(subject: CheckedType): ExpressionType =
    when (this) {
        is DataValue.Named -> {
            when (val resolved = subject.resolve(actualType)) {
                is Resolution.Ready -> ExpressionType.Value(resolved.value)
                is Resolution.Invalid -> ExpressionType.Invalid
            }
        }

        is DataValue.Boolean -> {
            ExpressionType.Boolean
        }

        is DataValue.Integer -> {
            ExpressionType.Integer
        }

        is DataValue.Float, is DataValue.Decimal -> {
            ExpressionType.Number
        }

        is DataValue.StringValue -> {
            ExpressionType.Text
        }

        is DataValue.Bytes -> {
            ExpressionType.Bytes
        }

        is DataValue.Timestamp -> {
            ExpressionType.Timestamp
        }

        is DataValue.ListValue, is DataValue.SetValue, is DataValue.MapValue -> {
            ExpressionType.Collection(ExpressionType.Any)
        }

        else -> {
            ExpressionType.Any
        }
    }

private fun ExpressionType.at(
    path: ValuePath,
    rule: OwnedRule,
    diagnostics: MutableList<DeclarationDiagnostic>,
): ExpressionType {
    var current = this
    path.segments.forEach { segment ->
        current =
            when (segment) {
                is PathSegment.Field -> {
                    val value = current as? ExpressionType.Value
                    val field =
                        value
                            ?.checked
                            ?.schema
                            ?.fields
                            ?.singleOrNull { it.key == segment.name }
                    if (value == null || field == null) {
                        diagnostics += DeclarationDiagnostic(rule.id.origin.owner, "invalid_rule_field_path")
                        ExpressionType.Invalid
                    } else {
                        value.checked.resolve(field.type).toExpressionType()
                    }
                }

                is PathSegment.Item -> {
                    current.collectionItem(rule, diagnostics)
                }

                PathSegment.MapKey -> {
                    (current as? ExpressionType.MapEntry)?.key ?: run {
                        diagnostics += DeclarationDiagnostic(rule.id.origin.owner, "invalid_rule_map_path")
                        ExpressionType.Invalid
                    }
                }

                PathSegment.MapValue -> {
                    (current as? ExpressionType.MapEntry)?.value ?: run {
                        diagnostics += DeclarationDiagnostic(rule.id.origin.owner, "invalid_rule_map_path")
                        ExpressionType.Invalid
                    }
                }
            }
    }
    return current
}

private fun ExpressionType.collectionItem(
    rule: OwnedRule,
    diagnostics: MutableList<DeclarationDiagnostic>,
): ExpressionType =
    when (this) {
        is ExpressionType.Collection -> {
            item
        }

        is ExpressionType.Value -> {
            when (val representation = checked.schema.representation) {
                is ResolvedRepresentation.Sequence -> {
                    checked.resolve(representation.item).toExpressionType()
                }

                is ResolvedRepresentation.Mapping -> {
                    ExpressionType.MapEntry(
                        checked.resolve(representation.key).toExpressionType(),
                        checked.resolve(representation.value).toExpressionType(),
                    )
                }

                else -> {
                    diagnostics += DeclarationDiagnostic(rule.id.origin.owner, "rule_collection_expected")
                    ExpressionType.Invalid
                }
            }
        }

        else -> {
            diagnostics += DeclarationDiagnostic(rule.id.origin.owner, "rule_collection_expected")
            ExpressionType.Invalid
        }
    }

private fun Resolution<CheckedType>.toExpressionType(): ExpressionType =
    when (this) {
        is Resolution.Ready -> ExpressionType.Value(value)
        is Resolution.Invalid -> ExpressionType.Invalid
    }

private fun expressionType(kind: ExpressionKind): ExpressionType =
    when (kind) {
        ExpressionKind.Any, ExpressionKind.Sized -> ExpressionType.Any
        ExpressionKind.Boolean -> ExpressionType.Boolean
        ExpressionKind.Integer -> ExpressionType.Integer
        ExpressionKind.Number -> ExpressionType.Number
        ExpressionKind.Text -> ExpressionType.Text
        ExpressionKind.Bytes -> ExpressionType.Bytes
        ExpressionKind.Collection -> ExpressionType.Collection(ExpressionType.Any)
        ExpressionKind.Timestamp -> ExpressionType.Timestamp
        ExpressionKind.Invalid -> ExpressionType.Invalid
    }

private data class OperationType(
    val inputs: List<ExpressionKind>,
    val output: ExpressionKind,
    val repeated: ExpressionKind? = null,
)

private fun ExpressionKind.accepts(actual: ExpressionKind): Boolean =
    actual == ExpressionKind.Invalid ||
        this == ExpressionKind.Any ||
        this == actual ||
        (this == ExpressionKind.Number && actual == ExpressionKind.Integer) ||
        (this == ExpressionKind.Sized && actual in setOf(ExpressionKind.Text, ExpressionKind.Bytes, ExpressionKind.Collection))

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
        "typewriter.value.eq" to OperationType(listOf(ExpressionKind.Any, ExpressionKind.Any), ExpressionKind.Boolean),
        "typewriter.value.neq" to OperationType(listOf(ExpressionKind.Any, ExpressionKind.Any), ExpressionKind.Boolean),
        "typewriter.value.is_null" to OperationType(listOf(ExpressionKind.Any), ExpressionKind.Boolean),
        "typewriter.link.target" to OperationType(listOf(ExpressionKind.Any), ExpressionKind.Text),
        "typewriter.record.field" to OperationType(listOf(ExpressionKind.Any, ExpressionKind.Text), ExpressionKind.Any),
        "typewriter.boolean.not" to OperationType(listOf(ExpressionKind.Boolean), ExpressionKind.Boolean),
        "typewriter.number.gt" to OperationType(listOf(ExpressionKind.Number, ExpressionKind.Number), ExpressionKind.Boolean),
        "typewriter.number.gte" to OperationType(listOf(ExpressionKind.Number, ExpressionKind.Number), ExpressionKind.Boolean),
        "typewriter.number.lt" to OperationType(listOf(ExpressionKind.Number, ExpressionKind.Number), ExpressionKind.Boolean),
        "typewriter.number.lte" to OperationType(listOf(ExpressionKind.Number, ExpressionKind.Number), ExpressionKind.Boolean),
        "typewriter.number.add" to OperationType(listOf(ExpressionKind.Number), ExpressionKind.Number, ExpressionKind.Number),
        "typewriter.number.subtract" to OperationType(listOf(ExpressionKind.Number), ExpressionKind.Number, ExpressionKind.Number),
        "typewriter.number.multiply" to OperationType(listOf(ExpressionKind.Number), ExpressionKind.Number, ExpressionKind.Number),
        "typewriter.number.divide" to OperationType(listOf(ExpressionKind.Number), ExpressionKind.Number, ExpressionKind.Number),
        "typewriter.number.remainder" to OperationType(listOf(ExpressionKind.Number), ExpressionKind.Number, ExpressionKind.Number),
        "typewriter.number.negate" to OperationType(listOf(ExpressionKind.Number), ExpressionKind.Number),
        "typewriter.text.length" to OperationType(listOf(ExpressionKind.Text), ExpressionKind.Integer),
        "typewriter.text.has_line_break" to OperationType(listOf(ExpressionKind.Text), ExpressionKind.Boolean),
        "typewriter.text.trim" to OperationType(listOf(ExpressionKind.Text), ExpressionKind.Text),
        "typewriter.text.lower" to OperationType(listOf(ExpressionKind.Text), ExpressionKind.Text),
        "typewriter.text.upper" to OperationType(listOf(ExpressionKind.Text), ExpressionKind.Text),
        "typewriter.text.title" to OperationType(listOf(ExpressionKind.Text), ExpressionKind.Text),
        "typewriter.text.replace" to
            OperationType(listOf(ExpressionKind.Text, ExpressionKind.Text, ExpressionKind.Text), ExpressionKind.Text),
        "typewriter.text.split" to OperationType(listOf(ExpressionKind.Text, ExpressionKind.Text), ExpressionKind.Collection),
        "typewriter.text.join" to OperationType(listOf(ExpressionKind.Collection, ExpressionKind.Text), ExpressionKind.Text),
        "typewriter.text.substring" to
            OperationType(listOf(ExpressionKind.Text, ExpressionKind.Integer), ExpressionKind.Text, ExpressionKind.Integer),
        "typewriter.text.contains" to OperationType(listOf(ExpressionKind.Text, ExpressionKind.Text), ExpressionKind.Boolean),
        "typewriter.text.starts_with" to OperationType(listOf(ExpressionKind.Text, ExpressionKind.Text), ExpressionKind.Boolean),
        "typewriter.text.ends_with" to OperationType(listOf(ExpressionKind.Text, ExpressionKind.Text), ExpressionKind.Boolean),
        "typewriter.text.interpolate" to OperationType(emptyList(), ExpressionKind.Text, ExpressionKind.Any),
        "typewriter.regex.matches" to OperationType(listOf(ExpressionKind.Text, ExpressionKind.Text), ExpressionKind.Boolean),
        "typewriter.regex.capture" to
            OperationType(listOf(ExpressionKind.Text, ExpressionKind.Text, ExpressionKind.Integer), ExpressionKind.Text),
        "typewriter.regex.replace" to
            OperationType(listOf(ExpressionKind.Text, ExpressionKind.Text, ExpressionKind.Text), ExpressionKind.Text),
        "typewriter.collection.size" to OperationType(listOf(ExpressionKind.Collection), ExpressionKind.Integer),
        "typewriter.collection.access" to OperationType(listOf(ExpressionKind.Collection, ExpressionKind.Any), ExpressionKind.Any),
        "typewriter.collection.contains" to OperationType(listOf(ExpressionKind.Collection, ExpressionKind.Any), ExpressionKind.Boolean),
        "typewriter.color.with_alpha" to OperationType(listOf(ExpressionKind.Integer, ExpressionKind.Integer), ExpressionKind.Integer),
        "typewriter.rule.one_of" to OperationType(listOf(ExpressionKind.Any), ExpressionKind.Boolean, ExpressionKind.Any),
        "typewriter.rule.nonEmpty" to OperationType(listOf(ExpressionKind.Sized), ExpressionKind.Boolean),
        "typewriter.rule.nonBlank" to OperationType(listOf(ExpressionKind.Text), ExpressionKind.Boolean),
        "typewriter.rule.minimumLength" to OperationType(listOf(ExpressionKind.Sized, ExpressionKind.Integer), ExpressionKind.Boolean),
        "typewriter.rule.maximumLength" to OperationType(listOf(ExpressionKind.Sized, ExpressionKind.Integer), ExpressionKind.Boolean),
        "typewriter.rule.lengthBetween" to
            OperationType(listOf(ExpressionKind.Sized, ExpressionKind.Integer, ExpressionKind.Integer), ExpressionKind.Boolean),
        "typewriter.rule.minimumLines" to OperationType(listOf(ExpressionKind.Text, ExpressionKind.Integer), ExpressionKind.Boolean),
        "typewriter.rule.maximumLines" to OperationType(listOf(ExpressionKind.Text, ExpressionKind.Integer), ExpressionKind.Boolean),
        "typewriter.rule.singleLine" to OperationType(listOf(ExpressionKind.Text), ExpressionKind.Boolean),
        "typewriter.rule.regex" to OperationType(listOf(ExpressionKind.Text, ExpressionKind.Text), ExpressionKind.Boolean),
        "typewriter.rule.startsWith" to OperationType(listOf(ExpressionKind.Text, ExpressionKind.Text), ExpressionKind.Boolean),
        "typewriter.rule.endsWith" to OperationType(listOf(ExpressionKind.Text, ExpressionKind.Text), ExpressionKind.Boolean),
        "typewriter.rule.minimum" to
            OperationType(listOf(ExpressionKind.Number, ExpressionKind.Number, ExpressionKind.Boolean), ExpressionKind.Boolean),
        "typewriter.rule.maximum" to
            OperationType(listOf(ExpressionKind.Number, ExpressionKind.Number, ExpressionKind.Boolean), ExpressionKind.Boolean),
        "typewriter.rule.between" to
            OperationType(listOf(ExpressionKind.Number, ExpressionKind.Number, ExpressionKind.Number), ExpressionKind.Boolean),
        "typewriter.rule.positive" to OperationType(listOf(ExpressionKind.Number), ExpressionKind.Boolean),
        "typewriter.rule.nonNegative" to OperationType(listOf(ExpressionKind.Number), ExpressionKind.Boolean),
        "typewriter.rule.multipleOf" to OperationType(listOf(ExpressionKind.Number, ExpressionKind.Number), ExpressionKind.Boolean),
        "typewriter.rule.maximumScale" to OperationType(listOf(ExpressionKind.Number, ExpressionKind.Integer), ExpressionKind.Boolean),
        "typewriter.rule.minimumItems" to OperationType(listOf(ExpressionKind.Collection, ExpressionKind.Integer), ExpressionKind.Boolean),
        "typewriter.rule.maximumItems" to OperationType(listOf(ExpressionKind.Collection, ExpressionKind.Integer), ExpressionKind.Boolean),
        "typewriter.rule.itemsBetween" to
            OperationType(listOf(ExpressionKind.Collection, ExpressionKind.Integer, ExpressionKind.Integer), ExpressionKind.Boolean),
        "typewriter.rule.unique" to OperationType(listOf(ExpressionKind.Collection), ExpressionKind.Boolean),
        "typewriter.rule.notNull" to OperationType(listOf(ExpressionKind.Any), ExpressionKind.Boolean),
        "typewriter.rule.notBefore" to OperationType(listOf(ExpressionKind.Timestamp, ExpressionKind.Timestamp), ExpressionKind.Boolean),
        "typewriter.rule.notAfter" to OperationType(listOf(ExpressionKind.Timestamp, ExpressionKind.Timestamp), ExpressionKind.Boolean),
        "typewriter.rule.opaque" to OperationType(listOf(ExpressionKind.Integer), ExpressionKind.Boolean),
    )

internal fun untypedPortableOperations(registry: PortableOperationRegistry = PortableOperationRegistry.Standard): Set<OperationId> =
    registry.semantics.map(PortableOperationSemantics::id).toSet() - OPERATION_TYPES.keys.map(::OperationId).toSet()

class DefaultPredicateReasoner : PredicateReasoner {
    override fun contradictions(rules: List<CheckedRule>): List<DeclarationDiagnostic> =
        rules
            .groupBy { it.subject.use }
            .values
            .mapNotNull(::contradiction)

    private fun contradiction(rules: List<CheckedRule>): DeclarationDiagnostic? {
        val constraints = rules.flatMap { constraints(it.rule.descriptor.predicate) }
        val numericLower = constraints.filterIsInstance<Constraint.NumericLower>().maxWithOrNull(NUMERIC_LOWER_ORDER)
        val numericUpper = constraints.filterIsInstance<Constraint.NumericUpper>().minWithOrNull(NUMERIC_UPPER_ORDER)
        val sizeLower = constraints.filterIsInstance<Constraint.SizeLower>().maxOfOrNull(Constraint.SizeLower::value)
        val sizeUpper = constraints.filterIsInstance<Constraint.SizeUpper>().minOfOrNull(Constraint.SizeUpper::value)
        val numericConflict =
            numericLower != null && numericUpper != null &&
                (
                    numericLower.value > numericUpper.value ||
                        (
                            numericLower.value == numericUpper.value &&
                                (!numericLower.inclusive || !numericUpper.inclusive)
                        )
                )
        val sizeConflict = sizeLower != null && sizeUpper != null && sizeLower > sizeUpper
        if (!numericConflict && !sizeConflict) return null
        return DeclarationDiagnostic(
            rules
                .first()
                .rule.id.origin.owner,
            "contradictory_configuration_rules",
        )
    }

    private fun constraints(expression: ExpressionNode): List<Constraint> {
        val predicate =
            if (expression is ExpressionNode.Or && expression.left.isNullGuard()) expression.right else expression
        val call = predicate as? ExpressionNode.Call ?: return emptyList()
        val values = call.arguments.map { (it as? ExpressionNode.Literal)?.value }
        return when (call.operation.value) {
            "typewriter.rule.minimum" -> {
                values
                    .getOrNull(1)
                    ?.number()
                    ?.let {
                        listOf(Constraint.NumericLower(it, values.getOrNull(2).booleanOrTrue()))
                    }.orEmpty()
            }

            "typewriter.rule.maximum" -> {
                values
                    .getOrNull(1)
                    ?.number()
                    ?.let {
                        listOf(Constraint.NumericUpper(it, values.getOrNull(2).booleanOrTrue()))
                    }.orEmpty()
            }

            "typewriter.rule.between" -> {
                val minimum = values.getOrNull(1)?.number()
                val maximum = values.getOrNull(2)?.number()
                if (minimum == null || maximum == null) {
                    emptyList()
                } else {
                    listOf(Constraint.NumericLower(minimum, true), Constraint.NumericUpper(maximum, true))
                }
            }

            "typewriter.rule.minimumLength", "typewriter.rule.minimumItems" -> {
                values
                    .getOrNull(1)
                    ?.integer()
                    ?.let { listOf(Constraint.SizeLower(it)) }
                    .orEmpty()
            }

            "typewriter.rule.maximumLength", "typewriter.rule.maximumItems" -> {
                values
                    .getOrNull(1)
                    ?.integer()
                    ?.let { listOf(Constraint.SizeUpper(it)) }
                    .orEmpty()
            }

            else -> {
                emptyList()
            }
        }
    }
}

private sealed interface Constraint {
    data class NumericLower(
        val value: BigDecimal,
        val inclusive: Boolean,
    ) : Constraint

    data class NumericUpper(
        val value: BigDecimal,
        val inclusive: Boolean,
    ) : Constraint

    data class SizeLower(
        val value: Int,
    ) : Constraint

    data class SizeUpper(
        val value: Int,
    ) : Constraint
}

private fun ExpressionNode.isNullGuard(): Boolean = this is ExpressionNode.Call && operation.value == "typewriter.value.is_null"

private fun DataValue?.number(): BigDecimal? =
    when (this) {
        is DataValue.Integer -> value.toBigDecimal()
        is DataValue.Decimal -> value.toBigDecimalOrNull()
        is DataValue.Float -> BigDecimal.valueOf(value)
        is DataValue.Named -> payload.number()
        else -> null
    }

private fun DataValue?.integer(): Int? =
    when (this) {
        is DataValue.Integer -> runCatching { value.intValueExact() }.getOrNull()
        is DataValue.Named -> payload.integer()
        else -> null
    }

private fun DataValue?.booleanOrTrue(): Boolean =
    when (this) {
        is DataValue.Boolean -> value
        is DataValue.Named -> payload.booleanOrTrue()
        else -> true
    }

private val NUMERIC_LOWER_ORDER =
    compareBy<Constraint.NumericLower> { it.value }.thenBy { if (it.inclusive) 0 else 1 }

private val NUMERIC_UPPER_ORDER =
    compareBy<Constraint.NumericUpper> { it.value }.thenBy { if (it.inclusive) 1 else 0 }

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
