package com.typewritermc.expression

import com.typewritermc.expression.operations.PortableOperation
import com.typewritermc.types.integer
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.TypeTemplate
import java.math.BigDecimal
import java.math.BigInteger

/** One argument of a call as the DSL builds it: an expression or a lambda. */
sealed class CallArgument {
    internal abstract fun lowerArgument(environment: ExpressionEnvironment): ExpressionNode
}

/** A lambda argument: one frame of [arity] locals around a body built once from those locals. */
internal class LambdaArgument(
    private val arity: Int,
    body: (List<Expr<Any?, MayBeMissing>>) -> Expr<*, *>,
) : CallArgument() {
    private val frame = LambdaFrame(arity)
    private val body = body(List(arity) { slot -> local(frame, slot) })

    override fun lowerArgument(environment: ExpressionEnvironment): ExpressionNode =
        ExpressionNode.createLambda(arity = arity, body = body.lower(environment.enter(frame)))
}

/** Calls the declared [operation]; the generated DSL is the usual caller. */
internal fun <R, M : MissingPolicy> call(
    operation: PortableOperation,
    vararg arguments: CallArgument,
    typeArguments: List<TypeTemplate> = emptyList(),
): Expr<R, M> {
    val captured = arguments.toList()
    return Expr { environment ->
        ExpressionNode.createCall(
            operation = operation.id,
            typeArguments = typeArguments,
            arguments = captured.map { it.lowerArgument(environment) },
        )
    }
}

/** A one local lambda whose body is written with the local as receiver. */
@Suppress("UNCHECKED_CAST")
internal fun <T> lambda1(body: Expr<T, MayBeMissing>.() -> Expr<*, *>): CallArgument =
    LambdaArgument(1) { (item) -> (item as Expr<T, MayBeMissing>).body() }

/** A one local lambda whose body takes the local as its parameter. */
@Suppress("UNCHECKED_CAST")
internal fun <T> lambdaOf(body: (Expr<T, MayBeMissing>) -> Expr<*, *>): CallArgument =
    LambdaArgument(1) { (item) -> body(item as Expr<T, MayBeMissing>) }

/** A two local lambda. */
@Suppress("UNCHECKED_CAST")
internal fun <A, B> lambda2(body: (Expr<A, MayBeMissing>, Expr<B, MayBeMissing>) -> Expr<*, *>): CallArgument =
    LambdaArgument(2) { (first, second) -> body(first as Expr<A, MayBeMissing>, second as Expr<B, MayBeMissing>) }

/** A literal of a Kotlin number, encoded in its family: integer, float or decimal. */
fun <N : Number> numericLiteral(value: N): Expr<N, Handled> =
    portableLiteral(
        when (value) {
            is Byte, is Short, is Int, is Long -> DataValue.integer(value.toLong())
            is BigInteger -> DataValue.integer(value)
            is Float, is Double -> DataValue.FloatWrapper(value.toDouble())
            is BigDecimal -> DataValue.DecimalWrapper(value.toPlainString())
            else -> throw IllegalArgumentException("Unsupported portable numeric constant ${value::class.qualifiedName}.")
        },
    )
