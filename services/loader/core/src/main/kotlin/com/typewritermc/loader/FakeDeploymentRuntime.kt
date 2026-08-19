package com.typewritermc.loader

import java.time.Instant

class FakeDeploymentRuntime(
    val child: DesiredChild,
) : DeploymentRuntime {
    var quiescedAt: Instant? = null
        private set
    var stopped: Boolean = false
        private set

    override suspend fun quiesce(deadline: Instant) {
        check(!stopped) { "A stopped runtime cannot quiesce." }
        quiescedAt = deadline
    }

    override suspend fun stop() {
        stopped = true
    }
}

class FakeDeploymentRuntimeFactory : DeploymentRuntimeFactory {
    private val mutableDeployments = mutableListOf<FakeDeploymentRuntime>()
    val deployments: List<FakeDeploymentRuntime> get() = mutableDeployments.toList()

    override suspend fun stage(
        child: DesiredChild,
        context: DeploymentContext,
    ): DeploymentRuntime = FakeDeploymentRuntime(child).also(mutableDeployments::add)
}
