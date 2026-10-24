package com.typewritermc.operations

import com.typewritermc.authoring.PlacementAnchor
import com.typewritermc.types.ResourceId

/**
 * Catalog and graph facts that operation availability and candidates read, against the invocation's working graph.
 * Every read is recorded as an observation, so a preview built from these facts is rejected when they change.
 * Operation scopes provide this as a context; read it through the extensions on [ResourceId].
 */
interface AuthoringGraphFacts {
    /** The immediate owner; the planner allows at most one (`multiple_immediate_owners`). */
    fun ownerOf(id: ResourceId): ResourceId?

    /**
     * Resources that could own [id] through the ownership it holds today, including its current owner. A resource
     * without an owner has no candidates, and a resource never becomes the owner of its own ownership closure.
     */
    fun ownerCandidatesOf(id: ResourceId): Sequence<ResourceId>

    /** Whether the type of [id] is the member side of some ownership relation. The realm root never is. */
    fun canBeOwned(id: ResourceId): Boolean

    /** The realm root or a section: created by the realm, never deleted, duplicated or moved. */
    fun isSingleton(id: ResourceId): Boolean

    /**
     * Resources every one of [ids] is linked with or can gain a link to through a non owning relation. The dragged
     * side holds a link first: a subject that declares a binding for a relation links through it, and only a subject
     * without one links through the target's binding.
     */
    fun linkTargetsOf(ids: List<ResourceId>): Sequence<ResourceId>

    /** Resources linked with [id] through non owning relations, whichever side holds each link. */
    fun linksOf(id: ResourceId): Sequence<ResourceId>

    /** Whether [id] and [target] are linked through a non owning relation, whichever of them holds the link. */
    fun isLinked(
        id: ResourceId,
        target: ResourceId,
    ): Boolean

    /** Room in the non owning bindings of [id] for a link to another resource of its own type, such as its copy. */
    fun linkCapacityOf(id: ResourceId): LinkCapacity

    /** Whether the ownership closures of [roots] can be copied without breaking an outside reference. */
    fun cloneabilityOf(roots: List<ResourceId>): Cloneability
}

/**
 * High level graph edits staged into the invocation's working graph. Choices between several bindings and the
 * invocation origin come from the preparation session, so a missing choice aborts the attempt with [NeedsChoices].
 */
interface AuthoringGraphEdits {
    /** Deletes [ids] together with everything they own. */
    suspend fun delete(ids: List<ResourceId>)

    /** Copies the ownership closures of [roots] under their current owners and returns the copied roots in order. */
    suspend fun duplicate(roots: List<ResourceId>): List<ResourceId>

    /**
     * Transfers ownership of [ids] to [destination], keeping every other field, including priorities. When the
     * destination is a graph layout, moved members receive a free graph placement near [anchor].
     */
    suspend fun move(
        ids: List<ResourceId>,
        destination: ResourceId,
        anchor: PlacementAnchor?,
    )

    /** Links each of [ids] with [target], the dragged side first. Already linked resources are left unchanged. */
    suspend fun link(
        ids: List<ResourceId>,
        target: ResourceId,
    )

    /** Removes every non owning link between each of [ids] and [target], whichever side holds it. */
    suspend fun unlink(
        ids: List<ResourceId>,
        target: ResourceId,
    )
}

/** Room for one more link of a resource to a resource of its own type. */
enum class LinkCapacity {
    /** No non owning binding accepts a resource of this type. */
    None,

    /** Every binding that accepts one is already filled. */
    Full,

    /** At least one binding can take another link. */
    Available,
}

sealed interface Cloneability {
    data object Allowed : Cloneability

    data class Blocked(
        val reason: String,
    ) : Cloneability
}

context(facts: AuthoringGraphFacts)
val ResourceId.owner: ResourceId? get() = facts.ownerOf(this)

context(facts: AuthoringGraphFacts)
val ResourceId.canBeOwned: Boolean get() = facts.canBeOwned(this)

context(facts: AuthoringGraphFacts)
val ResourceId.isSingleton: Boolean get() = facts.isSingleton(this)

context(facts: AuthoringGraphFacts)
fun ResourceId.ownerCandidates(): Sequence<ResourceId> = facts.ownerCandidatesOf(this)

context(facts: AuthoringGraphFacts)
fun ResourceId.links(): Sequence<ResourceId> = facts.linksOf(this)

context(facts: AuthoringGraphFacts)
fun ResourceId.isLinkedWith(target: ResourceId): Boolean = facts.isLinked(this, target)

context(facts: AuthoringGraphFacts)
val ResourceId.linkCapacity: LinkCapacity get() = facts.linkCapacityOf(this)

context(facts: AuthoringGraphFacts)
fun List<ResourceId>.linkTargets(): Sequence<ResourceId> = facts.linkTargetsOf(this)

context(facts: AuthoringGraphFacts)
val List<ResourceId>.cloneability: Cloneability get() = facts.cloneabilityOf(this)

context(edits: AuthoringGraphEdits)
suspend fun List<ResourceId>.delete() = edits.delete(this)

context(edits: AuthoringGraphEdits)
suspend fun List<ResourceId>.duplicate(): List<ResourceId> = edits.duplicate(this)

context(edits: AuthoringGraphEdits)
suspend fun List<ResourceId>.moveTo(
    destination: ResourceId,
    anchor: PlacementAnchor? = null,
) = edits.move(this, destination, anchor)

context(edits: AuthoringGraphEdits)
suspend fun List<ResourceId>.linkWith(target: ResourceId) = edits.link(this, target)

context(edits: AuthoringGraphEdits)
suspend fun List<ResourceId>.unlinkFrom(target: ResourceId) = edits.unlink(this, target)
