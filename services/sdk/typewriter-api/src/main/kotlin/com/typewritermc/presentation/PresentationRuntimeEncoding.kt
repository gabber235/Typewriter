package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.types.DataValue
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.binding.BindingRef
import skirout.editor.v1.type_catalog.FieldPathSegment
import java.math.BigInteger
import skirout.editor.v1.presentation.CrossAxisAlignment as WireCrossAxisAlignment
import skirout.editor.v1.presentation.MainAxisAlignment as WireMainAxisAlignment
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
            SkirTypeCodec.encode(ExpressionNode.Literal(DataValue.StringValue(value))).getOrThrow()
        }

        is Boolean -> {
            SkirTypeCodec.encode(ExpressionNode.Literal(DataValue.Boolean(value))).getOrThrow()
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
            SkirTypeCodec.encode(ExpressionNode.Literal(DataValue.Integer(BigInteger(value.toString())))).getOrThrow()
        }

        is Float -> {
            SkirTypeCodec.encode(ExpressionNode.Literal(DataValue.Float(value.toDouble()))).getOrThrow()
        }

        is Double -> {
            SkirTypeCodec.encode(ExpressionNode.Literal(DataValue.Float(value))).getOrThrow()
        }

        is Expr<*, *> -> {
            SkirTypeCodec.encode(value.node).getOrThrow()
        }

        else -> {
            throw IllegalArgumentException("Presentation expressions must be authored expressions or text literals.")
        }
    }

internal fun integerExpression(value: Long): skirout.editor.v1.expression.ExpressionNode =
    SkirTypeCodec.encode(ExpressionNode.Literal(DataValue.Integer(BigInteger.valueOf(value)))).getOrThrow()

internal fun MainAxisAlignment.wire(): WireMainAxisAlignment =
    when (this) {
        MainAxisAlignment.Start -> WireMainAxisAlignment.START
        MainAxisAlignment.Center -> WireMainAxisAlignment.CENTER
        MainAxisAlignment.End -> WireMainAxisAlignment.END
        MainAxisAlignment.SpaceBetween -> WireMainAxisAlignment.SPACE_BETWEEN
        MainAxisAlignment.SpaceAround -> WireMainAxisAlignment.SPACE_AROUND
        MainAxisAlignment.SpaceEvenly -> WireMainAxisAlignment.SPACE_EVENLY
    }

internal fun CrossAxisAlignment.wire(): WireCrossAxisAlignment =
    when (this) {
        CrossAxisAlignment.Start -> WireCrossAxisAlignment.START
        CrossAxisAlignment.Center -> WireCrossAxisAlignment.CENTER
        CrossAxisAlignment.End -> WireCrossAxisAlignment.END
        CrossAxisAlignment.Stretch -> WireCrossAxisAlignment.STRETCH
    }

internal fun PresentationBorder.wire(): skirout.editor.v1.presentation.PresentationBorder =
    skirout.editor.v1.presentation.PresentationBorder.createAll(
        color = expression(color),
        width = width,
    )

internal fun PresentationInsets.wire(): skirout.editor.v1.presentation.PresentationInsets =
    skirout.editor.v1.presentation.PresentationInsets.createOnly(
        top = top,
        left = start,
        right = end,
        bottom = bottom,
    )

internal val CONFIGURED_VALUE = ExpressionBindingId("configured_value")
