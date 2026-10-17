package com.typewritermc.scripting

import com.typewritermc.types.TypeUse
import kotlinx.serialization.Serializable

@JvmInline @Serializable
value class RuntimeMemberId(
    val value: String,
)

@JvmInline @Serializable
value class ScriptCapabilityId(
    val value: String,
)

@Serializable
data class RuntimeMemberSignature(
    val id: RuntimeMemberId,
    val receiver: TypeUse?,
    val parameters: List<TypeUse>,
    val result: TypeUse,
    val requiredCapabilities: Set<ScriptCapabilityId>,
)
