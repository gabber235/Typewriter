package com.typewritermc.authoring

import com.typewritermc.types.Color
import com.typewritermc.types.Icon
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeUse
import com.typewritermc.types.TypewriterType

/** Generic presentation subject shared by authoring, search, and reference resolution. */
data class PresentationSubject(
    val resource: ResourceId,
    val content: DraftBinding,
    val descriptor: ResourceTypeDescriptor,
)

/** Result of resolving one stable resource identity for presentation. */
sealed interface ReferenceResourceResolution {
    data class Resolved(
        val subject: PresentationSubject,
        val compatibleTypes: List<TypeUse.Named>,
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

/** Describes one authored resource family for role presentations. */
@TypewriterType(id = "da03c1ce637d4ee78c4916d304e57bf1")
data class ResourceTypeDescriptor(
    val name: String,
    val description: String,
    val icon: Icon,
    val color: Color,
)
