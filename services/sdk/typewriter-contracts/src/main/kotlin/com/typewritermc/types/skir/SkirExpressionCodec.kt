package com.typewritermc.types.skir

import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.expression.OperationId
import com.typewritermc.presentation.ExpressionNode
import skirout.editor.v1.expression.ExpressionNode as WireExpression

/** Decodes portable action expressions with the same bounded traversal as authored values. */
object SkirExpressionCodec {
    fun decode(expression: WireExpression): SkirConversionResult<ExpressionNode> = captureSkirConversion { expression.decodeNode() }
}

context(scope: ConversionScope)
private fun WireExpression.decodeNode(): ExpressionNode =
    scope.withinValueDepth {
        when (val node = this) {
            is WireExpression.LiteralWrapper -> {
                ExpressionNode.Literal(SkirDataValueCodec.decode(node.value).getOrThrow())
            }

            is WireExpression.ReadWrapper -> {
                ExpressionNode.Read(
                    ExpressionBindingId(node.value.binding.value),
                    SkirAuthoringValueCodec.decode(node.value.path).getOrThrow(),
                )
            }

            is WireExpression.CallWrapper -> {
                ExpressionNode.Call(OperationId(node.value.operation.value), node.value.arguments.map { it.decodeNode() })
            }

            is WireExpression.AndWrapper -> {
                ExpressionNode.And(node.value.left.decodeNode(), node.value.right.decodeNode())
            }

            is WireExpression.OrWrapper -> {
                ExpressionNode.Or(node.value.left.decodeNode(), node.value.right.decodeNode())
            }

            is WireExpression.ConditionalWrapper -> {
                ExpressionNode.Conditional(node.value.test.decodeNode(), node.value.yes.decodeNode(), node.value.no.decodeNode())
            }

            is WireExpression.OrElseWrapper -> {
                ExpressionNode.OrElse(node.value.input.decodeNode(), node.value.fallback.decodeNode())
            }

            is WireExpression.CollectionWrapper -> {
                ExpressionNode.Collection(
                    OperationId(node.value.operation.value),
                    node.value.input.decodeNode(),
                    node.value.bindings.map { ExpressionBindingId(it.value) },
                    node.value.arguments.map { it.decodeNode() },
                    node.value.body?.decodeNode(),
                )
            }

            else -> {
                scope.fail("Unknown portable expression variant.")
            }
        }
    }
