package com.typewritermc.types.skir

import com.typewritermc.operations.ActionTone
import com.typewritermc.operations.OperationAvailability
import com.typewritermc.operations.OperationConfirmation
import com.typewritermc.operations.OperationGroup
import com.typewritermc.operations.OperationTargets
import com.typewritermc.operations.ResolvedResourceOperations
import com.typewritermc.operations.ResourceOperationContribution
import com.typewritermc.operations.ResourceOperationDefinition
import com.typewritermc.operations.ResourceOperationId
import com.typewritermc.presentation.ButtonVariant
import skirout.editor.v1.presentation.HeaderActionTone
import skirout.editor.v1.operation.OperationAvailability as WireAvailability
import skirout.editor.v1.operation.OperationConfirmation as WireConfirmation
import skirout.editor.v1.operation.OperationGroup as WireGroup
import skirout.editor.v1.operation.OperationPresentation as WirePresentation
import skirout.editor.v1.operation.OperationTargets as WireTargets
import skirout.editor.v1.operation.ResolvedResourceOperation as WireOperation
import skirout.editor.v1.operation.ResolvedResourceOperations as WireOperations
import skirout.editor.v1.operation.ResourceOperationContribution as WireContribution
import skirout.editor.v1.operation.ResourceOperationDefinition as WireDefinition
import skirout.editor.v1.operation.ResourceOperationId as WireId

/** Encodes the same operation definitions retained with the executable catalog. */
object SkirOperationCodec {
    fun encode(value: ResolvedResourceOperations): SkirConversionResult<WireOperations> =
        captureSkirConversion {
            WireOperations(
                operations =
                    value.operations.map { operation ->
                        WireOperation(
                            definition = encode(operation.definition),
                            availability =
                                when (val availability = operation.availability) {
                                    OperationAvailability.Hidden -> WireAvailability.HIDDEN
                                    OperationAvailability.Enabled -> WireAvailability.ENABLED
                                    is OperationAvailability.Disabled -> WireAvailability.DisabledWrapper(availability.reason)
                                },
                        )
                    },
                primaryOperation = value.primaryOperation?.let(::encode),
            )
        }

    fun encode(value: OperationConfirmation): WireConfirmation = value.toWire()
}

internal fun ConversionScope.encode(value: OperationTargets): WireTargets =
    when (value) {
        is OperationTargets.Single -> WireTargets.SingleWrapper(encodeTypeTemplate(value.type))
        is OperationTargets.Selection -> WireTargets.SelectionWrapper(encodeTypeTemplate(value.type))
        OperationTargets.ContributedSingle -> WireTargets.CONTRIBUTED_SINGLE
        OperationTargets.ContributedSelection -> WireTargets.CONTRIBUTED_SELECTION
    }

internal fun ConversionScope.encode(value: ResourceOperationDefinition): WireDefinition =
    WireDefinition(
        id = encode(value.id),
        presentation =
            WirePresentation(
                label = value.presentation.label,
                description = value.presentation.description,
                icon = value.presentation.icon.orEmpty(),
                group =
                    when (value.presentation.group) {
                        OperationGroup.Navigation -> WireGroup.NAVIGATION
                        OperationGroup.Edit -> WireGroup.EDIT
                        OperationGroup.Organize -> WireGroup.ORGANIZE
                        OperationGroup.Destructive -> WireGroup.DESTRUCTIVE
                    },
                order = value.presentation.order,
                tone =
                    when (value.presentation.tone) {
                        ActionTone.Neutral -> HeaderActionTone.NEUTRAL
                        ActionTone.Destructive -> HeaderActionTone.DESTRUCTIVE
                    },
                confirmation = value.presentation.confirmation?.toWire(),
                showInInspector = value.presentation.showInInspector,
                variant =
                    when (value.presentation.variant) {
                        ButtonVariant.Filled -> skirout.editor.v1.presentation.ButtonVariant.FILLED
                        ButtonVariant.Outlined -> skirout.editor.v1.presentation.ButtonVariant.OUTLINED
                        ButtonVariant.Text -> skirout.editor.v1.presentation.ButtonVariant.TEXT
                    },
            ),
        targets = encode(value.targets),
        action = value.action,
    )

internal fun ConversionScope.encode(value: ResourceOperationContribution): WireContribution =
    WireContribution(
        target = encodeTypeTemplate(value.target),
        operations = value.operations.map(::encode),
        primary = value.primary?.let(::encode),
    )

private fun encode(value: ResourceOperationId): WireId =
    WireId(
        artifact = value.artifact,
        sourcePart = value.sourcePart,
        declaration = value.declaration,
        local = value.local,
    )

private fun OperationConfirmation.toWire() = WireConfirmation(title = title, message = message, confirmationLabel = confirmationLabel)
