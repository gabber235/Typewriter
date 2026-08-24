package com.typewritermc.loader.standalone

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactRequirement
import com.typewritermc.imprint.VersionConstraint
import com.typewritermc.loader.HostEntrypoint
import com.typewritermc.loader.HostIdentityStore
import com.typewritermc.loader.LoaderBootstrap
import com.typewritermc.loader.LoaderServiceFactory
import com.typewritermc.loader.RunningHost
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.deployment.HostId
import com.typewritermc.loader.deployment.PrimaryEngineTarget
import com.typewritermc.loader.deployment.RealmLoaderIntent
import com.typewritermc.loader.rollout.ArtifactHost
import com.typewritermc.loader.rollout.ArtifactHostAssignment
import com.typewritermc.loader.rollout.ArtifactHostAssignmentSource
import com.typewritermc.loader.rollout.BackendArtifactHostAssignmentSource
import com.typewritermc.loader.rollout.RealmId
import com.typewritermc.loader.standalone.shell.LoaderConsoleLogOutput
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.koin.serviceTelemetryModule
import io.opentelemetry.api.OpenTelemetry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.flow.flowOf
import org.koin.core.KoinApplication
import org.koin.dsl.koinApplication
import org.koin.dsl.module
import org.koin.dsl.onClose
import java.nio.file.Path

internal class ArtifactLoaderBootstrap(
    private val serviceFactory: LoaderServiceFactory,
    private val settings: LoaderSettings,
) : LoaderBootstrap {
    override suspend fun start(
        entrypoint: HostEntrypoint,
        workDirectory: Path,
        scope: CoroutineScope,
    ): RunningHost {
        val service = serviceFactory.create(workDirectory, scope)
        val identity = HostIdentityStore(workDirectory.resolve("state/host-id"))
        val hostId = HostId(identity.load() ?: "local-${entrypoint.name.lowercase()}".also(identity::save))
        val host =
            ArtifactHost(
                hostId,
                workDirectory,
                service,
                assignments(entrypoint, service),
                scope,
            )
        host.start()
        return RunningHost(service, host::stop)
    }

    private fun assignments(
        entrypoint: HostEntrypoint,
        service: com.typewritermc.loader.LoaderService,
    ): ArtifactHostAssignmentSource {
        val panelEngine =
            ArtifactRequirement(
                ArtifactId(settings.get("TYPEWRITER_PANEL_ENGINE_ID", "typewritermc:panel")),
                VersionConstraint(settings.get("TYPEWRITER_PANEL_ENGINE_VERSION", "^1")),
            )
        val localRealmId = settings.getOrNull("TYPEWRITER_LOCAL_REALM_ID")
        if (entrypoint != HostEntrypoint.STANDALONE || localRealmId == null) {
            return BackendArtifactHostAssignmentSource(service, panelEngine)
        }
        return ArtifactHostAssignmentSource {
            if (entrypoint == HostEntrypoint.STANDALONE) {
                val realmId = RealmId(localRealmId)
                flowOf(
                    ArtifactHostAssignment(
                        realmId = realmId,
                        roles = RuntimePlacement.entries.toSet(),
                        primaryEngine =
                            PrimaryEngineTarget(
                                ArtifactId(settings.get("TYPEWRITER_PRIMARY_ENGINE_ID", "typewritermc:paper")),
                                VersionConstraint(settings.get("TYPEWRITER_PRIMARY_ENGINE_VERSION", "^1")),
                            ),
                        intent =
                            RealmLoaderIntent(
                                panelEngine,
                            ),
                    ),
                )
            } else {
                emptyFlow()
            }
        }
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
fun localLoaderApplication(): LoaderApplication = createLocalLoaderApplication()

private fun createLocalLoaderApplication(): LoaderApplication {
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
                    single<LoaderServiceFactory> { DefaultLoaderServiceFactory(get(), get(), get()) }
                    single<LoaderBootstrap> { ArtifactLoaderBootstrap(get(), settings) }
                },
                serviceTelemetryModule("com.typewritermc.loader", LOADER_VERSION),
            )
        }
    return LoaderApplication(application, application.koin.get(), application.koin.get(), application.koin.get())
}
