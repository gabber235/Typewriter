package com.typewritermc.expression

import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.ValueLocation

/** The value locations expressions read through each binding, the runtime form of the editor expression bindings. */
data class ExpressionBindings(
    val locations: Map<ExpressionBindingId, ValueLocation>,
)
