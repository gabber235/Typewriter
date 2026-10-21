package com.typewritermc.presentation

import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.CheckedType
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.catalog.RepresentationKind
import skirout.editor.v1.type_catalog.DeclarationOwner
import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.PresentationId

sealed interface PresentationTarget {
    data class Named(
        val type: NamedTypeTemplate,
    ) : PresentationTarget

    data class Representation(
        val kind: RepresentationKind,
    ) : PresentationTarget
}

data class PresentationDescriptor(
    val id: PresentationId,
    val owner: DeclarationOwner,
    val target: PresentationTarget,
    val roles: Set<PresentationRole>,
    val priority: Int,
)

data class RoleFallback(
    val role: PresentationRole,
    val parents: List<PresentationRole>,
)

/** Checks the identity and roles a generated provider declared; selection and fallbacks rely on them. */
fun PresentationDescriptor.requireValid(): PresentationDescriptor =
    apply {
        id.requireValid()
        require(PresentationRole.UNKNOWN !in roles) { "A presentation declares only known roles." }
    }

/** Checks a presentation identity where it enters the catalog; both parts name the provider. */
fun PresentationId.requireValid(): PresentationId =
    apply {
        require(namespace.isNotBlank()) { "Presentation namespace must not be blank." }
        require(name.isNotBlank()) { "Presentation name must not be blank." }
    }

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
