package com.typewritermc.presentation

import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.requireValid
import skirout.editor.v1.catalog.PresentationDescriptor
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.catalog.PresentationTarget
import skirout.editor.v1.catalog.RepresentationKind
import skirout.editor.v1.type_catalog.DeclarationOwner
import skirout.editor.v1.type_catalog.PresentationId

/** A presentation descriptor with its [roles] in role order, the canonical form the catalog publishes. */
fun PresentationDescriptor.Companion.of(
    id: PresentationId,
    owner: DeclarationOwner,
    target: PresentationTarget,
    roles: Set<PresentationRole>,
    priority: Int,
): PresentationDescriptor =
    PresentationDescriptor(id = id, owner = owner, target = target, roles = roles.sortedBy { it.kind.ordinal }, priority = priority)

/** Checks the identity and roles a generated provider declared; selection and fallbacks rely on them. */
fun PresentationDescriptor.requireValid(): PresentationDescriptor =
    apply {
        id.requireValid()
        owner.requireValid()
        target.requireValid()
        require(PresentationRole.UNKNOWN !in roles) { "A presentation declares only known roles." }
        require(roles == roles.distinct().sortedBy { it.kind.ordinal }) { "Presentation roles must be unique and in role order." }
    }

/** Checks the named template or the known representation kind a presentation targets. */
fun PresentationTarget.requireValid(): PresentationTarget =
    apply {
        when (this) {
            is PresentationTarget.NamedWrapper -> value.requireValid()
            is PresentationTarget.RepresentationWrapper -> require(value != RepresentationKind.UNKNOWN) { "Unknown representation kind." }
            else -> throw IllegalArgumentException("Unknown presentation target.")
        }
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
