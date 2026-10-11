package com.typewritermc.types.catalog

import com.typewritermc.configuration.RelativeFieldPattern
import com.typewritermc.types.DeclarationOwner
import com.typewritermc.types.TypeDefinitionId
import kotlinx.serialization.Serializable

@Serializable
data class DeclarationOrigin(
    val owner: DeclarationOwner,
)

@Serializable
data class DeclarationDiagnostic(
    val affected: TypeDefinitionId,
    val code: String,
    val origins: List<DeclarationOrigin> = emptyList(),
    val field: RelativeFieldPattern? = null,
)
