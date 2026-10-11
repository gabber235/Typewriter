package com.typewritermc.presentation

import com.typewritermc.configuration.RepresentationKind
import com.typewritermc.types.DeclarationOwner
import com.typewritermc.types.PresentationId
import com.typewritermc.types.PresentationRole
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.CheckedType
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
sealed interface PresentationTarget {
    @Serializable
    @SerialName("named")
    data class Named(
        val type: TypeTemplate.Named,
    ) : PresentationTarget

    @Serializable
    @SerialName("representation")
    data class Representation(
        val kind: RepresentationKind,
    ) : PresentationTarget
}

@Serializable
data class PresentationDescriptor(
    val id: PresentationId,
    val owner: DeclarationOwner,
    val target: PresentationTarget,
    val roles: Set<PresentationRole>,
    val priority: Int,
)

@Serializable
data class RoleFallback(
    val role: PresentationRole,
    val parents: List<PresentationRole>,
)

sealed interface PresentationSelection {
    data class Selected(
        val descriptor: PresentationDescriptor,
    ) : PresentationSelection

    data class Missing(
        val role: PresentationRole,
    ) : PresentationSelection

    data class Conflict(
        val candidates: List<PresentationId>,
    ) : PresentationSelection
}

interface PresentationRegistry {
    val catalog: CheckedCatalog

    fun compatibleCandidates(
        role: PresentationRole,
        actual: CheckedType,
    ): List<PresentationDescriptor>

    fun isMoreSpecific(
        left: PresentationTarget,
        right: PresentationTarget,
        actual: CheckedType,
    ): Boolean

    fun isEquivalent(
        left: PresentationTarget,
        right: PresentationTarget,
        actual: CheckedType,
    ): Boolean

    fun fallbacks(role: PresentationRole): List<PresentationRole>

    fun select(
        role: PresentationRole,
        actual: CheckedType,
    ): PresentationSelection
}
