package com.typewritermc.scripting

import com.typewritermc.types.DeclarationOwner
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import kotlinx.serialization.Serializable

@Serializable
data class ScriptContextDescriptor(
    val types: Set<TypeDefinitionId>,
    val members: Set<RuntimeMemberId>,
    val capabilities: Set<ScriptCapabilityId>,
)

@Serializable
data class PortableRegistration(
    val owner: DeclarationOwner,
    val definitions: List<TypeDefinition>,
)

data class OwnedTypeContribution(
    val owner: DeclarationOwner,
    val definitions: List<TypeDefinition>,
)

fun PortableRegistration.toContribution(): OwnedTypeContribution = OwnedTypeContribution(owner, definitions)

fun Set<RuntimeMemberSignature>.invocableWith(engine: Set<RuntimeMemberSignature>): Set<RuntimeMemberSignature> = intersect(engine)
