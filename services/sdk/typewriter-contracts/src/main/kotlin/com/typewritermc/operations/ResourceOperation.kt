package com.typewritermc.operations

import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.ValuePath
import com.typewritermc.capability.CapabilityId
import skirout.editor.v1.operation.OperationAvailability
import skirout.editor.v1.operation.OperationConfirmation
import skirout.editor.v1.operation.OperationDrop
import skirout.editor.v1.operation.OperationGroup
import skirout.editor.v1.operation.OperationInspector
import skirout.editor.v1.operation.OperationPresentation
import skirout.editor.v1.operation.OperationShortcut
import skirout.editor.v1.operation.ResourceOperationId
import skirout.editor.v1.presentation.ButtonVariant
import skirout.editor.v1.presentation.HeaderActionTone

/**
 * The authoring capability that prepares the operation this id identifies. [ResourceOperationId.declaration] is the
 * fully qualified name of the operation object.
 */
val ResourceOperationId.capability: CapabilityId
    get() = CapabilityId(listOf(artifact, sourcePart, declaration).joinToString(":") { "${it.length}:$it" })

/**
 * The search capability that offers the declared candidates of the input field at [field]. Editors derive it the
 * same way: the operation capability, then `/candidates/`, then the field names of [field] joined by `.`.
 */
fun ResourceOperationId.candidateSearch(field: ValuePath): CapabilityId =
    CapabilityId(
        "${capability.value}/candidates/" +
            field.segments.joinToString(".") { segment ->
                require(segment is PathSegment.Field) { "Candidate fields are addressed by field names only." }
                segment.name
            },
    )

/** Checks that every part of the identity is present; the capability derived from it relies on that. */
fun ResourceOperationId.requireValid(): ResourceOperationId =
    apply { require(listOf(artifact, sourcePart, declaration).all(String::isNotBlank)) }

fun OperationConfirmation.requireValid(): OperationConfirmation =
    apply { require(title.isNotBlank() && message.isNotBlank() && confirmationLabel.isNotBlank()) }

/** The tone of an operation in this group: destructive operations look destructive everywhere. */
val OperationGroup.tone: HeaderActionTone
    get() = if (this == OperationGroup.DESTRUCTIVE) HeaderActionTone.DESTRUCTIVE else HeaderActionTone.NEUTRAL

/** Checks the shared appearance an operation declaration built. An empty [OperationPresentation.icon] means no icon. */
fun OperationPresentation.requireValid(): OperationPresentation =
    apply {
        require(label.isNotBlank()) { "An operation requires a visible label." }
        require(icon.isEmpty() || icon.isNotBlank()) { "An operation icon cannot be blank." }
        require(group != OperationGroup.UNKNOWN) { "Unknown operation group." }
        require(tone == group.tone) { "The operation tone follows its group." }
        require(
            when (val inspector = inspector) {
                OperationInspector.HIDDEN -> true
                is OperationInspector.ButtonWrapper -> inspector.value != ButtonVariant.UNKNOWN
                else -> false
            },
        ) { "Unknown operation inspector." }
        require(shortcut != OperationShortcut.UNKNOWN) { "Unknown operation shortcut." }
        confirmation?.requireValid()
    }

fun OperationDrop.requireValid(): OperationDrop = apply { require(hint.isNotBlank()) { "A drop hint cannot be blank." } }

/** Checks availability returned by an operation declaration: a disabled operation explains itself. */
fun OperationAvailability.requireValid(): OperationAvailability =
    apply {
        when (this) {
            OperationAvailability.HIDDEN, OperationAvailability.ENABLED -> Unit
            is OperationAvailability.DisabledWrapper -> require(value.isNotBlank()) { "A disabled operation requires a reason." }
            else -> throw IllegalArgumentException("Unknown operation availability.")
        }
    }
