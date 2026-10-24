package com.typewritermc.expression

import skirout.editor.v1.expression.ExpressionNode

/** A child occurrence, with the lexical frame introduced only along this edge. */
data class ExpressionChild(
    val index: Int,
    val node: ExpressionNode,
    val frameArity: Int = 0,
)

/**
 * Enumerates syntax children at stable ordinals. A lambda opens its frame of `arity` locals along the edge to its
 * body; call arguments keep their argument positions.
 */
fun ExpressionNode.children(): List<ExpressionChild> =
    when (this) {
        is ExpressionNode.LiteralWrapper, is ExpressionNode.InputWrapper, is ExpressionNode.LocalWrapper -> {
            emptyList()
        }

        is ExpressionNode.FieldWrapper -> {
            listOf(ExpressionChild(0, value.source))
        }

        is ExpressionNode.AndWrapper -> {
            listOf(ExpressionChild(0, value.left), ExpressionChild(1, value.right))
        }

        is ExpressionNode.OrWrapper -> {
            listOf(ExpressionChild(0, value.left), ExpressionChild(1, value.right))
        }

        is ExpressionNode.ConditionalWrapper -> {
            listOf(ExpressionChild(0, value.test), ExpressionChild(1, value.then), ExpressionChild(2, value.otherwise))
        }

        is ExpressionNode.OrElseWrapper -> {
            listOf(ExpressionChild(0, value.value), ExpressionChild(1, value.fallback))
        }

        is ExpressionNode.CallWrapper -> {
            value.arguments.mapIndexed { index, argument -> ExpressionChild(index, argument) }
        }

        is ExpressionNode.LambdaWrapper -> {
            listOf(ExpressionChild(0, value.body, frameArity = value.arity))
        }

        is ExpressionNode.Unknown -> {
            emptyList()
        }
    }

/** This node and every node below it, depth first in child order. */
fun ExpressionNode.descendants(): Sequence<ExpressionNode> =
    sequence {
        val pending = ArrayDeque(listOf(this@descendants))
        while (pending.isNotEmpty()) {
            val node = pending.removeFirst()
            yield(node)
            node.children().asReversed().forEach { pending.addFirst(it.node) }
        }
    }
