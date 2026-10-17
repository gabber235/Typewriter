package com.typewritermc.scripting

import com.typewritermc.types.DeclarationOwner
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeTemplate
import kotlinx.serialization.Serializable

@Serializable
data class OwnedPortableTypes(
    val owner: DeclarationOwner,
    val definitions: List<TypeDefinition>,
)

@Serializable
data class RuntimeMemberTemplate(
    val id: RuntimeMemberId,
    val receiver: TypeTemplate?,
    val arguments: List<TypeTemplate>,
    val result: TypeTemplate,
    val requiredCapabilities: Set<ScriptCapabilityId>,
)
