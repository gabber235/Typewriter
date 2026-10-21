package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.types.field
import com.typewritermc.types.integer
import com.typewritermc.types.requirePortable
import skirout.editor.v1.binding.BindingRef
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldPathSegment
import java.math.BigInteger
import skirout.editor.v1.type_catalog.ExpressionBindingId as WireExpressionBindingId
import skirout.editor.v1.type_catalog.PathSegment as WirePathSegment
import skirout.editor.v1.type_catalog.ValuePath as WireValuePath

internal fun BindingRef.field(name: String): BindingRef =
    BindingRef(
        path =
            WireValuePath(
                segments =
                    path.segments +
                        WirePathSegment.FieldWrapper(
                            FieldPathSegment(name = name),
                        ),
            ),
        bindingId = bindingId,
    )

internal fun ExpressionBindingId.wire(): WireExpressionBindingId = WireExpressionBindingId(value = value)

internal fun expression(value: Any?): skirout.editor.v1.expression.ExpressionNode =
    when (value) {
        is String -> {
            ExpressionNode.LiteralWrapper(
                DataValue.StringValueWrapper(value),
            )
        }

        is Boolean -> {
            ExpressionNode.LiteralWrapper(
                DataValue.BooleanWrapper(value),
            )
        }

        is Byte -> {
            integerExpression(value.toLong())
        }

        is Short -> {
            integerExpression(value.toLong())
        }

        is Int -> {
            integerExpression(value.toLong())
        }

        is Long -> {
            integerExpression(value)
        }

        is UByte -> {
            integerExpression(value.toLong())
        }

        is UShort -> {
            integerExpression(value.toLong())
        }

        is UInt -> {
            integerExpression(value.toLong())
        }

        is ULong -> {
            ExpressionNode.LiteralWrapper(
                DataValue.integer(BigInteger(value.toString())),
            )
        }

        is Float -> {
            ExpressionNode.LiteralWrapper(
                DataValue.FloatWrapper(value.toDouble()).requirePortable(),
            )
        }

        is Double -> {
            ExpressionNode.LiteralWrapper(
                DataValue.FloatWrapper(value).requirePortable(),
            )
        }

        is Expr<*, *> -> {
            value.toNode()
        }

        else -> {
            throw IllegalArgumentException("Presentation expressions must be authored expressions or text literals.")
        }
    }

internal fun integerExpression(value: Long): skirout.editor.v1.expression.ExpressionNode =
    ExpressionNode.LiteralWrapper(
        DataValue.integer(BigInteger.valueOf(value)),
    )

internal fun PresentationBorder.wire(): skirout.editor.v1.presentation.PresentationBorder =
    when (this) {
        is PresentationBorder.All -> {
            skirout.editor.v1.presentation.PresentationBorder
                .createAll(color = color.wire(), width = width)
        }

        is PresentationBorder.Sides -> {
            skirout.editor.v1.presentation.PresentationBorder.createSides(
                top = top?.wire(),
                start = start?.wire(),
                end = end?.wire(),
                bottom = bottom?.wire(),
            )
        }
    }

private fun PresentationBorder.Side.wire() =
    skirout.editor.v1.presentation
        .PresentationBorderSide(color = color.wire(), width = width)

internal fun PresentationRadius.wire(): skirout.editor.v1.presentation.PresentationRadius =
    when (this) {
        PresentationRadius.None -> {
            skirout.editor.v1.presentation.PresentationRadius.NONE
        }

        PresentationRadius.Small -> {
            skirout.editor.v1.presentation.PresentationRadius.SMALL
        }

        PresentationRadius.Medium -> {
            skirout.editor.v1.presentation.PresentationRadius.MEDIUM
        }

        PresentationRadius.Large -> {
            skirout.editor.v1.presentation.PresentationRadius.LARGE
        }

        is PresentationRadius.Custom -> {
            skirout.editor.v1.presentation.PresentationRadius
                .CustomWrapper(expression(value))
        }
    }

internal fun PresentationInsets.wire(): skirout.editor.v1.presentation.PresentationInsets =
    skirout.editor.v1.presentation.PresentationInsets.createOnly(
        top = top,
        left = start,
        right = end,
        bottom = bottom,
    )

internal val CONFIGURED_VALUE = ExpressionBindingId("configured_value")
