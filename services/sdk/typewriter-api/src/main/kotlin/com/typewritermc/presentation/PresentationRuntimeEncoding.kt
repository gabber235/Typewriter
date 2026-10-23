package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.types.field
import com.typewritermc.types.integer
import com.typewritermc.types.requirePortable
import skirout.editor.v1.binding.BindingRef
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.FieldPathSegment
import java.math.BigInteger
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

internal fun PresentationBorder.wire(state: PresentationBuildState): skirout.editor.v1.presentation.PresentationBorder =
    when (this) {
        is PresentationBorder.All -> {
            skirout.editor.v1.presentation.PresentationBorder
                .createAll(color = color.wire(state), width = width)
        }

        is PresentationBorder.Sides -> {
            skirout.editor.v1.presentation.PresentationBorder.createSides(
                top = top?.wire(state),
                start = start?.wire(state),
                end = end?.wire(state),
                bottom = bottom?.wire(state),
            )
        }
    }

private fun PresentationBorder.Side.wire(state: PresentationBuildState) =
    skirout.editor.v1.presentation
        .PresentationBorderSide(color = color.wire(state), width = width)

internal fun PresentationRadius.wire(state: PresentationBuildState): skirout.editor.v1.presentation.PresentationRadius =
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
                .CustomWrapper(state.lower(value, DOUBLE_SLOT))
        }
    }

internal fun PresentationInsets.wire(): skirout.editor.v1.presentation.PresentationInsets =
    skirout.editor.v1.presentation.PresentationInsets.createOnly(
        top = top.pixels,
        left = start.pixels,
        right = end.pixels,
        bottom = bottom.pixels,
    )

internal val CONFIGURED_VALUE = ExpressionBindingId(value = "configured_value")
