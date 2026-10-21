package com.typewritermc.authoring

import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.TypeUse

data class PortableValue(
    val actualType: TypeUse,
    val payload: DataValue,
)
