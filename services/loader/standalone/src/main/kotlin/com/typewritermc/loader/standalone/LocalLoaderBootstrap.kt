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
import com.typewritermc.loader.LoaderServiceFactory
import com.typewritermc.loader.RunningHost
import com.typewritermc.loader.standalone.shell.LoaderConsoleLogOutput
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.koin.serviceTelemetryModule
import io.opentelemetry.api.OpenTelemetry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import org.koin.core.KoinApplication
import org.koin.dsl.koinApplication
import org.koin.dsl.module
import org.koin.dsl.onClose
import java.nio.file.Path

/** Assembles a [HostLoader] from explicit control plane and deployment runtime factories. */
class LocalLoaderBootstrap(
    private val controlPlaneFactory: HostControlPlaneFactory,
    private val runtimeFactory: DeploymentRuntimeFactory,
    private val serviceFactory: LoaderServiceFactory? = null,
) : LoaderBootstrap {
    override suspend fun start(
        entrypoint: HostEntrypoint,
        workDirectory: Path,
        scope: CoroutineScope,
    ): RunningHost {
        val service = serviceFactory?.create(workDirectory, scope)
        return HostLoader(
            entrypoint,
            workDirectory,
            controlPlaneFactory.create(entrypoint),
            runtimeFactory,
            scope,
            service,
        ).start()
    }
}

/** Owns the isolated Koin container and loader bootstrap for one standalone or Paper entrypoint lifetime. */
class LoaderApplication internal constructor(
    private val application: KoinApplication,
    val bootstrap: LoaderBootstrap,
    val telemetry: ServiceTelemetry,
    val console: LoaderConsoleLogOutput,
) : AutoCloseable {
    override fun close() {
        application.close()
    }
}

/**
 * Creates the minimal local loader application used by scaffold development entrypoints.
 *
 * The local control plane requests no children. Runtime staging therefore fails explicitly until a deployment source is
 * configured, rather than pretending an unavailable runtime started successfully.
 */
fun localLoaderApplication(): LoaderApplication = localLoaderApplication(registerService = true)

internal fun localLoaderApplicationWithoutService(): LoaderApplication = localLoaderApplication(registerService = false)

private fun localLoaderApplication(registerService: Boolean): LoaderApplication {
    val settings = LoaderSettings.system()
    val console = LoaderConsoleLogOutput()
    val openTelemetry = loaderOpenTelemetry(console, settings.telemetryConfiguration())
    val application =
        koinApplication {
            modules(
                module {
                    single { console }
                    single<OpenTelemetry> { openTelemetry } onClose { it?.let(::closeLoaderOpenTelemetry) }
                    single { settings.registrarConfiguration() }
                    single<HostControlPlaneFactory> { HostControlPlaneFactory(::LocalHostControlPlane) }
                    single<DeploymentRuntimeFactory> {
                        DeploymentRuntimeFactory { child, _ ->
                            error("Local loader mode cannot stage ${child.runtimeId} without a deployment source.")
                        }
                    }
                    if (registerService) {
                        single<LoaderServiceFactory> { DefaultLoaderServiceFactory(get(), get(), get()) }
                        single<LoaderBootstrap> { LocalLoaderBootstrap(get(), get(), get()) }
                    } else {
                        single<LoaderBootstrap> { LocalLoaderBootstrap(get(), get()) }
                    }
                },
                serviceTelemetryModule("com.typewritermc.loader", LOADER_VERSION),
            )
        }
    return LoaderApplication(application, application.koin.get(), application.koin.get(), application.koin.get())
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
