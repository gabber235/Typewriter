package com.typewritermc.operations

import com.typewritermc.capability.CapabilityId
import com.typewritermc.presentation.ButtonVariant
import com.typewritermc.types.TypeTemplate
import kotlinx.serialization.Serializable
import skirout.editor.v1.action.EditorAction

/** Identifies a declaration independently of labels and catalog incarnations. */
data class ResourceOperationId(
    val artifact: String,
    val sourcePart: String,
    val declaration: String,
    val local: String,
) {
    init {
        require(listOf(artifact, sourcePart, declaration, local).all(String::isNotBlank))
    }

    val capability: CapabilityId
        get() = CapabilityId(listOf(artifact, sourcePart, declaration, local).joinToString(":") { "${it.length}:$it" })
}

@Serializable
sealed interface OperationTargets {
    @Serializable
    data class Single(
        val type: TypeTemplate.Named,
    ) : OperationTargets

    @Serializable
    data class Selection(
        val type: TypeTemplate.Named,
    ) : OperationTargets

    @Serializable
    data object ContributedSingle : OperationTargets

    @Serializable
    data object ContributedSelection : OperationTargets
}

enum class ActionTone { Neutral, Destructive }

enum class OperationGroup { Navigation, Edit, Organize, Destructive }

data class OperationConfirmation(
    val title: String,
    val message: String,
    val confirmationLabel: String,
) {
    init {
        require(title.isNotBlank() && message.isNotBlank() && confirmationLabel.isNotBlank())
    }
}

/** Shared operation appearance. Tone applies to both surfaces; variant controls inspector emphasis only. */
data class OperationPresentation(
    val label: String,
    val description: String = "",
    val icon: String? = null,
    val group: OperationGroup = OperationGroup.Edit,
    val order: Int = 0,
    val confirmation: OperationConfirmation? = null,
    val tone: ActionTone = ActionTone.Neutral,
    val variant: ButtonVariant = ButtonVariant.Outlined,
    val showInInspector: Boolean = true,
) {
    init {
        require(label.isNotBlank()) { "An operation requires a visible label." }
        require(icon == null || icon.isNotBlank()) { "An operation icon cannot be blank." }
    }
}

data class ResourceOperationDefinition(
    val id: ResourceOperationId,
    val presentation: OperationPresentation,
    val targets: OperationTargets,
    val action: EditorAction,
)

data class ResourceOperationContribution(
    val target: TypeTemplate.Named,
    val operations: List<ResourceOperationId>,
    val primary: ResourceOperationId? = null,
) {
    init {
        require(operations.distinct().size == operations.size) { "A contribution cannot repeat an operation." }
        require(primary == null || primary in operations) { "A primary action must be contributed." }
    }
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
    val primaryOperation: ResourceOperationId?,
)
