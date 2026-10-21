package com.typewritermc.configuration

import com.typewritermc.authoring.CompleteValue
import com.typewritermc.checking.CheckInput
import com.typewritermc.checking.CheckRecipe
import com.typewritermc.checking.DiagnosticTemplate
import com.typewritermc.checking.RegisteredPredicate
import com.typewritermc.discovery.checkedGeneratedScope
import com.typewritermc.expression.Expr
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.expression.ExpressionFactory
import com.typewritermc.expression.LambdaFrame
import com.typewritermc.expression.MissingPolicy
import com.typewritermc.expression.field
import com.typewritermc.expression.inputExpression
import com.typewritermc.expression.local
import com.typewritermc.expression.portableRegexValidationError
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.bytes
import com.typewritermc.types.duration
import com.typewritermc.types.field
import com.typewritermc.types.integer
import com.typewritermc.types.requirePortable
import com.typewritermc.types.template
import com.typewritermc.types.timestamp
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.expression.BoundDirection
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.expression.RegexMatchMode
import skirout.editor.v1.expression.RuleUnaryOperation
import skirout.editor.v1.expression.SizeBoundMetric
import skirout.editor.v1.expression.SizeRangeMetric
import skirout.editor.v1.expression.TextCompareOperation
import skirout.editor.v1.expression.TimestampBoundDirection
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.RuleId
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeTemplate
import kotlin.reflect.KClass

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
        this(target, ConfigurationCollectionState(), RelativeFieldPattern(), constants, skipNull = false)

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
        return PendingRule(receiver.callback().toNode())
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
        val nodes = listOf(VALUE_EXPRESSION.toNode()) + arguments.map { literal(it, expected, constants) }
        val predicate = operation.expression(nodes)
        PendingRule(predicate).error(message)
    }

    fun <Expressions> uniqueBy(callback: Expressions.() -> Expr<*, MissingPolicy>) {
        val frame = LambdaFrame(1)
        val factory = nested[FieldPatternSegment.Items]?.expressions ?: GenericValueExpressionsFactory
        val receiver = checkedGeneratedScope<Expressions>(factory.scope, factory.create(local<Any?>(frame, 0)))
        val body = receiver.callback()
        val predicate =
            Expr<Boolean, com.typewritermc.expression.MayBeMissing> { outer ->
                ExpressionNode.createUniqueBy(source = VALUE_EXPRESSION.lower(outer), body = body.lower(outer.enter(frame)))
            }
        PendingRule(predicate.toNode()).error("Collection values must have unique keys")
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
            val origin = RuleOrigin(owner = target, ordinal = state.nextRule++)
            val effectivePredicate =
                if (skipNull) {
                    ExpressionNode.createOr(
                        left = ExpressionNode.IsNullWrapper(VALUE_EXPRESSION.toNode()),
                        right = predicate,
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
                    rules = listOf(OwnedRule(RuleId(origin = origin, localIndex = 0), RuleDescriptor(effectivePredicate), diagnostic)),
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
        RepresentationKind.Unit -> ScalarKind.UNIT.template
        RepresentationKind.Boolean -> ScalarKind.BOOLEAN.template
        RepresentationKind.Text -> ScalarKind.TEXT.template
        RepresentationKind.Bytes -> ScalarKind.BYTES.template
        RepresentationKind.Decimal -> ScalarKind.DECIMAL.template
        RepresentationKind.Timestamp -> ScalarKind.TIMESTAMP.template
        RepresentationKind.Duration -> ScalarKind.DURATION.template
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

private fun literal(
    value: Any?,
    expected: TypeTemplate,
    constants: PortableConstantEncoder?,
): ExpressionNode =
    ExpressionNode.LiteralWrapper(
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
        }.requirePortable(),
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

private val VALUE_EXPRESSION = inputExpression<Any?, MissingPolicy>(ExpressionBindingId("configured_value"))

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

private fun ConfigurationRuleHelper.expression(nodes: List<ExpressionNode>): ExpressionNode {
    val source = nodes.first()

    fun argument(index: Int) = nodes[index + 1]
    return when (this) {
        ConfigurationRuleHelper.NON_EMPTY -> {
            ExpressionNode.createRuleUnary(operation = RuleUnaryOperation.NON_EMPTY, source = source)
        }

        ConfigurationRuleHelper.NON_BLANK -> {
            ExpressionNode.createRuleUnary(operation = RuleUnaryOperation.NON_BLANK, source = source)
        }

        ConfigurationRuleHelper.SINGLE_LINE -> {
            ExpressionNode.createRuleUnary(operation = RuleUnaryOperation.SINGLE_LINE, source = source)
        }

        ConfigurationRuleHelper.POSITIVE -> {
            ExpressionNode.createRuleUnary(operation = RuleUnaryOperation.POSITIVE, source = source)
        }

        ConfigurationRuleHelper.NON_NEGATIVE -> {
            ExpressionNode.createRuleUnary(operation = RuleUnaryOperation.NON_NEGATIVE, source = source)
        }

        ConfigurationRuleHelper.UNIQUE -> {
            ExpressionNode.createRuleUnary(operation = RuleUnaryOperation.UNIQUE, source = source)
        }

        ConfigurationRuleHelper.NOT_NULL -> {
            ExpressionNode.createRuleUnary(operation = RuleUnaryOperation.NOT_NULL, source = source)
        }

        ConfigurationRuleHelper.OPAQUE -> {
            ExpressionNode.createRuleUnary(operation = RuleUnaryOperation.OPAQUE, source = source)
        }

        ConfigurationRuleHelper.MINIMUM_LENGTH -> {
            ExpressionNode.createRuleSizeBound(
                metric = SizeBoundMetric.TEXT_LENGTH,
                direction = BoundDirection.MINIMUM,
                source = source,
                bound = argument(0),
            )
        }

        ConfigurationRuleHelper.MAXIMUM_LENGTH -> {
            ExpressionNode.createRuleSizeBound(
                metric = SizeBoundMetric.TEXT_LENGTH,
                direction = BoundDirection.MAXIMUM,
                source = source,
                bound = argument(0),
            )
        }

        ConfigurationRuleHelper.MINIMUM_LINES -> {
            ExpressionNode.createRuleSizeBound(
                metric = SizeBoundMetric.TEXT_LINES,
                direction = BoundDirection.MINIMUM,
                source = source,
                bound = argument(0),
            )
        }

        ConfigurationRuleHelper.MAXIMUM_LINES -> {
            ExpressionNode.createRuleSizeBound(
                metric = SizeBoundMetric.TEXT_LINES,
                direction = BoundDirection.MAXIMUM,
                source = source,
                bound = argument(0),
            )
        }

        ConfigurationRuleHelper.MINIMUM_ITEMS -> {
            ExpressionNode.createRuleSizeBound(
                metric = SizeBoundMetric.COLLECTION_ITEMS,
                direction = BoundDirection.MINIMUM,
                source = source,
                bound = argument(0),
            )
        }

        ConfigurationRuleHelper.MAXIMUM_ITEMS -> {
            ExpressionNode.createRuleSizeBound(
                metric = SizeBoundMetric.COLLECTION_ITEMS,
                direction = BoundDirection.MAXIMUM,
                source = source,
                bound = argument(0),
            )
        }

        ConfigurationRuleHelper.LENGTH_BETWEEN -> {
            ExpressionNode.createRuleSizeRange(
                metric = SizeRangeMetric.TEXT_LENGTH,
                source = source,
                minimum = argument(0),
                maximum = argument(1),
            )
        }

        ConfigurationRuleHelper.ITEMS_BETWEEN -> {
            ExpressionNode.createRuleSizeRange(
                metric = SizeRangeMetric.COLLECTION_ITEMS,
                source = source,
                minimum = argument(0),
                maximum = argument(1),
            )
        }

        ConfigurationRuleHelper.MINIMUM -> {
            ExpressionNode.createRuleNumericBound(
                direction = BoundDirection.MINIMUM,
                source = source,
                bound = argument(0),
                inclusive =
                    nodes.getOrNull(2) ?: ExpressionNode.LiteralWrapper(
                        skirout.editor.v1.type_catalog.DataValue
                            .BooleanWrapper(true),
                    ),
            )
        }

        ConfigurationRuleHelper.MAXIMUM -> {
            ExpressionNode.createRuleNumericBound(
                direction = BoundDirection.MAXIMUM,
                source = source,
                bound = argument(0),
                inclusive =
                    nodes.getOrNull(2) ?: ExpressionNode.LiteralWrapper(
                        skirout.editor.v1.type_catalog.DataValue
                            .BooleanWrapper(true),
                    ),
            )
        }

        ConfigurationRuleHelper.BETWEEN -> {
            ExpressionNode.createRuleNumericRange(source = source, minimum = argument(0), maximum = argument(1))
        }

        ConfigurationRuleHelper.MULTIPLE_OF -> {
            ExpressionNode.createRuleMultipleOf(source = source, divisor = argument(0))
        }

        ConfigurationRuleHelper.MAXIMUM_SCALE -> {
            ExpressionNode.createRuleMaximumScale(source = source, scale = argument(0))
        }

        ConfigurationRuleHelper.REGEX -> {
            ExpressionNode.createRegexTest(mode = RegexMatchMode.FULL_MATCH, source = source, pattern = argument(0))
        }

        ConfigurationRuleHelper.STARTS_WITH -> {
            ExpressionNode.createTextCompare(operation = TextCompareOperation.STARTS_WITH, source = source, other = argument(0))
        }

        ConfigurationRuleHelper.ENDS_WITH -> {
            ExpressionNode.createTextCompare(operation = TextCompareOperation.ENDS_WITH, source = source, other = argument(0))
        }

        ConfigurationRuleHelper.NOT_BEFORE -> {
            ExpressionNode.createRuleTimestampBound(direction = TimestampBoundDirection.NOT_BEFORE, source = source, bound = argument(0))
        }

        ConfigurationRuleHelper.NOT_AFTER -> {
            ExpressionNode.createRuleTimestampBound(direction = TimestampBoundDirection.NOT_AFTER, source = source, bound = argument(0))
        }

        ConfigurationRuleHelper.ONE_OF -> {
            require(nodes.size >= 2) { "An allowed value rule requires at least one candidate" }
            ExpressionNode.createRuleOneOf(source = source, firstCandidate = argument(0), remainingCandidates = nodes.drop(2))
        }
    }
}
