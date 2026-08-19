package com.typewritermc.loader

import java.nio.file.Path
import java.time.Instant

interface DeploymentEntrypoint {
    suspend fun start(context: DeploymentContext): DeploymentRuntime
}

interface DeploymentRuntime {
    suspend fun quiesce(deadline: Instant)

    suspend fun stop()
}

interface ReplaceableDeploymentRuntime : DeploymentRuntime {
    suspend fun activate()

    suspend fun resume()
}

data class DeploymentContext(
    val hostId: String,
    val workDirectory: Path,
    val child: DesiredChild,
)

fun interface DeploymentRuntimeFactory {
    suspend fun stage(
        child: DesiredChild,
        context: DeploymentContext,
    ): DeploymentRuntime
}
