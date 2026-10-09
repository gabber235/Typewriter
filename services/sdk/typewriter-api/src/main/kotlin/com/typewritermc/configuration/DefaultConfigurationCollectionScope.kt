package com.typewritermc.configuration

import com.typewritermc.authoring.CompleteValue
import com.typewritermc.authoring.ValuePath
import com.typewritermc.checking.CheckInput
import com.typewritermc.checking.CheckRecipe
import com.typewritermc.checking.DiagnosticSeverity
import com.typewritermc.checking.DiagnosticTemplate
import com.typewritermc.checking.RegisteredPredicate
import com.typewritermc.discovery.checkedGeneratedScope
import com.typewritermc.expression.Expr
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.expression.ExpressionFactory
import com.typewritermc.expression.MissingPolicy
import com.typewritermc.expression.OperationId
import com.typewritermc.expression.field
import com.typewritermc.expression.portableRegexValidationError
import com.typewritermc.presentation.ExpressionNode
import com.typewritermc.types.DataValue
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeTemplate
import kotlin.reflect.KClass

class DefaultConfigurationCollectionScope internal constructor(
    private val target: TypeDefinitionId,
    private val state: ConfigurationCollectionState,
    private val prefix: RelativeFieldPattern,
    private val constants: PortableConstantEncoder?,
    private val skipNull: Boolean,
) : ConfigurationCollectionScope {
    constructor(target: TypeDefinitionId, constants: PortableConstantEncoder? = null) :
        this(target, ConfigurationCollectionState(), RelativeFieldPattern(), constants, skipNull = false)

    override fun initialization(preference: InitializationPreference) {
        val previous = state.initialization
        require(previous == null || previous == preference) {
            "A type configuration cannot declare contradictory initialization preferences."
        }
        state.initialization = preference
    }

    override fun <S : Any> field(
        path: RelativeFieldPattern,
        representation: RepresentationKind,
        expected: TypeTemplate,
        scope: KClass<S>,
        nested: Map<FieldPatternSegment, NestedConfigurationScope>,
        expressions: ExpressionFactory<*>,
    ): S {
        val absolute = RelativeFieldPattern(prefix.segments + path.segments)
        val binding =
            RuntimeConfigurationBinding(target, state, absolute, representation, expected, nested, expressions, constants, skipNull)
        return binding.createScope(scope)
    }

    override fun nested(path: RelativeFieldPattern): ConfigurationCollectionScope =
        DefaultConfigurationCollectionScope(
            target,
            state,
            RelativeFieldPattern(prefix.segments + path.segments),
            constants,
            skipNull,
        )

    override fun collected(): CollectedConfiguration =
        CollectedConfiguration(state.recipes.toList(), state.checks.toList(), state.initialization)
}

internal class RuntimeConfigurationBinding(
    private val target: TypeDefinitionId,
    private val state: ConfigurationCollectionState,
    private val path: RelativeFieldPattern,
    private val representation: RepresentationKind,
    private val expected: TypeTemplate,
    private val nested: Map<FieldPatternSegment, NestedConfigurationScope>,
    private val expressions: ExpressionFactory<*>,
    private val constants: PortableConstantEncoder?,
    private val skipNull: Boolean,
) {
    fun <Expressions> rule(callback: ConfigurationPredicate<Expressions>): RuleDeclaration {
        val receiver = checkedGeneratedScope<Expressions>(expressions.scope, expressions.create(VALUE_EXPRESSION))
        return PendingRule(receiver.callback().node)
    }

    fun <Value> check(callback: (Value) -> Boolean): RuleDeclaration =
        PendingCheck { value ->
            @Suppress("UNCHECKED_CAST")
            callback(value as Value)
        }

    fun helper(
        operation: String,
        arguments: List<Any?>,
        message: String = helperMessage(operation),
    ) {
        if (operation == "regex") {
            val pattern =
                arguments.singleOrNull() as? String
                    ?: throw IllegalArgumentException("A regular expression rule requires one text pattern.")
            pattern.portableRegexValidationError()?.let { reason -> throw IllegalArgumentException(reason) }
        }
        val nodes = listOf(VALUE_EXPRESSION.node) + arguments.map { literal(it, expected, constants) }
        val predicate = ExpressionNode.Call(OperationId("typewriter.rule.$operation"), nodes)
        PendingRule(predicate).error(message)
    }

    fun <Expressions> uniqueBy(callback: Expressions.() -> Expr<*, MissingPolicy>) {
        val item = ExpressionBindingId("configured_item_${state.nextRule}")
        val factory = nested[FieldPatternSegment.Items]?.expressions ?: GenericValueExpressionsFactory
        val receiver =
            checkedGeneratedScope<Expressions>(
                factory.scope,
                factory.create(Expr<Any?, MissingPolicy>(ExpressionNode.Read(item, ValuePath()))),
            )
        PendingRule(
            ExpressionNode.Collection(
                operation = OperationId("typewriter.collection.unique_by"),
                input = VALUE_EXPRESSION.node,
                bindings = listOf(item),
                arguments = emptyList(),
                body = receiver.callback().node,
            ),
        ).error("Collection values must have unique keys")
    }

    fun <Scope> nested(
        configure: Configuration<Scope>,
        segment: FieldPatternSegment,
        samePath: Boolean = false,
    ) {
        val nestedPath = if (samePath) path else RelativeFieldPattern(path.segments + segment)
        val descriptor = nested[segment]
        val collection =
            DefaultConfigurationCollectionScope(
                target,
                state,
                nestedPath,
                constants,
                skipNull = skipNull || samePath,
            )
        val scope = descriptor?.scope ?: GenericValueConfigurationScope::class
        val receiver =
            descriptor?.create?.invoke(collection)
                ?: collection.field(
                    RelativeFieldPattern(),
                    representation,
                    expected,
                    GenericValueConfigurationScope::class,
                    emptyMap(),
                    GenericValueExpressionsFactory,
                )
        checkedGeneratedScope<Scope>(scope, receiver).configure()
    }

    fun whenText(configure: TextConfiguration) {
        val receiver =
            RuntimeConfigurationBinding(
                target,
                state,
                path,
                RepresentationKind.Text,
                RepresentationKind.Text.expectedTemplate(expected),
                emptyMap(),
                TextExpressionsFactory,
                constants,
                skipNull,
            ).createScope(Text::class)
        receiver.configure()
    }

    private inner class PendingRule(
        private val predicate: ExpressionNode,
    ) : RuleDeclaration {
        override fun error(
            message: String,
            at: RelativeFieldPattern?,
        ) {
            val origin = RuleOrigin(target, state.nextRule++)
            val effectivePredicate =
                if (skipNull) {
                    ExpressionNode.Or(
                        ExpressionNode.Call(OperationId("typewriter.value.is_null"), listOf(VALUE_EXPRESSION.node)),
                        predicate,
                    )
                } else {
                    predicate
                }
            val diagnostic = diagnostic(message, at ?: path)
            state.recipes +=
                ConfigurationRecipe(
                    origin = origin,
                    relativePath = path,
                    representationCondition = representation,
                    rules = listOf(OwnedRule(RuleId(origin, 0), RuleDescriptor(effectivePredicate), diagnostic)),
                )
        }
    }

    private inner class PendingCheck(
        private val callback: Function1<Any?, Boolean>,
    ) : RuleDeclaration {
        override fun error(
            message: String,
            at: RelativeFieldPattern?,
        ) {
            val origin = RuleOrigin(target, state.nextRule++)
            state.checks +=
                CheckRecipe(
                    owner = origin,
                    inputs = listOf(CheckInput(target, path, expected, skipNull)),
                    predicate = UnboundNativePredicate(expected, callback),
                    diagnostic = diagnostic(message, at ?: path),
                )
        }
    }
}

internal class ConfigurationCollectionState(
    val recipes: MutableList<ConfigurationRecipe> = mutableListOf(),
    val checks: MutableList<CheckRecipe> = mutableListOf(),
    var initialization: InitializationPreference? = null,
    var nextRule: Int = 0,
)

private class UnboundNativePredicate(
    expected: TypeTemplate,
    private val callback: Function1<Any?, Boolean>,
) : RegisteredPredicate {
    override val inputTypes: List<TypeTemplate> = listOf(expected)

    override fun invoke(completeInputs: List<CompleteValue>): Boolean =
        error("A native predicate must be bound to the catalog native binding registry before execution.")

    fun bind(registry: NativeBindingRegistry): RegisteredPredicate = BoundNativePredicate(inputTypes, callback, registry)
}

private class BoundNativePredicate(
    override val inputTypes: List<TypeTemplate>,
    private val callback: Function1<Any?, Boolean>,
    private val registry: NativeBindingRegistry,
) : RegisteredPredicate {
    override fun invoke(completeInputs: List<CompleteValue>): Boolean {
        require(completeInputs.size == 1)
        return callback(registry.decode(completeInputs.single(), inputTypes.single()))
    }
}

internal fun CheckRecipe.bindNative(registry: NativeBindingRegistry): CheckRecipe =
    copy(predicate = (predicate as? UnboundNativePredicate)?.bind(registry) ?: predicate)

private fun RepresentationKind.expectedTemplate(fallback: TypeTemplate): TypeTemplate =
    when (this) {
        RepresentationKind.Unit -> TypeTemplate.Scalar(com.typewritermc.types.ScalarKind.Unit)
        RepresentationKind.Boolean -> TypeTemplate.Scalar(com.typewritermc.types.ScalarKind.Boolean)
        RepresentationKind.Text -> TypeTemplate.Scalar(com.typewritermc.types.ScalarKind.Text)
        RepresentationKind.Bytes -> TypeTemplate.Scalar(com.typewritermc.types.ScalarKind.Bytes)
        RepresentationKind.Decimal -> TypeTemplate.Scalar(com.typewritermc.types.ScalarKind.Decimal)
        RepresentationKind.Timestamp -> TypeTemplate.Scalar(com.typewritermc.types.ScalarKind.Timestamp)
        RepresentationKind.Duration -> TypeTemplate.Scalar(com.typewritermc.types.ScalarKind.Duration)
        else -> fallback
    }

private fun diagnostic(
    message: String,
    path: RelativeFieldPattern,
): DiagnosticTemplate =
    DiagnosticTemplate(
        code = "configuration.rule",
        message = message,
        severity = DiagnosticSeverity.Error,
        targets = listOf(path),
    )

private fun literal(
    value: Any?,
    expected: TypeTemplate,
    constants: PortableConstantEncoder?,
): ExpressionNode =
    ExpressionNode.Literal(
        when (value) {
            null -> {
                DataValue.Null
            }

            Unit -> {
                DataValue.Unit
            }

            is Boolean -> {
                DataValue.Boolean(value)
            }

            is Byte -> {
                DataValue.Integer(value.toLong().toBigInteger())
            }

            is Short -> {
                DataValue.Integer(value.toLong().toBigInteger())
            }

            is Int -> {
                DataValue.Integer(value.toLong().toBigInteger())
            }

            is Long -> {
                DataValue.Integer(value.toBigInteger())
            }

            is UByte -> {
                DataValue.Integer(value.toLong().toBigInteger())
            }

            is UShort -> {
                DataValue.Integer(value.toLong().toBigInteger())
            }

            is UInt -> {
                DataValue.Integer(value.toString().toBigInteger())
            }

            is ULong -> {
                DataValue.Integer(value.toString().toBigInteger())
            }

            is Float -> {
                DataValue.Float(value.toDouble())
            }

            is Double -> {
                DataValue.Float(value)
            }

            is java.math.BigInteger -> {
                DataValue.Integer(value)
            }

            is java.math.BigDecimal -> {
                DataValue.Decimal(value.toPlainString())
            }

            is String -> {
                DataValue.StringValue(value)
            }

            is ByteArray -> {
                DataValue.Bytes(value)
            }

            is kotlin.time.Instant -> {
                DataValue.Timestamp(value)
            }

            is kotlin.time.Duration -> {
                DataValue.Duration(value)
            }

            else -> {
                constants?.encode(expected, value)
                    ?: throw IllegalArgumentException("Unsupported portable rule constant ${value::class.qualifiedName}.")
            }
        },
    )

internal fun helperMessage(name: String): String =
    when (name) {
        "nonEmpty" -> "Value must not be empty"
        "nonBlank" -> "Text must not be blank"
        "minimumLength" -> "Value is shorter than allowed"
        "maximumLength" -> "Value is longer than allowed"
        "lengthBetween" -> "Value length is outside the allowed range"
        "singleLine" -> "Text must be on one line"
        "regex" -> "Text does not match the required pattern"
        "startsWith" -> "Text does not start with the required prefix"
        "endsWith" -> "Text does not end with the required suffix"
        "minimum" -> "Value is below its minimum"
        "maximum" -> "Value is above its maximum"
        "between" -> "Value is outside the allowed range"
        "positive" -> "Value must be positive"
        "nonNegative" -> "Value must not be negative"
        "unique" -> "Collection values must be unique"
        "notNull" -> "Value is required"
        else -> "Value does not satisfy $name"
    }

private val VALUE_EXPRESSION =
    Expr<Any?, MissingPolicy>(
        ExpressionNode.Read(ExpressionBindingId("configured_value"), ValuePath()),
    )
