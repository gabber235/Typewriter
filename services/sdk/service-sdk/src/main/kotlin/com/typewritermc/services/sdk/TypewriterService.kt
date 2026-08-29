package com.typewritermc.services.sdk

import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.registrar.CredentialStorage
import com.typewritermc.services.libs.registrar.ReadySession
import com.typewritermc.services.libs.registrar.RegistrarConfiguration
import com.typewritermc.services.libs.registrar.RegistrarResult
import com.typewritermc.services.libs.registrar.RegistrarSnapshot
import com.typewritermc.services.libs.registrar.RegistrarState
import com.typewritermc.services.libs.registrar.RegistrarStopResult
import com.typewritermc.services.libs.registrar.ServiceRegistrar
import com.typewritermc.services.libs.registrar.koin.registrarModule
import com.typewritermc.services.libs.registrar.storage.FileCredentialStorage
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.utils.CoroutineDelayScheduler
import com.typewritermc.services.libs.utils.RetryPolicy
import io.opentelemetry.api.OpenTelemetry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.StateFlow
import org.koin.core.KoinApplication
import org.koin.dsl.bind
import org.koin.dsl.koinApplication
import org.koin.dsl.module
import java.nio.file.Path
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource

/** One supported Typewriter service identity, connection, and lifecycle. */
class TypewriterService private constructor(
    private val registrar: ServiceRegistrar,
    private val application: KoinApplication,
) {
    val states: StateFlow<RegistrarSnapshot> = registrar.states

    suspend fun start(): RegistrarResult<ReadySession> {
        val start = registrar.start()
        if (start is RegistrarResult.Failure) return start
        return registrar.awaitReady()
    }

    suspend fun communicator(): RegistrarResult<Communicator> {
        val ready =
            states.value.state as? RegistrarState.Ready
                ?: return RegistrarResult.Failure(
                    com.typewritermc.services.libs.registrar.RegistrarFailure
                        .Internal("service_not_ready"),
                )
        return registrar.communicatorFor(ready.connectionGeneration)
    }

    suspend fun communicatorFor(connectionGeneration: Long): RegistrarResult<Communicator> = registrar.communicatorFor(connectionGeneration)

    suspend fun rotateAuthorization(): RegistrarResult<Long> = registrar.rotateAuthorization()

    suspend fun releaseAuthorizationRotation(connectionGeneration: Long): RegistrarResult<Unit> =
        registrar.releaseAuthorizationRotation(connectionGeneration)

    suspend fun stop(): RegistrarStopResult {
        val result = registrar.stop()
        application.close()
        return result
    }

    companion object {
        @JvmStatic
        fun create(
            configuration: RegistrarConfiguration,
            stateDirectory: Path,
            scope: CoroutineScope,
            telemetry: ServiceTelemetry,
            openTelemetry: OpenTelemetry,
        ): TypewriterService {
            val application =
                koinApplication {
                    modules(
                        module {
                            single { openTelemetry }
                            single { telemetry }
                            single { FileCredentialStorage(stateDirectory.resolve("service-identity.json")) } bind
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
            return TypewriterService(application.koin.get(), application)
        }
    }
}
