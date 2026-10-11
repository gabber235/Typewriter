package com.typewritermc.expression

import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.ValuePath
import com.typewritermc.presentation.ExpressionNode
import com.typewritermc.types.DataValue
import com.typewritermc.types.Ref
import com.typewritermc.types.RelationshipEndpoint
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceId
import java.math.BigDecimal
import java.math.BigInteger
import kotlin.time.Duration
import kotlin.time.Instant

sealed interface MissingPolicy

sealed interface MayBeMissing : MissingPolicy

sealed interface Handled : MayBeMissing

class Expr<T, out M : MissingPolicy> internal constructor(
    val node: ExpressionNode,
)

fun <V> Expr<*, out MissingPolicy>.field(name: String): Expr<V, MayBeMissing> =
    Expr(
        when (val expression = node) {
            is ExpressionNode.Read -> {
                expression.copy(path = ValuePath(expression.path.segments + PathSegment.Field(name)))
            }

            else -> {
                ExpressionNode.Call(
                    OperationId("typewriter.record.field"),
                    listOf(expression, ExpressionNode.Literal(DataValue.StringValue(name))),
                )
            }
        },
    )

fun <T, S : Any> collectionAny(
    source: Expr<List<T>, out MissingPolicy>,
    factory: ExpressionFactory<S>,
    predicate: S.() -> Expr<Boolean, out MissingPolicy>,
): Expr<Boolean, MayBeMissing> {
    val item = ExpressionBindingId("item_${source.node.hashCode().toUInt()}")
    val expressions = factory.create(Expr<T, MayBeMissing>(ExpressionNode.Read(item, ValuePath())))
    return Expr(
        ExpressionNode.Collection(
            OperationId("typewriter.collection.any"),
            source.node,
            listOf(item),
            emptyList(),
            expressions.predicate().node,
        ),
    )
}

fun <T, S : Any> collectionFilter(
    source: Expr<List<T>, out MissingPolicy>,
    factory: ExpressionFactory<S>,
    predicate: S.() -> Expr<Boolean, out MissingPolicy>,
): Expr<List<T>, MayBeMissing> {
    val item = ExpressionBindingId("item_${source.node.hashCode().toUInt()}")
    val expressions = factory.create(Expr<T, MayBeMissing>(ExpressionNode.Read(item, ValuePath())))
    return Expr(
        ExpressionNode.Collection(
            OperationId("typewriter.collection.filter"),
            source.node,
            listOf(item),
            emptyList(),
            expressions.predicate().node,
        ),
    )
}

fun <T, M : MissingPolicy> Expr<out Collection<T>, M>.any(
    predicate: Expr<T, MayBeMissing>.() -> Expr<Boolean, out MissingPolicy>,
): Expr<Boolean, MayBeMissing> = unaryCollection<T, Boolean, Boolean>("any", predicate)

fun <T, M : MissingPolicy> Expr<out Collection<T>, M>.all(
    predicate: Expr<T, MayBeMissing>.() -> Expr<Boolean, out MissingPolicy>,
): Expr<Boolean, MayBeMissing> = unaryCollection<T, Boolean, Boolean>("all", predicate)

fun <T, M : MissingPolicy> Expr<out Collection<T>, M>.none(
    predicate: Expr<T, MayBeMissing>.() -> Expr<Boolean, out MissingPolicy>,
): Expr<Boolean, MayBeMissing> = unaryCollection<T, Boolean, Boolean>("none", predicate)

fun <T, M : MissingPolicy> Expr<out Collection<T>, M>.count(
    predicate: Expr<T, MayBeMissing>.() -> Expr<Boolean, out MissingPolicy>,
): Expr<Int, MayBeMissing> = unaryCollection<T, Boolean, Int>("count", predicate)

fun <T, M : MissingPolicy> Expr<out Collection<T>, M>.find(
    predicate: Expr<T, MayBeMissing>.() -> Expr<Boolean, out MissingPolicy>,
): Expr<T?, MayBeMissing> = unaryCollection<T, Boolean, T?>("find", predicate)

fun <T, M : MissingPolicy> Expr<out Collection<T>, M>.findLast(
    predicate: Expr<T, MayBeMissing>.() -> Expr<Boolean, out MissingPolicy>,
): Expr<T?, MayBeMissing> = unaryCollection<T, Boolean, T?>("find_last", predicate)

fun <T, M : MissingPolicy> Expr<List<T>, M>.filter(
    predicate: Expr<T, MayBeMissing>.() -> Expr<Boolean, out MissingPolicy>,
): Expr<List<T>, MayBeMissing> = unaryCollection<T, Boolean, List<T>>("filter", predicate)

fun <T, R, M : MissingPolicy> Expr<out Collection<T>, M>.map(
    transform: Expr<T, MayBeMissing>.() -> Expr<R, out MissingPolicy>,
): Expr<List<R>, MayBeMissing> = unaryCollection<T, R, List<R>>("map", transform)

fun <T, R, M : MissingPolicy> Expr<out Collection<T>, M>.flatMap(
    transform: Expr<T, MayBeMissing>.() -> Expr<out Collection<R>, out MissingPolicy>,
): Expr<List<R>, MayBeMissing> = unaryCollection<T, Collection<R>, List<R>>("flat_map", transform)

fun <T, K, M : MissingPolicy> Expr<List<T>, M>.distinctBy(
    key: Expr<T, MayBeMissing>.() -> Expr<K, out MissingPolicy>,
): Expr<List<T>, MayBeMissing> = unaryCollection<T, K, List<T>>("distinct_by", key)

fun <T, K, M : MissingPolicy> Expr<List<T>, M>.sortedBy(
    descending: Boolean = false,
    key: Expr<T, MayBeMissing>.() -> Expr<K, out MissingPolicy>,
): Expr<List<T>, MayBeMissing> =
    unaryCollection<T, K, List<T>>("sort_by", key, listOf(ExpressionNode.Literal(DataValue.Boolean(descending))))

fun <T, K, M : MissingPolicy> Expr<out Collection<T>, M>.groupBy(
    key: Expr<T, MayBeMissing>.() -> Expr<K, out MissingPolicy>,
): Expr<Map<K, List<T>>, MayBeMissing> = unaryCollection<T, K, Map<K, List<T>>>("group_by", key)

fun <T, M : MissingPolicy> Expr<List<T>, M>.distinct(): Expr<List<T>, M> = preserveCollection("distinct")

fun <T, M : MissingPolicy> Expr<List<T>, M>.reversed(): Expr<List<T>, M> = preserveCollection("reverse")

fun <T, M : MissingPolicy> Expr<List<T>, M>.take(count: Expr<Int, out MissingPolicy>): Expr<List<T>, MayBeMissing> =
    bodylessCollection<List<T>>("take", listOf(count.node))

fun <T, M : MissingPolicy> Expr<List<T>, M>.skip(count: Expr<Int, out MissingPolicy>): Expr<List<T>, MayBeMissing> =
    bodylessCollection<List<T>>("skip", listOf(count.node))

fun <T, M : MissingPolicy> Expr<List<T>, M>.reduce(
    combine: (Expr<T, MayBeMissing>, Expr<T, MayBeMissing>) -> Expr<T, out MissingPolicy>,
): Expr<T?, MayBeMissing> = binaryCollection<T, T, T?>("reduce") { accumulator, item -> combine(accumulator, item) }

fun <T, R, M : MissingPolicy> Expr<out Collection<T>, M>.fold(
    initial: Expr<R, out MissingPolicy>,
    combine: (Expr<R, MayBeMissing>, Expr<T, MayBeMissing>) -> Expr<R, out MissingPolicy>,
): Expr<R, MayBeMissing> = binaryCollection<T, R, R>("fold", listOf(initial.node)) { accumulator, item -> combine(accumulator, item) }

fun <T, M : MissingPolicy> Expr<List<T>, M>.sortedWith(
    compare: (Expr<T, MayBeMissing>, Expr<T, MayBeMissing>) -> Expr<out Number, out MissingPolicy>,
): Expr<List<T>, MayBeMissing> = binaryCollection<T, T, List<T>>("sort_with", body = compare)

private fun <T, B, O> Expr<out Collection<T>, *>.unaryCollection(
    operation: String,
    body: Expr<T, MayBeMissing>.() -> Expr<out B, out MissingPolicy>,
    arguments: List<ExpressionNode> = emptyList(),
): Expr<O, MayBeMissing> {
    val item = collectionBinding(operation, 0)
    val expression = Expr<T, MayBeMissing>(ExpressionNode.Read(item, ValuePath()))
    return Expr(
        ExpressionNode.Collection(
            OperationId("typewriter.collection.$operation"),
            node,
            listOf(item),
            arguments,
            expression.body().node,
        ),
    )
}

private fun <R> Expr<*, *>.bodylessCollection(
    operation: String,
    arguments: List<ExpressionNode> = emptyList(),
): Expr<R, MayBeMissing> =
    Expr(ExpressionNode.Collection(OperationId("typewriter.collection.$operation"), node, emptyList(), arguments, null))

private fun <R, M : MissingPolicy> Expr<*, M>.preserveCollection(operation: String): Expr<R, M> =
    Expr(ExpressionNode.Collection(OperationId("typewriter.collection.$operation"), node, emptyList(), emptyList(), null))

private fun <T, A, O> Expr<out Collection<T>, *>.binaryCollection(
    operation: String,
    arguments: List<ExpressionNode> = emptyList(),
    body: (Expr<A, MayBeMissing>, Expr<T, MayBeMissing>) -> Expr<*, out MissingPolicy>,
): Expr<O, MayBeMissing> {
    val first = collectionBinding(operation, 0)
    val second = collectionBinding(operation, 1)
    return Expr(
        ExpressionNode.Collection(
            OperationId("typewriter.collection.$operation"),
            node,
            listOf(first, second),
            arguments,
            body(
                Expr<A, MayBeMissing>(ExpressionNode.Read(first, ValuePath())),
                Expr(ExpressionNode.Read(second, ValuePath())),
            ).node,
        ),
    )
}

private fun Expr<*, *>.collectionBinding(
    operation: String,
    slot: Int,
): ExpressionBindingId = ExpressionBindingId("${operation}_${slot}_${node.hashCode().toUInt()}")

fun <T> portableExpression(node: ExpressionNode): Expr<T, MayBeMissing> = Expr(node)

fun literal(value: String): Expr<String, Handled> = Expr(ExpressionNode.Literal(DataValue.StringValue(value)))

fun literal(value: Boolean): Expr<Boolean, Handled> = Expr(ExpressionNode.Literal(DataValue.Boolean(value)))

fun literal(value: Int): Expr<Int, Handled> = Expr(ExpressionNode.Literal(DataValue.Integer(value.toBigInteger())))

fun literal(value: Long): Expr<Long, Handled> = Expr(ExpressionNode.Literal(DataValue.Integer(value.toBigInteger())))

fun literal(value: Float): Expr<Float, Handled> = Expr(ExpressionNode.Literal(DataValue.Float(value.toDouble())))

fun literal(value: Double): Expr<Double, Handled> = Expr(ExpressionNode.Literal(DataValue.Float(value)))

fun literal(value: BigInteger): Expr<BigInteger, Handled> = Expr(ExpressionNode.Literal(DataValue.Integer(value)))

fun literal(value: BigDecimal): Expr<BigDecimal, Handled> = Expr(ExpressionNode.Literal(DataValue.Decimal(value.toPlainString())))

fun literal(value: Instant): Expr<Instant, Handled> = Expr(ExpressionNode.Literal(DataValue.Timestamp(value)))

fun literal(value: Duration): Expr<Duration, Handled> = Expr(ExpressionNode.Literal(DataValue.Duration(value)))

fun <M : MissingPolicy> Expr<Boolean, M>.not(): Expr<Boolean, M> =
    Expr(ExpressionNode.Call(OperationId("typewriter.boolean.not"), listOf(node)))

infix fun <M : MissingPolicy> Expr<Boolean, M>.and(other: Expr<Boolean, M>): Expr<Boolean, M> = Expr(ExpressionNode.And(node, other.node))

infix fun <M : MissingPolicy> Expr<Boolean, M>.or(other: Expr<Boolean, M>): Expr<Boolean, M> = Expr(ExpressionNode.Or(node, other.node))

infix fun <T, M : MissingPolicy> Expr<T, M>.eq(other: Expr<T, M>): Expr<Boolean, M> =
    Expr(ExpressionNode.Call(OperationId("typewriter.value.eq"), listOf(node, other.node)))

infix fun <T, M : MissingPolicy> Expr<T, M>.neq(other: Expr<T, M>): Expr<Boolean, M> =
    Expr(ExpressionNode.Call(OperationId("typewriter.value.neq"), listOf(node, other.node)))

infix fun <N : Number, M : MissingPolicy> Expr<N, M>.gt(value: N): Expr<Boolean, M> = numeric("gt", value)

infix fun <N : Number, M : MissingPolicy> Expr<N, M>.gte(value: N): Expr<Boolean, M> = numeric("gte", value)

infix fun <N : Number, M : MissingPolicy> Expr<N, M>.lt(value: N): Expr<Boolean, M> = numeric("lt", value)

infix fun <N : Number, M : MissingPolicy> Expr<N, M>.lte(value: N): Expr<Boolean, M> = numeric("lte", value)

infix fun <N : Number, M : MissingPolicy> Expr<N, M>.gt(other: Expr<N, M>): Expr<Boolean, M> = numeric("gt", other)

infix fun <N : Number, M : MissingPolicy> Expr<N, M>.gte(other: Expr<N, M>): Expr<Boolean, M> = numeric("gte", other)

infix fun <N : Number, M : MissingPolicy> Expr<N, M>.lt(other: Expr<N, M>): Expr<Boolean, M> = numeric("lt", other)

infix fun <N : Number, M : MissingPolicy> Expr<N, M>.lte(other: Expr<N, M>): Expr<Boolean, M> = numeric("lte", other)

@JvmName("unsignedByteGreaterThanOrEqual")
infix fun <M : MissingPolicy> Expr<UByte, M>.gte(value: UByte): Expr<Boolean, M> = unsignedNumeric("gte", value)

@JvmName("unsignedShortGreaterThanOrEqual")
infix fun <M : MissingPolicy> Expr<UShort, M>.gte(value: UShort): Expr<Boolean, M> = unsignedNumeric("gte", value)

@JvmName("unsignedIntGreaterThanOrEqual")
infix fun <M : MissingPolicy> Expr<UInt, M>.gte(value: UInt): Expr<Boolean, M> = unsignedNumeric("gte", value)

@JvmName("unsignedLongGreaterThanOrEqual")
infix fun <M : MissingPolicy> Expr<ULong, M>.gte(value: ULong): Expr<Boolean, M> = unsignedNumeric("gte", value)

@JvmName("unsignedByteGreaterThan")
infix fun <M : MissingPolicy> Expr<UByte, M>.gt(value: UByte): Expr<Boolean, M> = unsignedNumeric("gt", value)

@JvmName("unsignedShortGreaterThan")
infix fun <M : MissingPolicy> Expr<UShort, M>.gt(value: UShort): Expr<Boolean, M> = unsignedNumeric("gt", value)

@JvmName("unsignedIntGreaterThan")
infix fun <M : MissingPolicy> Expr<UInt, M>.gt(value: UInt): Expr<Boolean, M> = unsignedNumeric("gt", value)

@JvmName("unsignedLongGreaterThan")
infix fun <M : MissingPolicy> Expr<ULong, M>.gt(value: ULong): Expr<Boolean, M> = unsignedNumeric("gt", value)

@JvmName("unsignedByteLessThan")
infix fun <M : MissingPolicy> Expr<UByte, M>.lt(value: UByte): Expr<Boolean, M> = unsignedNumeric("lt", value)

@JvmName("unsignedShortLessThan")
infix fun <M : MissingPolicy> Expr<UShort, M>.lt(value: UShort): Expr<Boolean, M> = unsignedNumeric("lt", value)

@JvmName("unsignedIntLessThan")
infix fun <M : MissingPolicy> Expr<UInt, M>.lt(value: UInt): Expr<Boolean, M> = unsignedNumeric("lt", value)

@JvmName("unsignedLongLessThan")
infix fun <M : MissingPolicy> Expr<ULong, M>.lt(value: ULong): Expr<Boolean, M> = unsignedNumeric("lt", value)

@JvmName("unsignedByteLessThanOrEqual")
infix fun <M : MissingPolicy> Expr<UByte, M>.lte(value: UByte): Expr<Boolean, M> = unsignedNumeric("lte", value)

@JvmName("unsignedShortLessThanOrEqual")
infix fun <M : MissingPolicy> Expr<UShort, M>.lte(value: UShort): Expr<Boolean, M> = unsignedNumeric("lte", value)

@JvmName("unsignedIntLessThanOrEqual")
infix fun <M : MissingPolicy> Expr<UInt, M>.lte(value: UInt): Expr<Boolean, M> = unsignedNumeric("lte", value)

@JvmName("unsignedLongLessThanOrEqual")
infix fun <M : MissingPolicy> Expr<ULong, M>.lte(value: ULong): Expr<Boolean, M> = unsignedNumeric("lte", value)

val <M : MissingPolicy> Expr<String, M>.length: Expr<Int, M>
    get() = Expr(ExpressionNode.Call(OperationId("typewriter.text.length"), listOf(node)))

fun <M : MissingPolicy> Expr<String, M>.hasLineBreaks(): Expr<Boolean, M> =
    Expr(ExpressionNode.Call(OperationId("typewriter.text.has_line_break"), listOf(node)))

val <T, M : MissingPolicy> Expr<out Collection<T>, M>.size: Expr<Int, M>
    get() = Expr(ExpressionNode.Call(OperationId("typewriter.collection.size"), listOf(node)))

@JvmName("orElseNullable")
fun <T : Any, M : MissingPolicy> Expr<T?, M>.orElse(value: Expr<T, Handled>): Expr<T, Handled> =
    Expr(ExpressionNode.OrElse(node, value.node))

@JvmName("orElseMissing")
fun <T : Any> Expr<T, MayBeMissing>.orElse(value: Expr<T, Handled>): Expr<T, Handled> = Expr(ExpressionNode.OrElse(node, value.node))

private fun <N : Number, M : MissingPolicy> Expr<N, M>.numeric(
    operation: String,
    value: N,
): Expr<Boolean, M> =
    Expr(
        ExpressionNode.Call(
            OperationId("typewriter.number.$operation"),
            listOf(node, ExpressionNode.Literal(numberLiteral(value))),
        ),
    )

private fun <N : Number, M : MissingPolicy> Expr<N, M>.numeric(
    operation: String,
    value: Expr<N, M>,
): Expr<Boolean, M> =
    Expr(
        ExpressionNode.Call(
            OperationId("typewriter.number.$operation"),
            listOf(node, value.node),
        ),
    )

private fun <N : Any, M : MissingPolicy> Expr<N, M>.unsignedNumeric(
    operation: String,
    value: N,
): Expr<Boolean, M> =
    Expr(
        ExpressionNode.Call(
            OperationId("typewriter.number.$operation"),
            listOf(node, ExpressionNode.Literal(unsignedLiteral(value))),
        ),
    )

private fun unsignedLiteral(value: Any): DataValue.Integer =
    DataValue.Integer(
        when (value) {
            is UByte -> value.toLong().toBigInteger()
            is UShort -> value.toLong().toBigInteger()
            is UInt -> value.toString().toBigInteger()
            is ULong -> value.toString().toBigInteger()
            else -> throw IllegalArgumentException("Unsupported portable unsigned numeric constant ${value::class.qualifiedName}.")
        },
    )

private fun numberLiteral(value: Number): DataValue =
    when (value) {
        is Byte -> DataValue.Integer(value.toLong().toBigInteger())
        is Short -> DataValue.Integer(value.toLong().toBigInteger())
        is Int -> DataValue.Integer(value.toBigInteger())
        is Long -> DataValue.Integer(value.toBigInteger())
        is Float -> DataValue.Float(value.toDouble())
        is Double -> DataValue.Float(value)
        is BigInteger -> DataValue.Integer(value)
        is BigDecimal -> DataValue.Decimal(value.toPlainString())
        else -> throw IllegalArgumentException("Unsupported portable numeric constant ${value::class.qualifiedName}.")
    }

val <E : RelationshipEndpoint<*, *>, T : Resource, M : MissingPolicy> Expr<Ref<E, T>, M>.target: Expr<ResourceId, M>
    get() = Expr(ExpressionNode.Call(OperationId("typewriter.link.target"), listOf(node)))

fun <T> emptyListExpression(): Expr<List<T>, Handled> = Expr(ExpressionNode.Literal(DataValue.ListValue(emptyList())))

fun literal(value: com.typewritermc.types.Color): Expr<com.typewritermc.types.Color, Handled> =
    Expr(ExpressionNode.Literal(DataValue.Integer(value.argb.toString().toBigInteger())))
