package com.typewritermc.loader

import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.registrar.ReadySession
import com.typewritermc.services.libs.registrar.RegistrarFailure
import com.typewritermc.services.libs.registrar.RegistrarResult
import com.typewritermc.services.libs.registrar.RegistrarSnapshot
import com.typewritermc.services.libs.registrar.RegistrarState
import com.typewritermc.services.libs.registrar.RegistrarStopResult
import com.typewritermc.services.libs.registrar.ServiceRegistrar
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.serviceTelemetry
import io.opentelemetry.api.OpenTelemetry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.nio.file.Path

typealias LoaderServiceSnapshot = RegistrarSnapshot
typealias LoaderServiceResult<Value> = RegistrarResult<Value>

/** Stable access to the loader owned service connection for managed child deployments. */
interface LoaderServiceConnection {
    val states: StateFlow<LoaderServiceSnapshot>
    val openTelemetry: OpenTelemetry
    val telemetry: ServiceTelemetry

    suspend fun communicatorFor(connectionGeneration: Long): LoaderServiceResult<Communicator>
}

/** Owns service registration and its underlying messaging runtime for one loader lifetime. */
interface LoaderService : LoaderServiceConnection {
    suspend fun start(): RegistrarResult<ReadySession>

    suspend fun stop(): RegistrarStopResult
}

/** Adapts the shared registrar to the loader service lifecycle. */
class RegistrarLoaderService(
    private val registrar: ServiceRegistrar,
    override val openTelemetry: OpenTelemetry,
    override val telemetry: ServiceTelemetry,
    private val close: suspend () -> Unit = {},
) : LoaderService {
    override val states: StateFlow<RegistrarSnapshot> = registrar.states

    override suspend fun start(): RegistrarResult<ReadySession> {
        val started = registrar.start()
        if (started is RegistrarResult.Failure) return started
        return registrar.awaitReady()
    }

    override suspend fun communicatorFor(connectionGeneration: Long): RegistrarResult<Communicator> =
        registrar.communicatorFor(connectionGeneration)

    override suspend fun stop(): RegistrarStopResult =
        try {
            registrar.stop()
        } finally {
            close()
        }
}

/** Creates a loader owned registration and messaging lifecycle for one host process. */
fun interface LoaderServiceFactory {
    fun create(
        workDirectory: Path,
        scope: CoroutineScope,
    ): LoaderService
}

object UnavailableLoaderServiceConnection : LoaderServiceConnection {
    private val mutableStates = MutableStateFlow(RegistrarSnapshot(0, 0, RegistrarState.Idle))
    override val states: StateFlow<RegistrarSnapshot> = mutableStates.asStateFlow()
    override val openTelemetry: OpenTelemetry = OpenTelemetry.noop()
    override val telemetry: ServiceTelemetry = openTelemetry.serviceTelemetry("com.typewritermc.loader.unavailable")

    override suspend fun communicatorFor(connectionGeneration: Long): RegistrarResult<Communicator> =
        RegistrarResult.Failure(RegistrarFailure.Internal("loader_service_unavailable"))
}
