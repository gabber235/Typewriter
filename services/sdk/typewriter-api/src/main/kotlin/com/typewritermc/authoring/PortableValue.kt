package com.typewritermc.authoring

import com.typewritermc.types.DataValue
import com.typewritermc.types.TypeUse

data class PortableValue(
    val actualType: TypeUse,
    val payload: DataValue,
)
