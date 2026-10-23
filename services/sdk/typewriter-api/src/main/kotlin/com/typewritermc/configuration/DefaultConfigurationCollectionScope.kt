package com.typewritermc.configuration

import com.typewritermc.authoring.CompleteValue
import com.typewritermc.checking.CheckInput
import com.typewritermc.checking.CheckRecipe
import com.typewritermc.checking.RegisteredPredicate
import com.typewritermc.configuration.root
import com.typewritermc.discovery.checkedGeneratedScope
import com.typewritermc.expression.Expr
import com.typewritermc.expression.ExpressionFactory
import com.typewritermc.expression.Handled
import com.typewritermc.expression.MissingPolicy
import com.typewritermc.expression.inputExpression
import com.typewritermc.expression.isNull
import com.typewritermc.expression.length
import com.typewritermc.expression.operations.portableRegexValidationError
import com.typewritermc.expression.or
import com.typewritermc.expression.portableLiteral
import com.typewritermc.expression.shortcuts.endsWith
import com.typewritermc.expression.shortcuts.gt
import com.typewritermc.expression.shortcuts.gte
import com.typewritermc.expression.shortcuts.inRange
import com.typewritermc.expression.shortcuts.isNotBlank
import com.typewritermc.expression.shortcuts.isNotEmpty
import com.typewritermc.expression.shortcuts.isNotNull
import com.typewritermc.expression.shortcuts.isSingleLine
import com.typewritermc.expression.shortcuts.lineCount
import com.typewritermc.expression.shortcuts.lt
import com.typewritermc.expression.shortcuts.lte
import com.typewritermc.expression.shortcuts.matches
import com.typewritermc.expression.shortcuts.maximumScale
import com.typewritermc.expression.shortcuts.multipleOf
import com.typewritermc.expression.shortcuts.nonNegative
import com.typewritermc.expression.shortcuts.oneOf
import com.typewritermc.expression.shortcuts.opaque
import com.typewritermc.expression.shortcuts.positive
import com.typewritermc.expression.shortcuts.startsWith
import com.typewritermc.expression.shortcuts.unique
import com.typewritermc.expression.shortcuts.uniqueBy
import com.typewritermc.expression.size
import com.typewritermc.expression.toByteList
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.bytes
import com.typewritermc.types.duration
import com.typewritermc.types.integer
import com.typewritermc.types.template
import com.typewritermc.types.timestamp
import skirout.editor.v1.catalog.ConfigurationRecipe
import skirout.editor.v1.catalog.OwnedRule
import skirout.editor.v1.catalog.RepresentationKind
import skirout.editor.v1.catalog.RuleDescriptor
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.diagnostic.DiagnosticTemplate
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.FieldPatternSegment
import skirout.editor.v1.type_catalog.RelativeFieldPattern
import skirout.editor.v1.type_catalog.RuleId
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeTemplate
import java.math.BigDecimal
import java.math.BigInteger
import kotlin.reflect.KClass
import kotlin.time.Duration

/**
 * Collects a provider's portable recipes and native checks under one declaration owner.
 * Nested field scopes share rule ordinals and collected state while extending relative paths. Collection records
 * declarations without evaluating authored values; native predicates are bound to a catalog before execution.
 */
class DefaultConfigurationCollectionScope internal constructor(
    private val target: TypeDefinitionId,
    private val state: ConfigurationCollectionState,
    private val prefix: RelativeFieldPattern,
    private val constants: PortableConstantEncoder?,
    private val skipNull: Boolean,
) : ConfigurationCollectionScope {
    constructor(target: TypeDefinitionId, constants: PortableConstantEncoder? = null) :
        this(target, ConfigurationCollectionState(), RelativeFieldPattern.root, constants, skipNull = false)

    override fun <S : Any> field(
        path: RelativeFieldPattern,
        representation: RepresentationKind,
        expected: TypeTemplate,
        scope: KClass<S>,
        nested: Map<FieldPatternSegment, NestedConfigurationScope>,
        expressions: ExpressionFactory<*>,
    ): S {
        val absolute = RelativeFieldPattern(segments = prefix.segments + path.segments)
        val binding =
            RuntimeConfigurationBinding(target, state, absolute, representation, expected, nested, expressions, constants, skipNull)
        return binding.createScope(scope)
    }

    override fun nested(path: RelativeFieldPattern): ConfigurationCollectionScope =
        DefaultConfigurationCollectionScope(
            target,
            state,
            RelativeFieldPattern(segments = prefix.segments + path.segments),
            constants,
            skipNull,
        )

    override fun collected(): CollectedConfiguration = CollectedConfiguration(state.recipes.toList(), state.checks.toList())
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
        return PendingRule(receiver.callback())
    }

    fun <Value> check(callback: (Value) -> Boolean): RuleDeclaration =
        PendingCheck { value ->
            @Suppress("UNCHECKED_CAST")
            callback(value as Value)
        }

    fun helper(
        operation: ConfigurationRuleHelper,
        arguments: List<Any?>,
        message: String = helperMessage(operation),
    ) {
        if (operation == ConfigurationRuleHelper.REGEX) {
            val pattern =
                arguments.singleOrNull() as? String
                    ?: throw IllegalArgumentException("A regular expression rule requires one text pattern.")
            pattern.portableRegexValidationError()?.let { reason -> throw IllegalArgumentException(reason) }
        }
        PendingRule(operation.predicate(representation, arguments) { constant(it, expected, constants) }).error(message)
    }

    fun <Expressions> uniqueBy(callback: Expressions.() -> Expr<*, MissingPolicy>) {
        val factory = nested[FieldPatternSegment.ITEMS]?.expressions ?: GenericValueExpressionsFactory
        val predicate =
            VALUE_EXPRESSION.typed<List<Any?>>().uniqueBy {
                checkedGeneratedScope<Expressions>(factory.scope, factory.create(this)).callback().typed<Any?>()
            }
        PendingRule(predicate).error("Collection values must have unique keys")
    }

    fun <Scope> nested(
        configure: Configuration<Scope>,
        segment: FieldPatternSegment,
        samePath: Boolean = false,
    ) {
        val nestedPath = if (samePath) path else RelativeFieldPattern(segments = path.segments + segment)
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
                    RelativeFieldPattern.root,
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
                RepresentationKind.TEXT,
                RepresentationKind.TEXT.expectedTemplate(expected),
                emptyMap(),
                TextExpressionsFactory,
                constants,
                skipNull,
            ).createScope(Text::class)
        receiver.configure()
    }

    private inner class PendingRule(
        private val predicate: Expr<Boolean, MissingPolicy>,
    ) : RuleDeclaration {
        override fun error(
            message: String,
            at: RelativeFieldPattern?,
        ) {
            val origin = RuleOrigin(owner = target, ordinal = state.nextRule++)
            val effectivePredicate = if (skipNull) VALUE_EXPRESSION.isNull() or predicate else predicate
            val diagnostic = diagnostic(message, at ?: path)
            state.recipes +=
                ConfigurationRecipe(
                    origin = origin,
                    relativePath = path,
                    representationCondition = representation,
                    rules =
                        listOf(
                            OwnedRule(
                                id = RuleId(origin = origin, localIndex = 0),
                                descriptor = RuleDescriptor(predicate = effectivePredicate.toNode()),
                                diagnostic = diagnostic,
                            ),
                        ),
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
            val origin = RuleOrigin(owner = target, ordinal = state.nextRule++)
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
        RepresentationKind.UNIT -> ScalarKind.UNIT.template
        RepresentationKind.BOOLEAN -> ScalarKind.BOOLEAN.template
        RepresentationKind.TEXT -> ScalarKind.TEXT.template
        RepresentationKind.BYTES -> ScalarKind.BYTES.template
        RepresentationKind.DECIMAL -> ScalarKind.DECIMAL.template
        RepresentationKind.TIMESTAMP -> ScalarKind.TIMESTAMP.template
        RepresentationKind.DURATION -> ScalarKind.DURATION.template
        else -> fallback
    }

private fun diagnostic(
    message: String,
    path: RelativeFieldPattern,
): DiagnosticTemplate =
    DiagnosticTemplate(
        code = "configuration.rule",
        message = message,
        severity = DiagnosticSeverity.ERROR,
        targets = listOf(path),
    )

/** A rule constant as a literal; catalog values beyond the scalars go through the provider's [constants]. */
private fun constant(
    value: Any?,
    expected: TypeTemplate,
    constants: PortableConstantEncoder?,
): Expr<Any?, Handled> =
    portableLiteral(
        when (value) {
            null -> {
                DataValue.NULL
            }

            Unit -> {
                DataValue.UNIT
            }

            is Boolean -> {
                DataValue.BooleanWrapper(value)
            }

            is Byte -> {
                DataValue.integer(value.toLong().toBigInteger())
            }

            is Short -> {
                DataValue.integer(value.toLong().toBigInteger())
            }

            is Int -> {
                DataValue.integer(value.toLong().toBigInteger())
            }

            is Long -> {
                DataValue.integer(value.toBigInteger())
            }

            is UByte -> {
                DataValue.integer(value.toLong().toBigInteger())
            }

            is UShort -> {
                DataValue.integer(value.toLong().toBigInteger())
            }

            is UInt -> {
                DataValue.integer(value.toString().toBigInteger())
            }

            is ULong -> {
                DataValue.integer(value.toString().toBigInteger())
            }

            is Float -> {
                DataValue.FloatWrapper(value.toDouble())
            }

            is Double -> {
                DataValue.FloatWrapper(value)
            }

            is java.math.BigInteger -> {
                DataValue.integer(value)
            }

            is java.math.BigDecimal -> {
                DataValue.DecimalWrapper(value.toPlainString())
            }

            is String -> {
                DataValue.StringValueWrapper(value)
            }

            is ByteArray -> {
                DataValue.bytes(value)
            }

            is kotlin.time.Instant -> {
                DataValue.timestamp(value)
            }

            is kotlin.time.Duration -> {
                DataValue.duration(value)
            }

            else -> {
                constants?.encode(expected, value)
                    ?: throw IllegalArgumentException("Unsupported portable rule constant ${value::class.qualifiedName}.")
            }
        },
    )

internal fun helperMessage(name: ConfigurationRuleHelper): String =
    when (name) {
        ConfigurationRuleHelper.NON_EMPTY -> "Value must not be empty"
        ConfigurationRuleHelper.NON_BLANK -> "Text must not be blank"
        ConfigurationRuleHelper.MINIMUM_LENGTH -> "Value is shorter than allowed"
        ConfigurationRuleHelper.MAXIMUM_LENGTH -> "Value is longer than allowed"
        ConfigurationRuleHelper.LENGTH_BETWEEN -> "Value length is outside the allowed range"
        ConfigurationRuleHelper.SINGLE_LINE -> "Text must be on one line"
        ConfigurationRuleHelper.REGEX -> "Text does not match the required pattern"
        ConfigurationRuleHelper.STARTS_WITH -> "Text does not start with the required prefix"
        ConfigurationRuleHelper.ENDS_WITH -> "Text does not end with the required suffix"
        ConfigurationRuleHelper.MINIMUM -> "Value is below its minimum"
        ConfigurationRuleHelper.MAXIMUM -> "Value is above its maximum"
        ConfigurationRuleHelper.BETWEEN -> "Value is outside the allowed range"
        ConfigurationRuleHelper.POSITIVE -> "Value must be positive"
        ConfigurationRuleHelper.NON_NEGATIVE -> "Value must not be negative"
        ConfigurationRuleHelper.UNIQUE -> "Collection values must be unique"
        ConfigurationRuleHelper.NOT_NULL -> "Value is required"
        else -> "Value does not satisfy $name"
    }

private val VALUE_EXPRESSION = inputExpression<Any?, MissingPolicy>(ExpressionBindingId(value = "configured_value"))

internal enum class ConfigurationRuleHelper {
    BETWEEN,
    ENDS_WITH,
    ITEMS_BETWEEN,
    LENGTH_BETWEEN,
    MAXIMUM,
    MAXIMUM_ITEMS,
    MAXIMUM_LENGTH,
    MAXIMUM_LINES,
    MAXIMUM_SCALE,
    MINIMUM,
    MINIMUM_ITEMS,
    MINIMUM_LENGTH,
    MINIMUM_LINES,
    MULTIPLE_OF,
    NON_BLANK,
    NON_EMPTY,
    NON_NEGATIVE,
    NOT_AFTER,
    NOT_BEFORE,
    NOT_NULL,
    ONE_OF,
    OPAQUE,
    POSITIVE,
    REGEX,
    SINGLE_LINE,
    STARTS_WITH,
    UNIQUE,
}

/**
 * The predicate of this helper over the configured value, built from the shortcuts. [representation] selects the
 * measure of size helpers (code points of text, bytes, items) and the numeric family of sign helpers; [constant]
 * encodes the helper's arguments as literals.
 */
private fun ConfigurationRuleHelper.predicate(
    representation: RepresentationKind,
    arguments: List<Any?>,
    constant: (Any?) -> Expr<Any?, Handled>,
): Expr<Boolean, MissingPolicy> {
    val value = VALUE_EXPRESSION

    fun argument(index: Int): Expr<Any?, MissingPolicy> = constant(arguments[index])

    fun count(index: Int): Int = arguments[index] as Int

    return when (this) {
        ConfigurationRuleHelper.NON_EMPTY -> {
            when (representation) {
                RepresentationKind.TEXT -> value.typed<String>().isNotEmpty()
                RepresentationKind.MAP -> value.typed<Map<Any?, Any?>>().isNotEmpty()
                else -> value.typed<Collection<Any?>>().isNotEmpty()
            }
        }

        ConfigurationRuleHelper.NON_BLANK -> {
            value.typed<String>().isNotBlank()
        }

        ConfigurationRuleHelper.SINGLE_LINE -> {
            value.typed<String>().isSingleLine()
        }

        ConfigurationRuleHelper.MINIMUM_LENGTH -> {
            value.length(representation) gte count(0)
        }

        ConfigurationRuleHelper.MAXIMUM_LENGTH -> {
            value.length(representation) lte count(0)
        }

        ConfigurationRuleHelper.LENGTH_BETWEEN -> {
            value.length(representation).inRange(count(0), count(1))
        }

        ConfigurationRuleHelper.MINIMUM_LINES -> {
            value.typed<String>().lineCount() gte count(0)
        }

        ConfigurationRuleHelper.MAXIMUM_LINES -> {
            value.typed<String>().lineCount() lte count(0)
        }

        ConfigurationRuleHelper.MINIMUM_ITEMS -> {
            value.itemCount(representation) gte count(0)
        }

        ConfigurationRuleHelper.MAXIMUM_ITEMS -> {
            value.itemCount(representation) lte count(0)
        }

        ConfigurationRuleHelper.ITEMS_BETWEEN -> {
            value.itemCount(representation).inRange(count(0), count(1))
        }

        ConfigurationRuleHelper.MINIMUM -> {
            if (arguments.getOrNull(1) as? Boolean ?: true) value gte argument(0) else value gt argument(0)
        }

        ConfigurationRuleHelper.MAXIMUM -> {
            if (arguments.getOrNull(1) as? Boolean ?: true) value lte argument(0) else value lt argument(0)
        }

        ConfigurationRuleHelper.BETWEEN -> {
            value.inRange(argument(0), argument(1))
        }

        ConfigurationRuleHelper.POSITIVE -> {
            when (representation) {
                RepresentationKind.FLOAT -> value.typed<Double>().positive()
                RepresentationKind.DECIMAL -> value.typed<BigDecimal>().positive()
                else -> value.typed<BigInteger>().positive()
            }
        }

        ConfigurationRuleHelper.NON_NEGATIVE -> {
            when (representation) {
                RepresentationKind.FLOAT -> value.typed<Double>().nonNegative()
                RepresentationKind.DECIMAL -> value.typed<BigDecimal>().nonNegative()
                RepresentationKind.DURATION -> value.typed<Duration>().nonNegative()
                else -> value.typed<BigInteger>().nonNegative()
            }
        }

        ConfigurationRuleHelper.MULTIPLE_OF -> {
            value.typed<kotlin.Number>().multipleOf(arguments[0].portableNumber())
        }

        ConfigurationRuleHelper.MAXIMUM_SCALE -> {
            value.typed<BigDecimal>().maximumScale(count(0))
        }

        ConfigurationRuleHelper.UNIQUE -> {
            value.typed<Collection<Any?>>().unique()
        }

        ConfigurationRuleHelper.NOT_NULL -> {
            value.isNotNull()
        }

        ConfigurationRuleHelper.OPAQUE -> {
            value.typed<com.typewritermc.types.Color>().opaque()
        }

        ConfigurationRuleHelper.REGEX -> {
            value.typed<String>().matches(arguments[0] as String)
        }

        ConfigurationRuleHelper.STARTS_WITH -> {
            value.typed<String>().startsWith(arguments[0] as String)
        }

        ConfigurationRuleHelper.ENDS_WITH -> {
            value.typed<String>().endsWith(arguments[0] as String)
        }

        ConfigurationRuleHelper.NOT_BEFORE -> {
            value gte argument(0)
        }

        ConfigurationRuleHelper.NOT_AFTER -> {
            value lte argument(0)
        }

        ConfigurationRuleHelper.ONE_OF -> {
            require(arguments.isNotEmpty()) { "An allowed value rule requires at least one candidate" }
            value.oneOf(*arguments.indices.map(::argument).toTypedArray())
        }
    }
}

/** The code points of text, or the bytes of a byte string. */
private fun Expr<Any?, MissingPolicy>.length(representation: RepresentationKind): Expr<Int, MissingPolicy> =
    if (representation == RepresentationKind.BYTES) typed<ByteArray>().toByteList().size else typed<String>().length

/** The entries of a map, or the items of a list or set. */
private fun Expr<Any?, MissingPolicy>.itemCount(representation: RepresentationKind): Expr<Int, MissingPolicy> =
    if (representation == RepresentationKind.MAP) typed<Map<Any?, Any?>>().size else typed<Collection<Any?>>().size

/** A divisor as a portable Kotlin number; unsigned constants become integers of the same value. */
private fun Any?.portableNumber(): kotlin.Number =
    when (this) {
        is UByte -> toLong()
        is UShort -> toLong()
        is UInt -> toLong()
        is ULong -> toString().toBigInteger()
        is kotlin.Number -> this
        else -> throw IllegalArgumentException("A multiple rule needs a numeric divisor.")
    }

/** This expression under the Kotlin type a shortcut is written for; the wire carries no Kotlin type. */
@Suppress("UNCHECKED_CAST")
private fun <T> Expr<*, MissingPolicy>.typed(): Expr<T, MissingPolicy> = this as Expr<T, MissingPolicy>
