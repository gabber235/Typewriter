package com.typewritermc.loader.standalone

import com.typewritermc.loader.LoaderService
import com.typewritermc.loader.LoaderServiceFactory
import com.typewritermc.loader.RegistrarLoaderService
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
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource

/** Assembles the loader owned registration and NATS runtime for one host process. */
class DefaultLoaderServiceFactory(
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
        return RegistrarLoaderService(registrar, openTelemetry, telemetry) {
            observerJob.cancelAndJoin()
            application.close()
        }
    }
}
