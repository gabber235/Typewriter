package com.typewritermc.capability

import com.typewritermc.types.unknownVariant
import skirout.editor.v1.capability.CapabilityDefinition
import skirout.editor.v1.type_catalog.CapabilityId

/** The identity of the capability this definition declares. */
val CapabilityDefinition.id: CapabilityId
    get() =
        when (this) {
            is CapabilityDefinition.SearchWrapper -> value.capabilityId
            is CapabilityDefinition.ComputationWrapper -> value.capabilityId
            is CapabilityDefinition.CommandWrapper -> value.capabilityId
            is CapabilityDefinition.AuthoringWrapper -> value.capabilityId
            else -> unknownVariant(this)
        }
