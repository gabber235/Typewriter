package com.typewritermc.discovery.testing

import com.typewritermc.discovery.DeploymentDiscoverySnapshot
import com.typewritermc.types.TypeId

fun DeploymentDiscoverySnapshot.requireType(id: TypeId) =
    types.definitions.singleOrNull { it.id.id == id }
        ?: error("Expected discovery snapshot to contain type $id.")
