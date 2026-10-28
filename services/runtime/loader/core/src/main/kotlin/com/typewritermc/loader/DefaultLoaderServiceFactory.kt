package com.typewritermc.loader

import com.typewritermc.loader.artifact.FileDigestBlobStore
import com.typewritermc.loader.shared.FileSharedArtifactRepository
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

/**
 * Composes persistent registration, registrar observation, and shared artifact storage for one host. Shared
 * repositories and services are cached by Realm within the created service lifetime. The service close callback
 * joins the registrar observer after registration shutdown. The pending registration token is shown on the console
 * and, only when [registrationTokenFile] is configured, also written to that file resolved against the work
 * directory, so automation can bind a headless host. Production hosts leave it unset and never put the token on disk.
 */
internal class DefaultLoaderServiceFactory(
    private val configuration: RegistrarConfiguration,
    private val telemetry: ServiceTelemetry,
    private val openTelemetry: OpenTelemetry,
    private val registrationTokenFile: Path?,
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
        val console = MordantBindingTokenOutput()
        val observer =
            RegistrarConsoleObserver(
                registrationTokenFile
                    ?.let { BindingTokenOutputs(console, FileBindingTokenOutput(workDirectory.resolve(it))) }
                    ?: console,
            )
        val observerJob = scope.launch(start = CoroutineStart.UNDISPATCHED) { observer.observe(service.states) }
        val artifactsRoot = workDirectory.resolve("artifacts")
        val blobs = FileDigestBlobStore(artifactsRoot, telemetry = telemetry)
        val shared = ConcurrentHashMap<String, SharedArtifactService>()
        return RegistrarLoaderService(
            blobs,
            service,
            openTelemetry,
            telemetry,
            { realmId ->
                shared.computeIfAbsent(realmId) {
                    SharedArtifactService(
                        realmId,
                        blobs,
                        FileSharedArtifactRepository(artifactsRoot.resolve("shared").resolve("$realmId.cbor")),
                        telemetry,
                    )
                }
            },
        ) {
            observerJob.cancelAndJoin()
        }
    }
}
