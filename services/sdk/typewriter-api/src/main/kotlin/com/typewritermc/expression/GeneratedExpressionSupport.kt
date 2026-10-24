package com.typewritermc.expression

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.append
import com.typewritermc.authoring.root
import com.typewritermc.expression.operations.PortableOperationCatalog
import com.typewritermc.types.Color
import com.typewritermc.types.ColorDefinition
import com.typewritermc.types.Icon
import com.typewritermc.types.IconIconifyDefinition
import com.typewritermc.types.IconSvgDefinition
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ResourceIdDefinition
import com.typewritermc.types.duration
import com.typewritermc.types.integer
import com.typewritermc.types.listValue
import com.typewritermc.types.named
import com.typewritermc.types.record
import com.typewritermc.types.requirePortable
import com.typewritermc.types.timestamp
import com.typewritermc.types.use
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.ValuePath
import java.math.BigDecimal
import java.math.BigInteger
import kotlin.time.Duration
import kotlin.time.Instant

sealed interface MissingPolicy

sealed interface MayBeMissing : MissingPolicy

sealed interface Handled : MayBeMissing

internal class LambdaFrame(
    val arity: Int,
)

internal data class ExpressionEnvironment(
    val frames: List<LambdaFrame> = emptyList(),
    val depth: Int = 0,
) {
    fun descend(): ExpressionEnvironment {
        require(depth < PortableExpressionLimits.MAX_DEPTH) { "Expression lowering depth exceeded" }
        return copy(depth = depth + 1)
    }

    fun enter(frame: LambdaFrame): ExpressionEnvironment = copy(frames = frames + frame)

    fun address(
        frame: LambdaFrame,
        slot: Int,
    ): Int {
        require(slot in 0 until frame.arity) { "Invalid local expression slot" }
        return frames.asReversed().indexOfFirst { it === frame }.also {
            require(it >= 0) { "A local expression escaped its declaring lambda" }
        }
    }
}

/** A reusable authoring expression. Complete programs freeze their captured lexical scope through [toNode]. */
class Expr<T, out M : MissingPolicy> internal constructor(
    private val emit: (ExpressionEnvironment) -> ExpressionNode,
) : CallArgument() {
    internal fun lower(environment: ExpressionEnvironment): ExpressionNode = emit(environment.descend())

    override fun lowerArgument(environment: ExpressionEnvironment): ExpressionNode = lower(environment)

    fun toNode(): ExpressionNode = lower(ExpressionEnvironment())
}

internal fun <T> local(
    frame: LambdaFrame,
    slot: Int,
): Expr<T, MayBeMissing> =
    Expr { environment ->
        ExpressionNode.createLocal(
            depth = environment.address(frame, slot),
            slot = slot,
            path =
                skirout.editor.v1.type_catalog
                    .ValuePath(segments = emptyList()),
        )
    }

internal fun <T, M : MissingPolicy> inputExpression(
    binding: ExpressionBindingId,
    path: ValuePath = ValuePath.root,
): Expr<T, M> {
    val source =
        skirout.editor.v1.type_catalog
            .ExpressionBindingId(value = binding.value)
    val frozenPath = path
    return Expr { ExpressionNode.createInput(binding = source, path = frozenPath) }
}

/** Projects the field [name]; a projection of an input, local or field extends that projection's path. */
fun <V> Expr<*, out MissingPolicy>.field(name: String): Expr<V, MayBeMissing> {
    val source = this
    val segment = PathSegment.createField(name = name)
    return Expr { environment ->
        when (val expression = source.lower(environment)) {
            is ExpressionNode.InputWrapper -> {
                ExpressionNode.InputWrapper(expression.value.copy(path = expression.value.path.append(segment)))
            }

            is ExpressionNode.LocalWrapper -> {
                ExpressionNode.LocalWrapper(expression.value.copy(path = expression.value.path.append(segment)))
            }

            is ExpressionNode.FieldWrapper -> {
                ExpressionNode.FieldWrapper(expression.value.copy(path = expression.value.path.append(segment)))
            }

            else -> {
                ExpressionNode.createField(source = expression, path = ValuePath(segments = listOf(segment)))
            }
        }
    }
}

/** Whether an item of [source] satisfies [predicate], written against the item's generated expressions. */
@GeneratedSdkApi
fun <T, S : Any> collectionAny(
    source: Expr<List<T>, out MissingPolicy>,
    factory: ExpressionFactory<S>,
    predicate: S.() -> Expr<Boolean, out MissingPolicy>,
): Expr<Boolean, MayBeMissing> = (source.filter { factory.create(this).predicate() }.size eq literal(0)).not()

/** The items of [source] that satisfy [predicate], written against the item's generated expressions. */
@GeneratedSdkApi
fun <T, S : Any> collectionFilter(
    source: Expr<List<T>, out MissingPolicy>,
    factory: ExpressionFactory<S>,
    predicate: S.() -> Expr<Boolean, out MissingPolicy>,
): Expr<List<T>, MayBeMissing> = source.filter { factory.create(this).predicate() }

/** The text representation of a value of a text backed named type. */
@GeneratedSdkApi
fun <M : MissingPolicy> textRepresentation(value: Expr<*, M>): Expr<String, M> = value.unwrap()

/** Imports a closed portable subtree. It cannot capture a local from its future insertion site. */
fun <T> portableExpression(node: ExpressionNode): Expr<T, MayBeMissing> {
    node.requireClosedExpression()
    val frozen = ExpressionNode.serializer.fromBytes(ExpressionNode.serializer.toBytes(node))
    return Expr { frozen }
}

internal fun <T> portableLiteral(value: DataValue): Expr<T, Handled> {
    val frozen = value.requirePortable()
    return Expr { ExpressionNode.LiteralWrapper(frozen) }
}

fun literal(value: String): Expr<String, Handled> = portableLiteral(DataValue.StringValueWrapper(value))

fun literal(value: ResourceId): Expr<ResourceId, Handled> =
    portableLiteral(DataValue.named(ResourceIdDefinition.use, DataValue.StringValueWrapper(value.value)))

fun literal(value: Boolean): Expr<Boolean, Handled> = portableLiteral(DataValue.BooleanWrapper(value))

fun literal(value: Int): Expr<Int, Handled> = portableLiteral(DataValue.integer(value.toBigInteger()))

fun literal(value: Long): Expr<Long, Handled> = portableLiteral(DataValue.integer(value.toBigInteger()))

fun literal(value: Float): Expr<Float, Handled> = portableLiteral(DataValue.FloatWrapper(value.toDouble()))

fun literal(value: Double): Expr<Double, Handled> = portableLiteral(DataValue.FloatWrapper(value))

fun literal(value: BigInteger): Expr<BigInteger, Handled> = portableLiteral(DataValue.integer(value))

fun literal(value: BigDecimal): Expr<BigDecimal, Handled> = portableLiteral(DataValue.DecimalWrapper(value.toPlainString()))

fun literal(value: Instant): Expr<Instant, Handled> = portableLiteral(DataValue.timestamp(value))

fun literal(value: Duration): Expr<Duration, Handled> = portableLiteral(DataValue.duration(value))

/** A named Color value, so the color shortcuts, which read the ARGB payload of a named Color, apply to it. */
fun literal(value: Color): Expr<Color, Handled> = portableLiteral(value.portableValue())

/** This color as a portable value: a named Color around its ARGB integer. */
internal fun Color.portableValue(): DataValue = DataValue.named(ColorDefinition.use, DataValue.integer(argb.toString().toBigInteger()))

fun literal(value: Icon): Expr<Icon, Handled> =
    portableLiteral(
        when (value) {
            is Icon.Iconify -> {
                DataValue.named(
                    IconIconifyDefinition.use,
                    DataValue.record(
                        mapOf("value" to DataValue.StringValueWrapper(value.value)),
                    ),
                )
            }

            is Icon.Svg -> {
                DataValue.named(IconSvgDefinition.use, DataValue.record(mapOf("source" to DataValue.StringValueWrapper(value.source))))
            }
        },
    )

fun literal(value: UByte): Expr<UByte, Handled> = portableLiteral(DataValue.integer(value.toString().toBigInteger()))

fun literal(value: UShort): Expr<UShort, Handled> = portableLiteral(DataValue.integer(value.toString().toBigInteger()))

fun literal(value: UInt): Expr<UInt, Handled> = portableLiteral(DataValue.integer(value.toString().toBigInteger()))

fun literal(value: ULong): Expr<ULong, Handled> = portableLiteral(DataValue.integer(value.toString().toBigInteger()))

infix fun <M : MissingPolicy> Expr<Boolean, M>.and(other: Expr<Boolean, M>): Expr<Boolean, M> =
    Expr { ExpressionNode.createAnd(left = lower(it), right = other.lower(it)) }

infix fun <M : MissingPolicy> Expr<Boolean, M>.or(other: Expr<Boolean, M>): Expr<Boolean, M> =
    Expr { ExpressionNode.createOr(left = lower(it), right = other.lower(it)) }

/** [then] when [test] is true, otherwise [otherwise]; only the chosen branch evaluates. */
fun <T> conditional(
    test: Expr<Boolean, out MissingPolicy>,
    then: Expr<T, out MissingPolicy>,
    otherwise: Expr<T, out MissingPolicy>,
): Expr<T, MayBeMissing> =
    Expr { ExpressionNode.createConditional(test = test.lower(it), then = then.lower(it), otherwise = otherwise.lower(it)) }

@JvmName("orElseNullable")
fun <T : Any, M : MissingPolicy> Expr<T?, M>.orElse(value: Expr<T, Handled>): Expr<T, Handled> =
    Expr { ExpressionNode.createOrElse(value = lower(it), fallback = value.lower(it)) }

@JvmName("orElseMissing")
fun <T : Any> Expr<T, MayBeMissing>.orElse(value: Expr<T, Handled>): Expr<T, Handled> =
    Expr { ExpressionNode.createOrElse(value = lower(it), fallback = value.lower(it)) }

fun <T> emptyListExpression(): Expr<List<T>, Handled> = portableLiteral(DataValue.listValue(emptyList()))

private fun ExpressionNode.requireClosedExpression() {
    fun visit(
        node: ExpressionNode,
        frames: List<Int>,
        depth: Int,
    ) {
        require(depth <= PortableExpressionLimits.MAX_DEPTH) { "Expression depth exceeded" }
        if (node is ExpressionNode.LocalWrapper) {
            val local = node.value
            require(
                local.depth >= 0 && local.slot >= 0 &&
                    frames.asReversed().getOrNull(local.depth)?.let { local.slot < it } == true,
            ) {
                "invalid_expression_local"
            }
        }
        node.children().forEach { child ->
            visit(child.node, if (child.frameArity == 0) frames else frames + child.frameArity, depth + 1)
        }
    }
    visit(this, emptyList(), 1)
}

fun <T> input(
    binding: ExpressionBindingId,
    path: ValuePath = ValuePath.root,
): Expr<T, MayBeMissing> = inputExpression(binding, path)
