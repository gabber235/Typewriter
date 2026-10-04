package com.typewritermc.configuration

import com.typewritermc.authoring.CompleteValue
import com.typewritermc.authoring.ValuePath
import com.typewritermc.checking.CheckInput
import com.typewritermc.checking.CheckRecipe
import com.typewritermc.checking.DiagnosticSeverity
import com.typewritermc.checking.DiagnosticTemplate
import com.typewritermc.checking.RegisteredPredicate
import com.typewritermc.expression.Expr
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.expression.MissingPolicy
import com.typewritermc.expression.OperationId
import com.typewritermc.expression.field
import com.typewritermc.expression.portableRegexValidationError
import com.typewritermc.presentation.ExpressionNode
import com.typewritermc.types.DataValue
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeTemplate
import java.lang.reflect.InvocationHandler
import java.lang.reflect.Method
import java.lang.reflect.Proxy
import kotlin.reflect.KClass

class DefaultConfigurationCollectionScope private constructor(
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
        expressions: KClass<*>,
    ): S {
        require(scope.java.isInterface) { "Configuration scopes must be interfaces." }
        val interfaces = (CONFIGURATION_INTERFACES + scope.java).distinct().toTypedArray()
        val absolute = RelativeFieldPattern(prefix.segments + path.segments)
        val handler = FieldScopeHandler(absolute, representation, expected, nested, expressions, skipNull)
        @Suppress("UNCHECKED_CAST")
        return Proxy.newProxyInstance(scope.java.classLoader, interfaces, handler) as S
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

    private inner class FieldScopeHandler(
        private val path: RelativeFieldPattern,
        private val representation: RepresentationKind,
        private val expected: TypeTemplate,
        private val nested: Map<FieldPatternSegment, NestedConfigurationScope>,
        private val expressions: KClass<*>,
        private val skipNull: Boolean,
    ) : InvocationHandler {
        override fun invoke(
            proxy: Any,
            method: Method,
            arguments: Array<out Any?>?,
        ): Any? {
            val values = arguments.orEmpty()
            return when (method.name) {
                "rule" -> declarePortable(values.single() as Function1<Any, *>)
                "check" -> declareNative(values.single() as Function1<Any?, Boolean>)
                "oneOf" -> declareHelper("one_of", values.flatMap(::spread), "Value must be one of the declared choices")
                "uniqueBy" -> declareUniqueBy(values.single())
                "whenPresent" -> invokeNested(values.single(), FieldPatternSegment.Values, samePath = true)
                "items" -> invokeNested(values.single(), FieldPatternSegment.Items)
                "keys" -> invokeNested(values.single(), FieldPatternSegment.Keys)
                "values" -> invokeNested(values.single(), FieldPatternSegment.Values)
                "whenText" -> invokeConditional(values.single(), RepresentationKind.Text, Text::class)
                "toString" -> "ConfigurationScope($target:$path)"
                "hashCode" -> System.identityHashCode(proxy)
                "equals" -> proxy === values.singleOrNull()
                else -> declareHelper(method.name, values.flatMap(::spread), helperMessage(method.name))
            }
        }

        private fun declarePortable(callback: Function1<Any, *>): RuleDeclaration {
            val expression =
                callback.invoke(generatedExpressionScope(expressions, VALUE_EXPRESSION)) as? Expr<*, *>
                    ?: throw IllegalArgumentException("A configuration rule must return an expression.")
            return PendingRule(expression.node)
        }

        private fun declareNative(callback: Function1<Any?, Boolean>): RuleDeclaration = PendingCheck(callback)

        private fun declareHelper(
            operation: String,
            arguments: List<Any?>,
            message: String,
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

        private fun declareUniqueBy(callback: Any?) {
            val item = ExpressionBindingId("configured_item_${state.nextRule}")

            @Suppress("UNCHECKED_CAST")
            val body =
                (callback as Function1<Any, *>)
                    .invoke(
                        generatedExpressionScope(
                            nested[FieldPatternSegment.Items]?.expressions ?: GenericValueExpressions::class,
                            Expr<Any?, MissingPolicy>(ExpressionNode.Read(item, ValuePath())),
                        ),
                    )
                    as? Expr<*, *>
                    ?: throw IllegalArgumentException("A uniqueBy selector must return an expression.")
            PendingRule(
                ExpressionNode.Collection(
                    operation = OperationId("typewriter.collection.unique_by"),
                    input = VALUE_EXPRESSION.node,
                    bindings = listOf(item),
                    arguments = emptyList(),
                    body = body.node,
                ),
            ).error("Collection values must have unique keys")
        }

        private fun invokeNested(
            callback: Any?,
            segment: FieldPatternSegment,
            samePath: Boolean = false,
        ) {
            val nestedPath = if (samePath) path else RelativeFieldPattern(path.segments + segment)
            val descriptor = nested[segment]
            val receiver =
                descriptor?.create?.invoke(
                    DefaultConfigurationCollectionScope(
                        target,
                        state,
                        nestedPath,
                        constants,
                        skipNull = skipNull || samePath,
                    ),
                )
                    ?: Proxy.newProxyInstance(
                        Field::class.java.classLoader,
                        CONFIGURATION_INTERFACES.toTypedArray(),
                        FieldScopeHandler(
                            nestedPath,
                            descriptor?.representation ?: representation,
                            descriptor?.expected ?: expected,
                            emptyMap(),
                            descriptor?.expressions ?: GenericValueExpressions::class,
                            skipNull = samePath,
                        ),
                    )
            @Suppress("UNCHECKED_CAST")
            (callback as Function1<Any, Unit>).invoke(receiver)
        }

        private fun invokeConditional(
            callback: Any?,
            condition: RepresentationKind,
            scope: KClass<*>,
        ) {
            val receiver =
                Proxy.newProxyInstance(
                    scope.java.classLoader,
                    (CONFIGURATION_INTERFACES + scope.java).distinct().toTypedArray(),
                    FieldScopeHandler(
                        path,
                        condition,
                        condition.expectedTemplate(expected),
                        emptyMap(),
                        expressions,
                        skipNull,
                    ),
                )
            @Suppress("UNCHECKED_CAST")
            (callback as Function1<Any, Unit>).invoke(receiver)
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
}

private class ConfigurationCollectionState(
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

private fun spread(value: Any?): List<Any?> =
    when (value) {
        is Array<*> -> value.toList()
        is BooleanArray -> value.toList()
        is ByteArray -> value.toList()
        is ShortArray -> value.toList()
        is IntArray -> value.toList()
        is LongArray -> value.toList()
        is FloatArray -> value.toList()
        is DoubleArray -> value.toList()
        is Iterable<*> -> value.toList()
        else -> listOf(value)
    }

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

private fun helperMessage(name: String): String =
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

fun <S : Any> generatedExpressionScope(
    scope: KClass<S>,
    value: Expr<*, out MissingPolicy>,
): S =
    Proxy.newProxyInstance(
        scope.java.classLoader,
        (
            listOf(
                scope.java,
                GenericValueExpressions::class.java,
                TextExpressions::class.java,
                NumberExpressions::class.java,
                BytesExpressions::class.java,
                BooleanExpressions::class.java,
                EnumExpressions::class.java,
                NullableExpressions::class.java,
                ListExpressions::class.java,
                SetExpressions::class.java,
                MapExpressions::class.java,
                ItemExpressions::class.java,
                LinkExpressions::class.java,
                TimestampExpressions::class.java,
                DurationExpressions::class.java,
                ColorExpressions::class.java,
            ).distinct()
        ).toTypedArray(),
    ) { proxy, method, arguments ->
        val field = method.getAnnotation(ExpressionField::class.java)
        when {
            field != null -> {
                value.field<Any?>(field.name)
            }

            method.name == "getValue" -> {
                value
            }

            method.name == "toString" -> {
                "ConfiguredValueExpressions"
            }

            method.name == "hashCode" -> {
                System.identityHashCode(proxy)
            }

            method.name == "equals" -> {
                proxy === arguments?.singleOrNull()
            }

            else -> {
                throw IllegalArgumentException("Unsupported expression member ${method.name}.")
            }
        }
    } as S

private val CONFIGURATION_INTERFACES =
    listOf(
        Field::class.java,
        Text::class.java,
        Number::class.java,
        Integer::class.java,
        Real::class.java,
        Decimal::class.java,
        Bytes::class.java,
        BooleanField::class.java,
        EnumField::class.java,
        RecordField::class.java,
        NullableField::class.java,
        LinkField::class.java,
        TimestampField::class.java,
        DurationField::class.java,
        ColorField::class.java,
        CollectionField::class.java,
        ListField::class.java,
        SetField::class.java,
        MapField::class.java,
        GenericValueConfigurationScope::class.java,
    )
