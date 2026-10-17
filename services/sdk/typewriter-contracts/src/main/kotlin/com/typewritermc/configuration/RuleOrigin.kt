package com.typewritermc.configuration

import com.typewritermc.types.TypeDefinitionId
import kotlinx.serialization.Serializable

@Serializable
data class RuleOrigin(
    val owner: TypeDefinitionId,
    val ordinal: Int,
)
