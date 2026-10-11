package com.typewritermc.configuration

import com.typewritermc.types.DataValue
import com.typewritermc.types.FieldOwner
import com.typewritermc.types.TypeDefinitionId
import kotlinx.serialization.Serializable

@Serializable
enum class InitializationPreference {
    Startup,
    Creation,
}

@Serializable
data class InitializationRequirements(
    val forcedCreation: Boolean,
    val preference: InitializationPreference?,
    val embeddedDependencies: Set<TypeDefinitionId>,
)

@Serializable
data class CapturedDefault(
    val field: FieldOwner,
    val value: DataValue,
)
