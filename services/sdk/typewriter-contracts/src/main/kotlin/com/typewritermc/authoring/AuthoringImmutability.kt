package com.typewritermc.authoring

import com.typewritermc.types.DataValue
import com.typewritermc.types.ResourceId
import com.typewritermc.types.immutableCopy
import com.typewritermc.types.immutableListCopy
import com.typewritermc.types.immutableMapCopy
import com.typewritermc.types.immutableSetCopy

/** Skir type values are deeply immutable, so only the argument list needs a copy. */
fun TypeSelection.immutableCopy(): TypeSelection =
    when (this) {
        is TypeSelection.Complete -> this
        is TypeSelection.Pending -> copy(arguments = arguments.immutableListCopy())
    }

fun AuthoringRecord.immutableCopy(): AuthoringRecord =
    copy(
        configuration = configuration.immutableCopy(),
        fields = fields.immutableMapCopy(DataValue::immutableCopy),
    )

fun ValuePath.immutableCopy(): ValuePath = copy(segments = segments.immutableListCopy())

fun LinkOccurrence.immutableCopy(): LinkOccurrence =
    copy(
        id = id.copy(location = id.location.copy(path = id.location.path.immutableCopy())),
        target = target.copy(opposite = target.opposite?.immutableCopy()),
    )

fun Map<ResourceId, AuthoringRecord>.immutableAuthoringCopy(): Map<ResourceId, AuthoringRecord> =
    immutableMapCopy(AuthoringRecord::immutableCopy)

fun PreparationTarget.immutableCopy(): PreparationTarget =
    when (this) {
        is PreparationTarget.Record -> copy(selection = selection.immutableCopy())
        is PreparationTarget.Value -> this
    }

fun PreparedContent.immutableCopy(): PreparedContent =
    when (this) {
        is PreparedContent.Record -> copy(record = record.immutableCopy())
        is PreparedContent.Value -> copy(value = value.immutableCopy())
    }

fun PreparationDraft.immutableCopy(): PreparationDraft =
    copy(
        target = target.immutableCopy(),
        content = content.immutableCopy(),
        pendingDefaults = pendingDefaults.map(ValuePath::immutableCopy).immutableSetCopy(),
        requiredInputs =
            requiredInputs.immutableListCopy {
                it.copy(path = it.path.immutableCopy())
            },
        findings = findings.immutableListCopy { it.copy(relativePath = it.relativePath?.immutableCopy()) },
    )
