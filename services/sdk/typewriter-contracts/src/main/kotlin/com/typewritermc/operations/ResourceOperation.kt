package com.typewritermc.operations

import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.ValuePath
import com.typewritermc.capability.CapabilityId
import com.typewritermc.presentation.ButtonVariant
import com.typewritermc.types.ResourceTarget

/**
 * Identifies one declared operation object independently of labels and catalog incarnations. [declaration] is the
 * fully qualified name of the object.
 */
data class ResourceOperationId(
    val artifact: String,
    val sourcePart: String,
    val declaration: String,
) {
    init {
        require(listOf(artifact, sourcePart, declaration).all(String::isNotBlank))
    }

    /** The authoring capability that prepares this operation. */
    val capability: CapabilityId
        get() = CapabilityId(listOf(artifact, sourcePart, declaration).joinToString(":") { "${it.length}:$it" })

    /**
     * The search capability that offers the declared candidates of the input field at [field]. Editors derive it the
     * same way: the operation capability, then `/candidates/`, then the field names of [field] joined by `.`.
     */
    fun candidateSearch(field: ValuePath): CapabilityId =
        CapabilityId(
            "${capability.value}/candidates/" +
                field.segments.joinToString(".") { segment ->
                    require(segment is PathSegment.Field) { "Candidate fields are addressed by field names only." }
                    segment.name
                },
        )
}

/** The resources an operation applies to and how many it accepts at once. */
data class OperationTargets(
    val subject: ResourceTarget,
    val cardinality: OperationCardinality,
)

enum class OperationCardinality { Single, Selection }

enum class ActionTone { Neutral, Destructive }

/** Menu sections, in display order. */
enum class OperationGroup { Edit, Organize, Destructive }

/** Inspector presence of an operation. Menus, shortcuts and drops ignore it. */
sealed interface OperationInspector {
    data object Hidden : OperationInspector

    data class Button(
        val variant: ButtonVariant = ButtonVariant.Outlined,
    ) : OperationInspector
}

/** Keyboard gestures an operation can claim. */
enum class OperationShortcut { Delete, }

data class OperationConfirmation(
    val title: String,
    val message: String,
    val confirmationLabel: String,
) {
    init {
        require(title.isNotBlank() && message.isNotBlank() && confirmationLabel.isNotBlank())
    }
}

/** Shared operation appearance. The tone follows the group: destructive operations look destructive everywhere. */
data class OperationPresentation(
    val label: String,
    val description: String = "",
    val icon: String? = null,
    val group: OperationGroup = OperationGroup.Edit,
    val order: Int = 0,
    val confirmation: OperationConfirmation? = null,
    val inspector: OperationInspector = OperationInspector.Button(),
    val shortcut: OperationShortcut? = null,
) {
    init {
        require(label.isNotBlank()) { "An operation requires a visible label." }
        require(icon == null || icon.isNotBlank()) { "An operation icon cannot be blank." }
    }

    val tone: ActionTone
        get() = if (group == OperationGroup.Destructive) ActionTone.Destructive else ActionTone.Neutral
}

/** The input field a resource dropped onto another resource fills with the resource dropped onto, and the hover hint. */
data class OperationDrop(
    val input: ValuePath,
    val hint: String,
) {
    init {
        require(hint.isNotBlank()) { "A drop hint cannot be blank." }
    }
}

data class ResourceOperationDefinition(
    val id: ResourceOperationId,
    val presentation: OperationPresentation,
    val targets: OperationTargets,
    val drop: OperationDrop? = null,
) {
    /** Every catalog operation is an authoring action prepared through this capability. */
    val capability: CapabilityId get() = id.capability
}

sealed interface OperationAvailability {
    data object Hidden : OperationAvailability

    data class Disabled(
        val reason: String,
    ) : OperationAvailability {
        init {
            require(reason.isNotBlank()) { "A disabled operation requires a reason." }
        }
    }

    data object Enabled : OperationAvailability
}

data class ResolvedResourceOperation(
    val definition: ResourceOperationDefinition,
    val availability: OperationAvailability,
)

data class ResolvedResourceOperations(
    val operations: List<ResolvedResourceOperation>,
)

/** Destinations one operation accepts for dragged resources. [complete] is false when the list was capped. */
data class DropCandidates(
    val operation: ResourceOperationId,
    val destinations: List<com.typewritermc.types.ResourceId>,
    val complete: Boolean,
)
