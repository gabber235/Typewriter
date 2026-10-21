package com.typewritermc.types.catalog

import com.typewritermc.configuration.RelativeFieldPattern
import skirout.editor.v1.type_catalog.DeclarationOwner
import skirout.editor.v1.type_catalog.TypeDefinitionId

data class DeclarationOrigin(
    val owner: DeclarationOwner,
)

data class DeclarationDiagnostic(
    val affected: TypeDefinitionId,
    val code: String,
    val origins: List<DeclarationOrigin> = emptyList(),
    val field: RelativeFieldPattern? = null,
)
