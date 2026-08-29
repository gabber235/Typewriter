package com.typewritermc.loader

import com.typewritermc.loader.artifact.FileDigestBlobStore
import com.typewritermc.loader.shared.FileSharedArtifactRepository
import com.typewritermc.loader.shared.SharedArtifactOutboxPublisher
import com.typewritermc.loader.shared.SharedArtifactService
import com.typewritermc.services.libs.registrar.RegistrarConfiguration
import com.typewritermc.services.libs.registrar.console.MordantBindingTokenOutput
import com.typewritermc.services.libs.registrar.console.RegistrarConsoleObserver
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.sdk.TypewriterService
import io.opentelemetry.api.OpenTelemetry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.launch
import java.nio.file.Path
import java.util.concurrent.ConcurrentHashMap

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
        val service =
            TypewriterService.create(
                configuration,
                workDirectory.resolve("state"),
                scope,
                telemetry,
                openTelemetry,
            )
        val observer = RegistrarConsoleObserver(MordantBindingTokenOutput())
        val observerJob = scope.launch(start = CoroutineStart.UNDISPATCHED) { observer.observe(service.states) }
        val artifactsRoot = workDirectory.resolve("artifacts")
        val blobs = FileDigestBlobStore(artifactsRoot, telemetry = telemetry)
        val shared = ConcurrentHashMap<String, SharedArtifactService>()
        val sharedRepositories = ConcurrentHashMap<String, FileSharedArtifactRepository>()
        val sharedPublisher =
            SharedArtifactOutboxPublisher(
                scope,
                service.states,
                service::communicatorFor,
                sharedRepositories::values,
            )
        return RegistrarLoaderService(
            service,
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
        }
    }
}
