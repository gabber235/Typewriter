package com.typewritermc.authoring

import com.typewritermc.types.DataValue
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeUse
import com.typewritermc.types.immutableCopy
import com.typewritermc.types.immutableListCopy
import com.typewritermc.types.immutableMapCopy

fun TypeSelection.immutableCopy(): TypeSelection =
    when (this) {
        is TypeSelection.Complete -> {
            copy(use = use.immutableCopy() as TypeUse.Named)
        }

        is TypeSelection.Pending -> {
            copy(
                arguments =
                    arguments.immutableListCopy { argument ->
                        when (argument) {
                            is ArgumentSelection.Chosen -> argument.copy(type = argument.type.immutableCopy())
                            ArgumentSelection.Unfilled -> argument
                        }
                    },
            )
        }
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
