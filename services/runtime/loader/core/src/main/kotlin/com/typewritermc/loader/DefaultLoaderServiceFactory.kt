package com.typewritermc.loader

import com.typewritermc.loader.artifact.FileDigestBlobStore
import com.typewritermc.loader.shared.FileSharedArtifactRepository
import com.typewritermc.loader.shared.SharedArtifactOutboxPublisher
import com.typewritermc.loader.shared.SharedArtifactService
import com.typewritermc.services.libs.registrar.CredentialStorage
import com.typewritermc.services.libs.registrar.RegistrarConfiguration
import com.typewritermc.services.libs.registrar.ServiceRegistrar
import com.typewritermc.services.libs.registrar.console.MordantBindingTokenOutput
import com.typewritermc.services.libs.registrar.console.RegistrarConsoleObserver
import com.typewritermc.services.libs.registrar.koin.registrarModule
import com.typewritermc.services.libs.registrar.storage.FileCredentialStorage
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.utils.CoroutineDelayScheduler
import com.typewritermc.services.libs.utils.RetryPolicy
import io.opentelemetry.api.OpenTelemetry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.launch
import org.koin.dsl.bind
import org.koin.dsl.koinApplication
import org.koin.dsl.module
import java.nio.file.Path
import java.util.concurrent.ConcurrentHashMap
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource

/** Assembles the loader owned registration and NATS runtime for one host process. */
internal class DefaultLoaderServiceFactory(
    private val configuration: RegistrarConfiguration,
    private val telemetry: ServiceTelemetry,
    private val openTelemetry: OpenTelemetry,
) : LoaderServiceFactory {
    override fun create(
        workDirectory: Path,
        scope: CoroutineScope,
    ): LoaderService {
        val application =
            koinApplication {
                modules(
                    module {
                        single { openTelemetry }
                        single { telemetry }
                        single { FileCredentialStorage(workDirectory.resolve("state/service-identity.json")) } bind
                            CredentialStorage::class
                    },
                    registrarModule(
                        configuration,
                        scope,
                        RetryPolicy.exponential(1.seconds, 30.seconds, jitterRatio = .2),
                        CoroutineDelayScheduler,
                        TimeSource.Monotonic,
                    ),
                )
            }
        val registrar = application.koin.get<ServiceRegistrar>()
        val observer = RegistrarConsoleObserver(MordantBindingTokenOutput())
        val observerJob = scope.launch(start = CoroutineStart.UNDISPATCHED) { observer.observe(registrar.states) }
        val artifactsRoot = workDirectory.resolve("artifacts")
        val blobs = FileDigestBlobStore(artifactsRoot, telemetry = telemetry)
        val shared = ConcurrentHashMap<String, SharedArtifactService>()
        val sharedRepositories = ConcurrentHashMap<String, FileSharedArtifactRepository>()
        val sharedPublisher =
            SharedArtifactOutboxPublisher(
                scope,
                registrar.states,
                registrar::communicatorFor,
                sharedRepositories::values,
            )
        return RegistrarLoaderService(
            registrar,
            openTelemetry,
            telemetry,
            { realmId ->
                shared.computeIfAbsent(realmId) {
                    val repository =
                        sharedRepositories.computeIfAbsent(realmId) {
                            FileSharedArtifactRepository(artifactsRoot.resolve("shared").resolve("$realmId.cbor"))
                        }
                    SharedArtifactService(
                        realmId,
                        blobs,
                        repository,
                        telemetry,
                    )
                }
            },
        ) {
            sharedPublisher.stop()
            observerJob.cancelAndJoin()
            application.close()
        }
    }
}
