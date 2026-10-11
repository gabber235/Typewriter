package com.typewritermc.types

import com.typewritermc.discovery.ContributionKey
import kotlinx.serialization.Serializable

@Serializable
data class TypeParameter(
    val key: ParameterKey,
    val name: String,
    val bounds: List<TypeTemplate> = emptyList(),
) {
    init {
        require(name.isNotBlank()) { "Type parameter name must not be blank." }
    }
}

@Serializable
data class FieldOwner(
    val definition: TypeDefinitionId,
    val name: String,
) {
    init {
        require(name.isNotBlank()) { "Field name must not be blank." }
    }
}

@Serializable
data class FieldDeclaration(
    val owner: FieldOwner,
    val type: TypeTemplate,
    val overrides: List<FieldOwner> = emptyList(),
    val hasConstructorDefault: Boolean = false,
)

@Serializable
data class DeclarationOwner(
    val source: ContributionKey,
    val localIdentity: String,
) {
    init {
        require(localIdentity.isNotBlank()) { "Local declaration identity must not be blank." }
    }
}
