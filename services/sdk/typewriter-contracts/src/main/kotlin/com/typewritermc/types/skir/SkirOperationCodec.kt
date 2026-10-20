package com.typewritermc.types.skir

import com.typewritermc.operations.ActionTone
import com.typewritermc.operations.DropCandidates
import com.typewritermc.operations.OperationAvailability
import com.typewritermc.operations.OperationCardinality
import com.typewritermc.operations.OperationConfirmation
import com.typewritermc.operations.OperationGroup
import com.typewritermc.operations.OperationInspector
import com.typewritermc.operations.OperationShortcut
import com.typewritermc.operations.OperationTargets
import com.typewritermc.operations.ResolvedResourceOperations
import com.typewritermc.operations.ResourceOperationDefinition
import com.typewritermc.operations.ResourceOperationId
import com.typewritermc.presentation.ButtonVariant
import skirout.editor.v1.presentation.HeaderActionTone
import skirout.editor.v1.operation.OperationAvailability as WireAvailability
import skirout.editor.v1.operation.OperationCardinality as WireCardinality
import skirout.editor.v1.operation.OperationConfirmation as WireConfirmation
import skirout.editor.v1.operation.OperationDrop as WireDrop
import skirout.editor.v1.operation.OperationGroup as WireGroup
import skirout.editor.v1.operation.OperationInspector as WireInspector
import skirout.editor.v1.operation.OperationPresentation as WirePresentation
import skirout.editor.v1.operation.OperationShortcut as WireShortcut
import skirout.editor.v1.operation.OperationTargets as WireTargets
import skirout.editor.v1.operation.ResolvedResourceOperation as WireOperation
import skirout.editor.v1.operation.ResolvedResourceOperations as WireOperations
import skirout.editor.v1.operation.ResourceOperationDefinition as WireDefinition
import skirout.editor.v1.operation.ResourceOperationId as WireId
import skirout.editor.v1.presentation.ButtonVariant as WireButtonVariant
import skirout.editor.v1.resource_operations.DropCandidates as WireDropCandidates
import skirout.editor.v1.type_catalog.CapabilityId as WireCapabilityId
import skirout.editor.v1.type_catalog.ResourceId as WireResourceId

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
            )
        }

    fun encode(value: List<DropCandidates>): SkirConversionResult<List<WireDropCandidates>> =
        captureSkirConversion {
            value.map { candidates ->
                WireDropCandidates(
                    operation = encode(candidates.operation),
                    destinations = candidates.destinations.map { WireResourceId(value = it.value) },
                    complete = candidates.complete,
                )
            }
        }

    fun encode(value: OperationConfirmation): WireConfirmation = value.toWire()
}

internal fun ConversionScope.encode(value: OperationTargets): WireTargets =
    WireTargets(
        subject = encode(value.subject),
        cardinality =
            when (value.cardinality) {
                OperationCardinality.Single -> WireCardinality.SINGLE
                OperationCardinality.Selection -> WireCardinality.SELECTION
            },
    )

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
                inspector =
                    when (val inspector = value.presentation.inspector) {
                        OperationInspector.Hidden -> WireInspector.HIDDEN
                        is OperationInspector.Button -> WireInspector.ButtonWrapper(inspector.variant.toWire())
                    },
                shortcut =
                    value.presentation.shortcut?.let { shortcut ->
                        when (shortcut) {
                            OperationShortcut.Delete -> WireShortcut.DELETE
                        }
                    },
            ),
        targets = encode(value.targets),
        capability = WireCapabilityId(value = value.capability.value),
        drop = value.drop?.let { WireDrop(input = encodeValuePath(it.input), hint = it.hint) },
    )

private fun encode(value: ResourceOperationId): WireId =
    WireId(
        artifact = value.artifact,
        sourcePart = value.sourcePart,
        declaration = value.declaration,
    )

private fun ButtonVariant.toWire(): WireButtonVariant =
    when (this) {
        ButtonVariant.Filled -> WireButtonVariant.FILLED
        ButtonVariant.Outlined -> WireButtonVariant.OUTLINED
        ButtonVariant.Text -> WireButtonVariant.TEXT
    }

private fun OperationConfirmation.toWire() = WireConfirmation(title = title, message = message, confirmationLabel = confirmationLabel)
