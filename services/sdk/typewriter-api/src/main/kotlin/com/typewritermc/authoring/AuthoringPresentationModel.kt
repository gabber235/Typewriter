package com.typewritermc.authoring

import com.typewritermc.types.Color
import com.typewritermc.types.Icon
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypedValueEnvelope
import com.typewritermc.types.TypewriterType

/** Generic presentation subject shared by authoring, search, and reference resolution. */
data class PresentationSubject(
    val content: TypedValueEnvelope,
    val descriptor: TypedValueEnvelope,
    val identity: TypedValueEnvelope,
)

/** Result of resolving one stable resource identity for presentation. */
sealed interface ReferenceResourceResolution {
    data class Resolved(
        val subject: PresentationSubject,
        val compatibleTypes: List<ResolvedTypeRef>,
    ) : ReferenceResourceResolution

    data class Missing(
        val id: ResourceId,
    ) : ReferenceResourceResolution

    data class Unavailable(
        val id: ResourceId,
        val diagnostics: List<ReferenceResourceDiagnostic>,
    ) : ReferenceResourceResolution
}

/** Explains why an existing resource cannot currently produce a typed presentation subject. */
data class ReferenceResourceDiagnostic(
    val code: String,
    val message: String,
)

/** Stable identity input supplied separately from editable presentation content. */
@TypewriterType(id = "214fdb63564640e5bc15c7524f6121ef")
data class ResourceIdentity(
    val id: ResourceId,
    val owner: ResourceId? = null,
)

/** Describes one authored resource family for role presentations. */
@TypewriterType(id = "da03c1ce637d4ee78c4916d304e57bf1")
data class ResourceTypeDescriptor(
    val type: ResolvedTypeRef,
    val name: String,
    val description: String,
    val icon: Icon,
    val color: Color,
)
