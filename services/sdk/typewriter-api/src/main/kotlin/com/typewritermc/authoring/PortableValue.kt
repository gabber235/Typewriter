package com.typewritermc.authoring

import com.typewritermc.types.DataValue
import skirout.editor.v1.type_catalog.TypeUse

data class PortableValue(
    val actualType: TypeUse,
    val payload: DataValue,
)
