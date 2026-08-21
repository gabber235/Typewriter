package com.typewritermc.loader.standalone

import com.typewritermc.loader.DeploymentRuntimeFactory
import com.typewritermc.loader.DesiredTopology
import com.typewritermc.loader.HostControlPlane
import com.typewritermc.loader.HostControlPlaneFactory
import com.typewritermc.loader.HostEntrypoint
import com.typewritermc.loader.HostExecutionReport
import com.typewritermc.loader.HostLoader
import com.typewritermc.loader.HostRegistration
import com.typewritermc.loader.LoaderBootstrap
import com.typewritermc.loader.RunningHost
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import org.koin.core.KoinApplication
import org.koin.dsl.koinApplication
import org.koin.dsl.module
import java.nio.file.Path

class LocalLoaderBootstrap(
    private val controlPlaneFactory: HostControlPlaneFactory,
    private val runtimeFactory: DeploymentRuntimeFactory,
) : LoaderBootstrap {
    override suspend fun start(
        entrypoint: HostEntrypoint,
        workDirectory: Path,
        scope: CoroutineScope,
    ): RunningHost =
        HostLoader(
            entrypoint,
            workDirectory,
            controlPlaneFactory.create(entrypoint),
            runtimeFactory,
            scope,
        ).start()
}

class LoaderApplication internal constructor(
    private val application: KoinApplication,
    val bootstrap: LoaderBootstrap,
) : AutoCloseable {
    override fun close() {
        application.close()
    }
}

fun localLoaderApplication(): LoaderApplication {
    val application =
        koinApplication {
            modules(
                module {
                    single<HostControlPlaneFactory> { HostControlPlaneFactory(::LocalHostControlPlane) }
                    single<DeploymentRuntimeFactory> {
                        DeploymentRuntimeFactory { child, _ ->
                            error("Local loader mode cannot stage ${child.runtimeId} without a deployment source.")
                        }
                    }
                    single<LoaderBootstrap> { LocalLoaderBootstrap(get(), get()) }
                },
            )
        }
    return LoaderApplication(application, application.koin.get())
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
