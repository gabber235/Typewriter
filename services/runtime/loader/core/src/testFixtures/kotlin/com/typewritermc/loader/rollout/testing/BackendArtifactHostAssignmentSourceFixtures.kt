package com.typewritermc.loader.rollout.testing

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactRequirement
import com.typewritermc.imprint.VersionConstraint
import com.typewritermc.loader.HostEntrypoint
import com.typewritermc.loader.LoaderServiceConnection
import com.typewritermc.loader.rollout.BackendArtifactHostAssignmentSource
import com.typewritermc.protocol.transport.ServiceRouteScope
import com.typewritermc.protocol.transport.generated.hostExecutionWatch
import com.typewritermc.protocol.transport.generated.serviceHostRegister
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.transport.InboundMessage
import com.typewritermc.services.libs.communicator.transport.OutboundMessage
import com.typewritermc.services.libs.communicator.transport.TransportResult
import com.typewritermc.services.libs.registrar.OrganizationBinding
import com.typewritermc.services.libs.registrar.ReadySession
import com.typewritermc.services.libs.registrar.RegistrarResult
import com.typewritermc.services.libs.registrar.RegistrarSnapshot
import com.typewritermc.services.libs.registrar.RegistrarState
import com.typewritermc.services.libs.registrar.ServiceId
import com.typewritermc.services.libs.registrar.ServiceIdentity
import com.typewritermc.services.libs.registrar.ServiceRole
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.flow.MutableStateFlow
import skirout.kernel.v1.record_id.RecordId
import skirout.kernel.v1.record_id.RecordIdKey
import skirout.service.v1.topology.ChildRuntimeState
import skirout.service.v1.topology.ChildRuntimeStatus
import skirout.service.v1.topology.EngineTarget
import skirout.service.v1.topology.OwnerHost
import skirout.service.v1.topology.RealmInstance
import skirout.service.v1.topology.RegisterServiceHostResponse
import skirout.service.v1.topology.ServiceHost
import skirout.service.v1.topology.WatchHostExecutionResponse
import java.time.Instant

/** The backend side of the host's messaging: it answers registration and the initial assignment of the watch. */
class Backend(
    private var failedRegistrations: Int = 0,
) : AutoCloseable {
    val events = mutableListOf<String>()
    private val transport = FakeMessageTransport()
    private val harness = TelemetryTestHarness.create()

    init {
        repeat(ANSWERED_REQUESTS) { transport.respondWith { request, _ -> TransportResult.Success(answer(request)) } }
    }

    private fun answer(request: OutboundMessage): InboundMessage =
        when (request.address) {
            HOST_SCOPE.serviceHostRegister.requestAddress.render(HOST_SCOPE) -> {
                events += "register"
                val response =
                    if (failedRegistrations-- > 0) {
                        RegisterServiceHostResponse.createInternalError()
                    } else {
                        RegisterServiceHostResponse.SuccessWrapper(ServiceHost.partial())
                    }
                InboundMessage(request.address, HOST_SCOPE.serviceHostRegister.responseCodec.encode(response))
            }

            HOST_SCOPE.hostExecutionWatch.requestAddress.render(HOST_SCOPE) -> {
                events += "watch"
                val initial = WatchHostExecutionResponse.createDesired(topologyRevision = 1, realm = realmInstance(), engine = null)
                InboundMessage(request.address, HOST_SCOPE.hostExecutionWatch.initialCodec.encode(initial))
            }

            else -> {
                error("Unexpected request to ${request.address}")
            }
        }

    fun source(ready: Boolean): BackendArtifactHostAssignmentSource {
        val communicator = Communicator(transport, harness.telemetry, ContextPropagators.noop())
        val state =
            if (ready) {
                RegistrarState.Ready(
                    ReadySession(
                        ServiceIdentity(ASSIGNMENT_HOST, "Host", "host-user", ServiceRole.Host("1.0.0")),
                        OrganizationBinding("organization", "Organization"),
                    ),
                    connectionGeneration = 1,
                )
            } else {
                RegistrarState.Idle
            }
        val connection =
            object : LoaderServiceConnection {
                override val states = MutableStateFlow(RegistrarSnapshot(1, 1, state))
                override val openTelemetry = harness.openTelemetry
                override val telemetry = harness.telemetry

                override suspend fun communicatorFor(connectionGeneration: Long) = RegistrarResult.Success(communicator)

                override suspend fun rotateAuthorization() = error("Not used by assignments.")

                override suspend fun releaseAuthorizationRotation(connectionGeneration: Long) = error("Not used by assignments.")

                override fun sharedArtifacts(realmId: String) = error("Not used by assignments.")
            }
        return BackendArtifactHostAssignmentSource(
            connection,
            ArtifactRequirement(ArtifactId("typewritermc:panel"), VersionConstraint("^1")),
            HostEntrypoint.STANDALONE,
        )
    }

    override fun close() {
        transport.close()
        harness.close()
    }

    private companion object {
        const val ANSWERED_REQUESTS = 8
    }
}

private fun realmInstance(): RealmInstance {
    val host = OwnerHost(id = record("service_host", "host"), name = "Host")
    return RealmInstance(
        realmId = record("realm_instance", "realm"),
        ownerHost = host,
        revision = 1,
        targetEngine = EngineTarget(engineId = "typewritermc:paper", versionConstraint = "^1"),
        state =
            ChildRuntimeState(
                status = ChildRuntimeStatus.ABSENT,
                activeArtifactVersion = null,
                message = null,
                updatedAt = Instant.EPOCH,
            ),
    )
}

private fun record(
    table: String,
    key: String,
) = RecordId(table = table, key = RecordIdKey.StringWrapper(key))

val ASSIGNMENT_HOST = ServiceId("host")

private val HOST_SCOPE = ServiceRouteScope(ASSIGNMENT_HOST.value)
