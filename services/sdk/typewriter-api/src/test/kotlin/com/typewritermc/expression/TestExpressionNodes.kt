package com.typewritermc.expression

import com.typewritermc.authoring.root
import com.typewritermc.types.requirePortable
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ValuePath

internal fun testInput(
    binding: ExpressionBindingId,
    path: ValuePath = ValuePath.root,
): ExpressionNode = inputExpression<Any, MayBeMissing>(binding, path).toNode()

internal fun testLiteral(value: DataValue): ExpressionNode = ExpressionNode.LiteralWrapper(value.requirePortable())
