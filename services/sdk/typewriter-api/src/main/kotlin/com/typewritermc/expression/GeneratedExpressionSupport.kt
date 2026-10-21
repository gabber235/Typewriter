package com.typewritermc.expression

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.root
import com.typewritermc.types.Color
import com.typewritermc.types.Icon
import com.typewritermc.types.IconIconifyDefinition
import com.typewritermc.types.IconSvgDefinition
import com.typewritermc.types.Ref
import com.typewritermc.types.RelationshipEndpoint
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ResourceIdDefinition
import com.typewritermc.types.duration
import com.typewritermc.types.field
import com.typewritermc.types.integer
import com.typewritermc.types.listValue
import com.typewritermc.types.named
import com.typewritermc.types.record
import com.typewritermc.types.requirePortable
import com.typewritermc.types.timestamp
import com.typewritermc.types.use
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.expression.NumberCompareOperation
import skirout.editor.v1.expression.RuleUnaryOperation
import skirout.editor.v1.expression.TextUnaryOperation
import skirout.editor.v1.expression.ValueCompareOperation
import skirout.editor.v1.type_catalog.DataValue
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
) {
    internal fun lower(environment: ExpressionEnvironment): ExpressionNode = emit(environment.descend())

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

fun <V> Expr<*, out MissingPolicy>.field(name: String): Expr<V, MayBeMissing> {
    val source = this
    val segment =
        PathSegment.createField(name = name)
    return Expr { environment ->
        when (val expression = source.lower(environment)) {
            is ExpressionNode.InputWrapper -> {
                ExpressionNode.InputWrapper(
                    expression.value.copy(path = expression.value.path.copy(segments = expression.value.path.segments + segment)),
                )
            }

            is ExpressionNode.LocalWrapper -> {
                ExpressionNode.LocalWrapper(
                    expression.value.copy(path = expression.value.path.copy(segments = expression.value.path.segments + segment)),
                )
            }

            else -> {
                ExpressionNode.createField(source = expression, name = name)
            }
        }
    }
}

private fun <T, B, O> Expr<out Collection<T>, *>.unaryCollection(
    make: (ExpressionNode, ExpressionNode) -> ExpressionNode,
    body: Expr<T, MayBeMissing>.() -> Expr<out B, out MissingPolicy>,
): Expr<O, MayBeMissing> {
    val source = this
    val frame = LambdaFrame(1)
    val result = local<T>(frame, 0).body()
    return Expr { outer -> make(source.lower(outer), result.lower(outer.enter(frame))) }
}

@GeneratedSdkApi
fun <T, S : Any> collectionAny(
    source: Expr<List<T>, out MissingPolicy>,
    factory: ExpressionFactory<S>,
    predicate: S.() -> Expr<Boolean, out MissingPolicy>,
): Expr<Boolean, MayBeMissing> = source.any { factory.create(this).predicate() }

@GeneratedSdkApi
fun <T, S : Any> collectionFilter(
    source: Expr<List<T>, out MissingPolicy>,
    factory: ExpressionFactory<S>,
    predicate: S.() -> Expr<Boolean, out MissingPolicy>,
): Expr<List<T>, MayBeMissing> = source.filter { factory.create(this).predicate() }

fun <T, M : MissingPolicy> Expr<out Collection<T>, M>.any(
    body: Expr<T, MayBeMissing>.() -> Expr<Boolean, out MissingPolicy>,
): Expr<Boolean, MayBeMissing> =
    unaryCollection<T, Boolean, Boolean>({ source, result ->
        ExpressionNode.createAny(source = source, body = result)
    }, body)

fun <T, M : MissingPolicy> Expr<out Collection<T>, M>.all(
    body: Expr<T, MayBeMissing>.() -> Expr<Boolean, out MissingPolicy>,
): Expr<Boolean, MayBeMissing> =
    unaryCollection<T, Boolean, Boolean>({ source, result ->
        ExpressionNode.createAll(source = source, body = result)
    }, body)

fun <T, M : MissingPolicy> Expr<out Collection<T>, M>.none(
    body: Expr<T, MayBeMissing>.() -> Expr<Boolean, out MissingPolicy>,
): Expr<Boolean, MayBeMissing> =
    unaryCollection<T, Boolean, Boolean>({ source, result ->
        ExpressionNode.createNone(source = source, body = result)
    }, body)

fun <T, M : MissingPolicy> Expr<out Collection<T>, M>.count(
    body: Expr<T, MayBeMissing>.() -> Expr<Boolean, out MissingPolicy>,
): Expr<Int, MayBeMissing> =
    unaryCollection<T, Boolean, Int>({ source, result ->
        ExpressionNode.createCount(source = source, body = result)
    }, body)

fun <T, M : MissingPolicy> Expr<out Collection<T>, M>.find(
    body: Expr<T, MayBeMissing>.() -> Expr<Boolean, out MissingPolicy>,
): Expr<T?, MayBeMissing> =
    unaryCollection<T, Boolean, T?>({ source, result ->
        ExpressionNode.createFind(source = source, body = result)
    }, body)

fun <T, M : MissingPolicy> Expr<out Collection<T>, M>.findLast(
    body: Expr<T, MayBeMissing>.() -> Expr<Boolean, out MissingPolicy>,
): Expr<T?, MayBeMissing> =
    unaryCollection<T, Boolean, T?>({ source, result ->
        ExpressionNode.createFindLast(source = source, body = result)
    }, body)

fun <T, M : MissingPolicy> Expr<List<T>, M>.filter(
    body: Expr<T, MayBeMissing>.() -> Expr<Boolean, out MissingPolicy>,
): Expr<List<T>, MayBeMissing> =
    unaryCollection<T, Boolean, List<T>>({ source, result ->
        ExpressionNode.createFilter(source = source, body = result)
    }, body)

fun <T, R, M : MissingPolicy> Expr<out Collection<T>, M>.map(
    body: Expr<T, MayBeMissing>.() -> Expr<R, out MissingPolicy>,
): Expr<List<R>, MayBeMissing> =
    unaryCollection<T, R, List<R>>({ source, result ->
        ExpressionNode.createMap(source = source, body = result)
    }, body)

fun <T, R, M : MissingPolicy> Expr<out Collection<T>, M>.flatMap(
    body: Expr<T, MayBeMissing>.() -> Expr<out Collection<R>, out MissingPolicy>,
): Expr<List<R>, MayBeMissing> =
    unaryCollection<T, Collection<R>, List<R>>({ source, result ->
        ExpressionNode.createFlatMap(source = source, body = result)
    }, body)

fun <T, K, M : MissingPolicy> Expr<List<T>, M>.distinctBy(
    body: Expr<T, MayBeMissing>.() -> Expr<K, out MissingPolicy>,
): Expr<List<T>, MayBeMissing> =
    unaryCollection<T, K, List<T>>({ source, result ->
        ExpressionNode.createDistinctBy(source = source, body = result)
    }, body)

fun <T, K, M : MissingPolicy> Expr<out Collection<T>, M>.groupBy(
    body: Expr<T, MayBeMissing>.() -> Expr<K, out MissingPolicy>,
): Expr<Map<K, List<T>>, MayBeMissing> =
    unaryCollection<T, K, Map<K, List<T>>>({ source, result ->
        ExpressionNode.createGroupBy(source = source, body = result)
    }, body)

fun <T, K, M : MissingPolicy> Expr<out Collection<T>, M>.uniqueBy(
    body: Expr<T, MayBeMissing>.() -> Expr<K, out MissingPolicy>,
): Expr<Boolean, MayBeMissing> =
    unaryCollection<T, K, Boolean>({ source, result ->
        ExpressionNode.createUniqueBy(source = source, body = result)
    }, body)

fun <T, K, M : MissingPolicy> Expr<List<T>, M>.sortedBy(
    descending: Boolean = false,
    key: Expr<T, MayBeMissing>.() -> Expr<K, out MissingPolicy>,
): Expr<List<T>, MayBeMissing> {
    val source = this
    val frame = LambdaFrame(1)
    val result = local<T>(frame, 0).key()
    val order = literal(descending)
    return Expr { outer ->
        ExpressionNode.createSortBy(
            source = source.lower(outer),
            descending = order.lower(outer),
            key = result.lower(outer.enter(frame)),
        )
    }
}

fun <T, M : MissingPolicy> Expr<List<T>, M>.distinct(): Expr<List<T>, M> = Expr { ExpressionNode.DistinctWrapper(lower(it)) }

fun <T, M : MissingPolicy> Expr<List<T>, M>.reversed(): Expr<List<T>, M> = Expr { ExpressionNode.ReverseWrapper(lower(it)) }

fun <T, M : MissingPolicy> Expr<List<T>, M>.take(count: Expr<Int, out MissingPolicy>): Expr<List<T>, MayBeMissing> =
    Expr { ExpressionNode.createTake(source = lower(it), count = count.lower(it)) }

fun <T, M : MissingPolicy> Expr<List<T>, M>.skip(count: Expr<Int, out MissingPolicy>): Expr<List<T>, MayBeMissing> =
    Expr { ExpressionNode.createSkip(source = lower(it), count = count.lower(it)) }

fun <T, M : MissingPolicy> Expr<List<T>, M>.reduce(
    combine: (Expr<T, MayBeMissing>, Expr<T, MayBeMissing>) -> Expr<T, out MissingPolicy>,
): Expr<T?, MayBeMissing> {
    val source = this
    val frame = LambdaFrame(2)
    val body = combine(local(frame, 0), local(frame, 1))
    return Expr { outer -> ExpressionNode.createReduce(source = source.lower(outer), body = body.lower(outer.enter(frame))) }
}

fun <T, R, M : MissingPolicy> Expr<out Collection<T>, M>.fold(
    initial: Expr<R, out MissingPolicy>,
    combine: (Expr<R, MayBeMissing>, Expr<T, MayBeMissing>) -> Expr<R, out MissingPolicy>,
): Expr<R, MayBeMissing> {
    val source = this
    val frame = LambdaFrame(2)
    val body = combine(local(frame, 0), local(frame, 1))
    return Expr { outer ->
        ExpressionNode.createFold(
            source = source.lower(outer),
            initial = initial.lower(outer),
            body = body.lower(outer.enter(frame)),
        )
    }
}

fun <T, M : MissingPolicy> Expr<List<T>, M>.sortedWith(
    compare: (Expr<T, MayBeMissing>, Expr<T, MayBeMissing>) -> Expr<out Number, out MissingPolicy>,
): Expr<List<T>, MayBeMissing> {
    val source = this
    val frame = LambdaFrame(2)
    val body = compare(local(frame, 0), local(frame, 1))
    return Expr { outer -> ExpressionNode.createSortWith(source = source.lower(outer), comparator = body.lower(outer.enter(frame))) }
}

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

fun literal(value: Color): Expr<Color, Handled> = portableLiteral(DataValue.integer(value.argb.toString().toBigInteger()))

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

fun <M : MissingPolicy> Expr<*, M>.isNull(): Expr<Boolean, M> = Expr { ExpressionNode.IsNullWrapper(lower(it)) }

@GeneratedSdkApi
fun <M : MissingPolicy> textRepresentation(value: Expr<*, M>): Expr<String, M> =
    Expr { ExpressionNode.createTextUnary(operation = TextUnaryOperation.VALUE, source = value.lower(it)) }

fun <M : MissingPolicy> Expr<Boolean, M>.not(): Expr<Boolean, M> = Expr { ExpressionNode.BooleanNotWrapper(lower(it)) }

infix fun <M : MissingPolicy> Expr<Boolean, M>.and(other: Expr<Boolean, M>): Expr<Boolean, M> =
    Expr { ExpressionNode.createAnd(left = lower(it), right = other.lower(it)) }

infix fun <M : MissingPolicy> Expr<Boolean, M>.or(other: Expr<Boolean, M>): Expr<Boolean, M> =
    Expr { ExpressionNode.createOr(left = lower(it), right = other.lower(it)) }

infix fun <T, M : MissingPolicy> Expr<T, M>.eq(other: Expr<T, M>): Expr<Boolean, M> =
    Expr { ExpressionNode.createValueCompare(operation = ValueCompareOperation.EQUAL, left = lower(it), right = other.lower(it)) }

infix fun <T, M : MissingPolicy> Expr<T, M>.neq(other: Expr<T, M>): Expr<Boolean, M> =
    Expr { ExpressionNode.createValueCompare(operation = ValueCompareOperation.NOT_EQUAL, left = lower(it), right = other.lower(it)) }

infix fun <N : Number, M : MissingPolicy> Expr<N, M>.gt(value: N): Expr<Boolean, M> {
    val operand = portableLiteral<N>(numberLiteral(value))
    return Expr {
        ExpressionNode.createNumberCompare(
            operation = NumberCompareOperation.GREATER,
            left = lower(it),
            right = operand.lower(it),
        )
    }
}

infix fun <N : Number, M : MissingPolicy> Expr<N, M>.gt(other: Expr<N, M>): Expr<Boolean, M> =
    Expr { ExpressionNode.createNumberCompare(operation = NumberCompareOperation.GREATER, left = lower(it), right = other.lower(it)) }

@JvmName("UBytegtLiteral")
infix fun <M : MissingPolicy> Expr<UByte, M>.gt(value: UByte): Expr<Boolean, M> {
    val operand = literal(value)
    return Expr {
        ExpressionNode.createNumberCompare(
            operation = NumberCompareOperation.GREATER,
            left = lower(it),
            right = operand.lower(it),
        )
    }
}

@JvmName("UShortgtLiteral")
infix fun <M : MissingPolicy> Expr<UShort, M>.gt(value: UShort): Expr<Boolean, M> {
    val operand = literal(value)
    return Expr {
        ExpressionNode.createNumberCompare(
            operation = NumberCompareOperation.GREATER,
            left = lower(it),
            right = operand.lower(it),
        )
    }
}

@JvmName("UIntgtLiteral")
infix fun <M : MissingPolicy> Expr<UInt, M>.gt(value: UInt): Expr<Boolean, M> {
    val operand = literal(value)
    return Expr {
        ExpressionNode.createNumberCompare(
            operation = NumberCompareOperation.GREATER,
            left = lower(it),
            right = operand.lower(it),
        )
    }
}

@JvmName("ULonggtLiteral")
infix fun <M : MissingPolicy> Expr<ULong, M>.gt(value: ULong): Expr<Boolean, M> {
    val operand = literal(value)
    return Expr {
        ExpressionNode.createNumberCompare(
            operation = NumberCompareOperation.GREATER,
            left = lower(it),
            right = operand.lower(it),
        )
    }
}

infix fun <N : Number, M : MissingPolicy> Expr<N, M>.gte(value: N): Expr<Boolean, M> {
    val operand = portableLiteral<N>(numberLiteral(value))
    return Expr {
        ExpressionNode.createNumberCompare(operation = NumberCompareOperation.GREATER_EQUAL, left = lower(it), right = operand.lower(it))
    }
}

infix fun <N : Number, M : MissingPolicy> Expr<N, M>.gte(other: Expr<N, M>): Expr<Boolean, M> =
    Expr { ExpressionNode.createNumberCompare(operation = NumberCompareOperation.GREATER_EQUAL, left = lower(it), right = other.lower(it)) }

@JvmName("UBytegteLiteral")
infix fun <M : MissingPolicy> Expr<UByte, M>.gte(value: UByte): Expr<Boolean, M> {
    val operand = literal(value)
    return Expr {
        ExpressionNode.createNumberCompare(operation = NumberCompareOperation.GREATER_EQUAL, left = lower(it), right = operand.lower(it))
    }
}

@JvmName("UShortgteLiteral")
infix fun <M : MissingPolicy> Expr<UShort, M>.gte(value: UShort): Expr<Boolean, M> {
    val operand = literal(value)
    return Expr {
        ExpressionNode.createNumberCompare(operation = NumberCompareOperation.GREATER_EQUAL, left = lower(it), right = operand.lower(it))
    }
}

@JvmName("UIntgteLiteral")
infix fun <M : MissingPolicy> Expr<UInt, M>.gte(value: UInt): Expr<Boolean, M> {
    val operand = literal(value)
    return Expr {
        ExpressionNode.createNumberCompare(operation = NumberCompareOperation.GREATER_EQUAL, left = lower(it), right = operand.lower(it))
    }
}

@JvmName("ULonggteLiteral")
infix fun <M : MissingPolicy> Expr<ULong, M>.gte(value: ULong): Expr<Boolean, M> {
    val operand = literal(value)
    return Expr {
        ExpressionNode.createNumberCompare(operation = NumberCompareOperation.GREATER_EQUAL, left = lower(it), right = operand.lower(it))
    }
}

infix fun <N : Number, M : MissingPolicy> Expr<N, M>.lt(value: N): Expr<Boolean, M> {
    val operand = portableLiteral<N>(numberLiteral(value))
    return Expr { ExpressionNode.createNumberCompare(operation = NumberCompareOperation.LESS, left = lower(it), right = operand.lower(it)) }
}

infix fun <N : Number, M : MissingPolicy> Expr<N, M>.lt(other: Expr<N, M>): Expr<Boolean, M> =
    Expr { ExpressionNode.createNumberCompare(operation = NumberCompareOperation.LESS, left = lower(it), right = other.lower(it)) }

@JvmName("UByteltLiteral")
infix fun <M : MissingPolicy> Expr<UByte, M>.lt(value: UByte): Expr<Boolean, M> {
    val operand = literal(value)
    return Expr { ExpressionNode.createNumberCompare(operation = NumberCompareOperation.LESS, left = lower(it), right = operand.lower(it)) }
}

@JvmName("UShortltLiteral")
infix fun <M : MissingPolicy> Expr<UShort, M>.lt(value: UShort): Expr<Boolean, M> {
    val operand = literal(value)
    return Expr { ExpressionNode.createNumberCompare(operation = NumberCompareOperation.LESS, left = lower(it), right = operand.lower(it)) }
}

@JvmName("UIntltLiteral")
infix fun <M : MissingPolicy> Expr<UInt, M>.lt(value: UInt): Expr<Boolean, M> {
    val operand = literal(value)
    return Expr { ExpressionNode.createNumberCompare(operation = NumberCompareOperation.LESS, left = lower(it), right = operand.lower(it)) }
}

@JvmName("ULongltLiteral")
infix fun <M : MissingPolicy> Expr<ULong, M>.lt(value: ULong): Expr<Boolean, M> {
    val operand = literal(value)
    return Expr { ExpressionNode.createNumberCompare(operation = NumberCompareOperation.LESS, left = lower(it), right = operand.lower(it)) }
}

infix fun <N : Number, M : MissingPolicy> Expr<N, M>.lte(value: N): Expr<Boolean, M> {
    val operand = portableLiteral<N>(numberLiteral(value))
    return Expr {
        ExpressionNode.createNumberCompare(operation = NumberCompareOperation.LESS_EQUAL, left = lower(it), right = operand.lower(it))
    }
}

infix fun <N : Number, M : MissingPolicy> Expr<N, M>.lte(other: Expr<N, M>): Expr<Boolean, M> =
    Expr { ExpressionNode.createNumberCompare(operation = NumberCompareOperation.LESS_EQUAL, left = lower(it), right = other.lower(it)) }

@JvmName("UBytelteLiteral")
infix fun <M : MissingPolicy> Expr<UByte, M>.lte(value: UByte): Expr<Boolean, M> {
    val operand = literal(value)
    return Expr {
        ExpressionNode.createNumberCompare(operation = NumberCompareOperation.LESS_EQUAL, left = lower(it), right = operand.lower(it))
    }
}

@JvmName("UShortlteLiteral")
infix fun <M : MissingPolicy> Expr<UShort, M>.lte(value: UShort): Expr<Boolean, M> {
    val operand = literal(value)
    return Expr {
        ExpressionNode.createNumberCompare(operation = NumberCompareOperation.LESS_EQUAL, left = lower(it), right = operand.lower(it))
    }
}

@JvmName("UIntlteLiteral")
infix fun <M : MissingPolicy> Expr<UInt, M>.lte(value: UInt): Expr<Boolean, M> {
    val operand = literal(value)
    return Expr {
        ExpressionNode.createNumberCompare(operation = NumberCompareOperation.LESS_EQUAL, left = lower(it), right = operand.lower(it))
    }
}

@JvmName("ULonglteLiteral")
infix fun <M : MissingPolicy> Expr<ULong, M>.lte(value: ULong): Expr<Boolean, M> {
    val operand = literal(value)
    return Expr {
        ExpressionNode.createNumberCompare(operation = NumberCompareOperation.LESS_EQUAL, left = lower(it), right = operand.lower(it))
    }
}

val <M : MissingPolicy> Expr<String, M>.length: Expr<Int, M> get() = Expr { ExpressionNode.TextLengthWrapper(lower(it)) }

fun <M : MissingPolicy> Expr<String, M>.hasLineBreaks(): Expr<Boolean, M> = Expr { ExpressionNode.TextHasLineBreakWrapper(lower(it)) }

val <T, M : MissingPolicy> Expr<out Collection<T>, M>.size: Expr<Int, M> get() = Expr { ExpressionNode.CollectionSizeWrapper(lower(it)) }

@JvmName("orElseNullable")
fun <T : Any, M : MissingPolicy> Expr<T?, M>.orElse(value: Expr<T, Handled>): Expr<T, Handled> =
    Expr { ExpressionNode.createOrElse(input = lower(it), fallback = value.lower(it)) }

@JvmName("orElseMissing")
fun <T : Any> Expr<T, MayBeMissing>.orElse(value: Expr<T, Handled>): Expr<T, Handled> =
    Expr { ExpressionNode.createOrElse(input = lower(it), fallback = value.lower(it)) }

/** This text when it is present and not blank, otherwise [fallback]. */
fun Expr<String, MissingPolicy>.orIfBlank(fallback: Expr<String, Handled>): Expr<String, Handled> {
    val source = this
    return Expr { environment ->
        val input = source.lower(environment)
        val fallbackNode = fallback.lower(environment)
        ExpressionNode.createOrElse(
            input =
                ExpressionNode.createConditional(
                    test = ExpressionNode.createRuleUnary(operation = RuleUnaryOperation.NON_BLANK, source = input),
                    yes = input,
                    no = fallbackNode,
                ),
            fallback = fallbackNode,
        )
    }
}

/** This text when it is present and not blank, otherwise the literal [fallback]. */
fun Expr<String, MissingPolicy>.orIfBlank(fallback: String): Expr<String, Handled> = orIfBlank(literal(fallback))

val <E : RelationshipEndpoint<*, *>, T : Resource, M : MissingPolicy> Expr<Ref<E, T>, M>.target: Expr<ResourceId, M>
    get() = Expr { ExpressionNode.LinkTargetWrapper(lower(it)) }

fun <T> emptyListExpression(): Expr<List<T>, Handled> = portableLiteral(DataValue.listValue(emptyList()))

private fun numberLiteral(value: Number): DataValue =
    when (value) {
        is Byte, is Short, is Int, is Long -> DataValue.integer(value.toLong().toBigInteger())
        is Float, is Double -> DataValue.FloatWrapper(value.toDouble())
        is BigInteger -> DataValue.integer(value)
        is BigDecimal -> DataValue.DecimalWrapper(value.toPlainString())
        else -> throw IllegalArgumentException("Unsupported portable numeric constant ${value::class.qualifiedName}.")
    }

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
