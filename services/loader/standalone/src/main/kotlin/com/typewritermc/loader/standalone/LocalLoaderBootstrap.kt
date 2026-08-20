package com.typewritermc.loader.standalone

import com.typewritermc.loader.DeploymentRuntimeFactory
import com.typewritermc.loader.DesiredTopology
import com.typewritermc.loader.HostControlPlane
import com.typewritermc.loader.HostEntrypoint
import com.typewritermc.loader.HostExecutionReport
import com.typewritermc.loader.HostLoader
import com.typewritermc.loader.HostRegistration
import com.typewritermc.loader.LoaderBootstrap
import com.typewritermc.loader.RunningHost
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import java.nio.file.Path

class LocalLoaderBootstrap : LoaderBootstrap {
    override suspend fun start(
        entrypoint: HostEntrypoint,
        workDirectory: Path,
        scope: CoroutineScope,
    ): RunningHost =
        HostLoader(
            entrypoint,
            workDirectory,
            LocalHostControlPlane(entrypoint),
            DeploymentRuntimeFactory { child, _ ->
                error("Local loader mode cannot stage ${child.runtimeId} without a deployment source.")
            },
            scope,
        ).start()
}

private class LocalHostControlPlane(
    private val entrypoint: HostEntrypoint,
) : HostControlPlane {
    private val desired = MutableStateFlow(DesiredTopology(0))

    override suspend fun register(entrypoint: HostEntrypoint): HostRegistration {
        check(entrypoint == this.entrypoint)
        return HostRegistration("local-${entrypoint.name.lowercase()}", entrypoint)
    }

    override fun watchExecution(hostId: String): Flow<DesiredTopology> = desired

    override suspend fun report(
        hostId: String,
        report: HostExecutionReport,
    ) = Unit
}
