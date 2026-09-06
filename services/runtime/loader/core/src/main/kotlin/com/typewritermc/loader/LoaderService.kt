package com.typewritermc.loader

import com.typewritermc.loader.api.artifact.SharedArtifactAccess
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.registrar.ReadySession
import com.typewritermc.services.libs.registrar.RegistrarResult
import com.typewritermc.services.libs.registrar.RegistrarSnapshot
import com.typewritermc.services.libs.registrar.RegistrarStopResult
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.sdk.TypewriterService
import io.opentelemetry.api.OpenTelemetry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.StateFlow
import java.nio.file.Path

typealias LoaderServiceSnapshot = RegistrarSnapshot
typealias LoaderServiceResult<Value> = RegistrarResult<Value>

/**
 * Borrowed service access supplied to managed child deployments. Communicators belong to registrar connection
 * generations and must be reacquired after reconnection. The loader owns registration, authorization rotation, and
 * telemetry lifetime; child consumers use this surface without stopping the service.
 */
interface LoaderServiceConnection {
    val states: StateFlow<LoaderServiceSnapshot>
    val openTelemetry: OpenTelemetry
    val telemetry: ServiceTelemetry

    suspend fun communicatorFor(connectionGeneration: Long): LoaderServiceResult<Communicator>

    suspend fun rotateAuthorization(): LoaderServiceResult<Long>

    suspend fun releaseAuthorizationRotation(connectionGeneration: Long): LoaderServiceResult<Unit>

    fun sharedArtifacts(realmId: String): SharedArtifactAccess
}

/**
 * Owner of registration and its messaging runtime for a loader lifetime. Start returns readiness or a typed
 * registrar failure; stop releases that runtime. Managed children receive [LoaderServiceConnection] so lifecycle
 * authority remains with the host.
 */
interface LoaderService : LoaderServiceConnection {
    suspend fun start(): RegistrarResult<ReadySession>

    suspend fun stop(): RegistrarStopResult
}

/**
 * Adapts [TypewriterService] to loader lifecycle and Realm scoped shared artifact access. Its stop operation
 * always invokes the additional cleanup callback, including when registrar shutdown throws. Telemetry ownership
 * stays with the enclosing loader application.
 */
class RegistrarLoaderService(
    private val service: TypewriterService,
    override val openTelemetry: OpenTelemetry,
    override val telemetry: ServiceTelemetry,
    private val sharedArtifactAccess: (String) -> SharedArtifactAccess,
    private val close: suspend () -> Unit = {},
) : LoaderService {
    override val states: StateFlow<RegistrarSnapshot> = service.states

    override suspend fun start(): RegistrarResult<ReadySession> = service.start()

    override suspend fun communicatorFor(connectionGeneration: Long): RegistrarResult<Communicator> =
        service.communicatorFor(connectionGeneration)

    override suspend fun rotateAuthorization(): RegistrarResult<Long> = service.rotateAuthorization()

    override suspend fun releaseAuthorizationRotation(connectionGeneration: Long): RegistrarResult<Unit> =
        service.releaseAuthorizationRotation(connectionGeneration)

    override fun sharedArtifacts(realmId: String): SharedArtifactAccess = sharedArtifactAccess(realmId)

    override suspend fun stop(): RegistrarStopResult =
        try {
            service.stop()
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
