package com.typewritermc.loader

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactRequirement
import com.typewritermc.imprint.VersionConstraint
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.deployment.HostId
import com.typewritermc.loader.deployment.PrimaryEngineTarget
import com.typewritermc.loader.deployment.RealmLoaderIntent
import com.typewritermc.loader.rollout.ArtifactHost
import com.typewritermc.loader.rollout.ArtifactHostAssignment
import com.typewritermc.loader.rollout.ArtifactHostAssignmentSource
import com.typewritermc.loader.rollout.BackendArtifactHostAssignmentSource
import com.typewritermc.loader.rollout.DesiredHostExecution
import com.typewritermc.loader.rollout.RealmId
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.koin.serviceTelemetryModule
import io.opentelemetry.api.OpenTelemetry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.flowOf
import org.koin.core.KoinApplication
import org.koin.dsl.koinApplication
import org.koin.dsl.module
import org.koin.dsl.onClose
import java.nio.file.Path

/**
 * Assembles and starts the shared artifact host for a process entrypoint. Restores persistent host identity,
 * creates registration and assignment dependencies, and returns a [RunningHost] whose stop action owns host
 * teardown. Local Realm assignment overrides apply only to the standalone entrypoint.
 */
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
            return BackendArtifactHostAssignmentSource(service, panelEngine, entrypoint)
        }
        return ArtifactHostAssignmentSource {
            flowOf(
                DesiredHostExecution(
                    revision = null,
                    assignment =
                        ArtifactHostAssignment(
                            realmId = RealmId(localRealmId),
                            roles = RuntimePlacement.entries.toSet(),
                            primaryEngine =
                                PrimaryEngineTarget(
                                    ArtifactId(settings.get("TYPEWRITER_PRIMARY_ENGINE_ID", "typewritermc:paper")),
                                    VersionConstraint(settings.get("TYPEWRITER_PRIMARY_ENGINE_VERSION", "^1")),
                                ),
                            intent = RealmLoaderIntent(panelEngine),
                        ),
                ),
            )
        }
    }
}

/**
 * Owns the loader dependency injection container and telemetry SDK for one entrypoint. Its bootstrap creates
 * running hosts using entrypoint supplied directories and coroutine scopes. Close the running host first so
 * runtime shutdown can still use these dependencies and emit telemetry.
 */
class LoaderApplication internal constructor(
    private val application: KoinApplication,
    val bootstrap: LoaderBootstrap,
    val telemetry: ServiceTelemetry,
) : AutoCloseable {
    override fun close() {
        application.close()
    }
}

/**
 * Creates an isolated loader application from process settings and a host supplied logging destination. The
 * returned application owns its telemetry SDK and dependency container; the caller owns closing it after host
 * shutdown.
 */
fun loaderApplication(logOutput: LoaderLogOutput): LoaderApplication = createLoaderApplication(logOutput)

private fun createLoaderApplication(logOutput: LoaderLogOutput): LoaderApplication {
    val settings = LoaderSettings.system()
    val openTelemetry = loaderOpenTelemetry(logOutput, settings.telemetryConfiguration())
    val application =
        koinApplication {
            modules(
                module {
                    single<OpenTelemetry> { openTelemetry } onClose { it?.let(::closeLoaderOpenTelemetry) }
                    single { settings.registrarConfiguration() }
                    single<LoaderServiceFactory> { DefaultLoaderServiceFactory(get(), get(), get()) }
                    single<LoaderBootstrap> { ArtifactLoaderBootstrap(get(), settings) }
                },
                serviceTelemetryModule("com.typewritermc.loader", LOADER_VERSION),
            )
        }
    return LoaderApplication(application, application.koin.get(), application.koin.get())
}
