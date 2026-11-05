package com.typewritermc.loader.rollout.testing

import com.typewritermc.loader.deployment.HostDeploymentProjection
import com.typewritermc.loader.deployment.RealmDeploymentSelection
import com.typewritermc.loader.deployment.projectFor
import com.typewritermc.loader.testing.FIXTURE_VERSION
import com.typewritermc.services.libs.registrar.ServiceId

fun projection(): HostDeploymentProjection =
    deploymentSnapshot().projectFor(
        "realm",
        RealmDeploymentSelection(HOST, setOf(HOST), mapOf(HOST to FIXTURE_VERSION)),
        HOST,
        deploymentManifests(),
    )

private val HOST = ServiceId("combined")
