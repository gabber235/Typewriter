package com.typewritermc.presentation

import com.typewritermc.authoring.ValuePath
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.expression.ExpressionType
import com.typewritermc.expression.OperationId
import com.typewritermc.types.DataValue
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
sealed interface ExpressionNode {
    @Serializable
    @SerialName("literal")
    data class Literal(
        val value: DataValue,
    ) : ExpressionNode

    @Serializable
    @SerialName("read")
    data class Read(
        val binding: ExpressionBindingId,
        val path: ValuePath,
    ) : ExpressionNode

    @Serializable
    @SerialName("call")
    data class Call(
        val operation: OperationId,
        val arguments: List<ExpressionNode>,
    ) : ExpressionNode

    @Serializable
    @SerialName("and")
    data class And(
        val left: ExpressionNode,
        val right: ExpressionNode,
    ) : ExpressionNode

    @Serializable
    @SerialName("or")
    data class Or(
        val left: ExpressionNode,
        val right: ExpressionNode,
    ) : ExpressionNode

    @Serializable
    @SerialName("conditional")
    data class Conditional(
        val test: ExpressionNode,
        val yes: ExpressionNode,
        val no: ExpressionNode,
    ) : ExpressionNode

    @Serializable
    @SerialName("or_else")
    data class OrElse(
        val input: ExpressionNode,
        val fallback: ExpressionNode,
    ) : ExpressionNode

    @Serializable
    @SerialName("collection")
    data class Collection(
        val operation: OperationId,
        val input: ExpressionNode,
        val bindings: List<ExpressionBindingId>,
        val arguments: List<ExpressionNode>,
        val body: ExpressionNode?,
    ) : ExpressionNode
}

@Serializable
data class OperationDescriptor(
    val id: OperationId,
    val input: List<ExpressionType>,
    val result: ExpressionType,
)
