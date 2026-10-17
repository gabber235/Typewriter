package com.typewritermc.expression

import com.typewritermc.authoring.ValuePath
import com.typewritermc.types.DataValue
import com.typewritermc.types.skir.SkirDataValueCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.expression.ExpressionNode

internal fun testInput(
    binding: ExpressionBindingId,
    path: ValuePath = ValuePath(),
): ExpressionNode = inputExpression<Any, MayBeMissing>(binding, path).toNode()

internal fun testLiteral(value: DataValue): ExpressionNode = ExpressionNode.LiteralWrapper(SkirDataValueCodec.encode(value).getOrThrow())
