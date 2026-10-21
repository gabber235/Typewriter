package com.typewritermc.expression

import com.typewritermc.authoring.ValuePath
import com.typewritermc.types.requirePortable
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.DataValue

internal fun testInput(
    binding: ExpressionBindingId,
    path: ValuePath = ValuePath(),
): ExpressionNode = inputExpression<Any, MayBeMissing>(binding, path).toNode()

internal fun testLiteral(value: DataValue): ExpressionNode = ExpressionNode.LiteralWrapper(value.requirePortable())
