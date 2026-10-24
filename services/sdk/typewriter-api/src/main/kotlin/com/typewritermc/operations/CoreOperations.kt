package com.typewritermc.operations

import com.typewritermc.authoring.PlacementAnchor
import com.typewritermc.presentation.ButtonVariant
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypewriterType

/** Deletes the selected resources together with everything they own. Singletons cannot be deleted. */
object Delete : ResourceOperation<Unit> {
    override fun ResourceOperationSpec<Unit>.declare(): PreparedOperation {
        appearance {
            icon("mdi:delete-outline")
            group(OperationGroup.Destructive)
            inspector(OperationInspector.Button(ButtonVariant.Filled))
        }
        confirm("Delete the selected resources and their owned contents?") { title("Delete resources") }
        gestures { shortcut(OperationShortcut.Delete) }
        availableWhen { if (subjects.any { it.isSingleton }) OperationAvailability.Hidden else OperationAvailability.Enabled }
        return prepare { subjects.delete() }
    }
}

/** Copies the selected resources with everything they own under their current owners, then selects the copies. */
object Duplicate : ResourceOperation<Unit> {
    override fun ResourceOperationSpec<Unit>.declare(): PreparedOperation {
        appearance {
            icon("mdi:content-copy")
            group(OperationGroup.Organize, order = 40)
        }
        availableWhen {
            if (subjects.any { it.isSingleton }) OperationAvailability.Hidden else subjects.cloneability.availability()
        }
        return prepare { selectAfterStaging(subjects.duplicate()) }
    }
}

/** [anchor] places graph members at the drop point on a graph canvas; pickers leave it empty. */
@TypewriterType(id = "4a3d713ca8304a17b19a1faf4a075f49")
data class MoveToOwnerInput(
    val destination: ResourceId,
    val anchor: PlacementAnchor? = null,
)

/**
 * Moves the selected resources to another owner of the same ownership relation: an element into a page, a page into a
 * book. Priorities and every other field stay as they are; graph members get a free placement in a graph layout.
 */
object MoveToOwner : ResourceOperation<MoveToOwnerInput> {
    override fun ResourceOperationSpec<MoveToOwnerInput>.declare(): PreparedOperation {
        appearance {
            label("Move to")
            icon("mdi:folder-move-outline")
            group(OperationGroup.Organize, order = 10)
        }
        input {
            MoveToOwnerInputFields.destination {
                candidates {
                    subjects
                        .map { it.ownerCandidates().toSet() - setOfNotNull(it.owner) }
                        .reduceOrNull(Set<ResourceId>::intersect)
                        .orEmpty()
                        .asSequence()
                }
                accepts { destination -> subjects.all { it.owner != destination && destination in it.ownerCandidates() } }
                fillOnDrop(hint = "Move here")
            }
        }
        availableWhen {
            if (subjects.any { !it.canBeOwned || it.isSingleton }) OperationAvailability.Hidden else OperationAvailability.Enabled
        }
        return prepare { subjects.moveTo(destination = input.destination, anchor = input.anchor) }
    }
}

@TypewriterType(id = "e719cd67b7bb4cc096e17149ec4f0a91")
data class LinkWithInput(
    val target: ResourceId,
)

/**
 * Links the selected resources with a target through a non owning relation. The dragged side holds the link when it
 * can, so a tag dropped onto a tag becomes its child and a tag dropped onto a book joins the book's tags.
 */
object LinkWith : ResourceOperation<LinkWithInput> {
    override fun ResourceOperationSpec<LinkWithInput>.declare(): PreparedOperation {
        appearance {
            icon("mdi:link-variant")
            group(OperationGroup.Organize, order = 20)
        }
        input {
            LinkWithInputFields.target {
                candidates { subjects.linkTargets().filter { target -> subjects.any { !it.isLinkedWith(target) } } }
                fillOnDrop(hint = "Link")
            }
        }
        availableWhen {
            when {
                subjects.any { it.isSingleton } -> OperationAvailability.Hidden
                subjects.linkTargets().none() -> OperationAvailability.Hidden
                else -> OperationAvailability.Enabled
            }
        }
        return prepare { subjects.linkWith(input.target) }
    }
}

@TypewriterType(id = "e4bde42e41b64ab59188d4da3ee9cc80")
data class UnlinkInput(
    val target: ResourceId,
)

/** Removes the links between the selected resources and a target, whichever side holds them. */
object Unlink : ResourceOperation<UnlinkInput> {
    override fun ResourceOperationSpec<UnlinkInput>.declare(): PreparedOperation {
        appearance {
            icon("mdi:link-variant-off")
            group(OperationGroup.Organize, order = 30)
        }
        input {
            UnlinkInputFields.target {
                candidates { subjects.asSequence().flatMap { it.links() }.distinct() }
                fillOnDrop(hint = "Unlink")
            }
        }
        availableWhen {
            if (subjects.all { it.links().none() }) OperationAvailability.Hidden else OperationAvailability.Enabled
        }
        return prepare { subjects.unlinkFrom(input.target) }
    }
}

/** Duplicates one resource and links the original with its copy, such as a tag that becomes the parent of its copy. */
object LinkWithDuplicate : ResourceOperation<Unit> {
    override fun ResourceOperationSpec<Unit>.declare(): PreparedOperation {
        appearance {
            icon("mdi:link-variant-plus")
            group(OperationGroup.Organize, order = 50)
        }
        singleSubject()
        availableWhen {
            val subject = subjects.single()
            if (subject.isSingleton) return@availableWhen OperationAvailability.Hidden
            when (subject.linkCapacity) {
                LinkCapacity.None -> OperationAvailability.Hidden
                LinkCapacity.Full -> OperationAvailability.Disabled("No compatible outgoing reference has room for another link")
                LinkCapacity.Available -> subjects.cloneability.availability()
            }
        }
        return prepare {
            val copy = subjects.duplicate().single()
            subjects.linkWith(copy)
            selectAfterStaging(listOf(copy))
        }
    }
}

private fun Cloneability.availability(): OperationAvailability =
    when (this) {
        Cloneability.Allowed -> OperationAvailability.Enabled
        is Cloneability.Blocked -> OperationAvailability.Disabled(reason)
    }
