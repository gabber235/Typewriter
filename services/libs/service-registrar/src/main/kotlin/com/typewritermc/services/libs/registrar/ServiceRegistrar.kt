package com.typewritermc.services.libs.registrar

import com.typewritermc.services.libs.communicator.JwtProvider
import com.typewritermc.services.libs.communicator.NatsCommunicator
import com.typewritermc.services.libs.communicator.interfaces.*
import com.typewritermc.services.libs.telemetry.withSuspendSpan
import com.typewritermc.services.libs.utils.DeferredProvider
import com.typewritermc.services.libs.utils.StateProvider
import com.typewritermc.services.libs.utils.awaitNonNull
import io.github.oshai.kotlinlogging.KLogger
import io.github.oshai.kotlinlogging.KotlinLogging.logger
import io.natskt.api.NatsClient
import io.opentelemetry.api.trace.StatusCode
import io.opentelemetry.api.trace.Tracer
import kotlinx.coroutines.CoroutineScope

class ServiceRegistrar(
    private val credentialStorage: CredentialStorage,
    private val credentialIssuer: CredentialIssuer,
    private val jwtExchanger: JwtExchanger,
    private val communicator: NatsCommunicator,
    private val credentialProvider: DeferredProvider<Credential>,
    private val jwtProviderHolder: DeferredProvider<JwtProvider>,
    private val natsClientProvider: StateProvider<NatsClient?>,
    private val messageBusProvider: DeferredProvider<MessageBus>,
    private val registrationClientProvider: DeferredProvider<RegistrationClient>,
    private val reconnectorProvider: DeferredProvider<Reconnector>,
    private val registrationStateProvider: StateProvider<RegistrationState>,
    private val coroutineScope: CoroutineScope,
    private val tracer: Tracer,
) {
    private val logger: KLogger = logger {}

    private var credential: Credential? = null
    private var heartbeatSender: HeartbeatSender? = null

    suspend fun initialize() = tracer.withSuspendSpan("registrar.initialize") { s ->
        s.addEvent("loading_credentials")

        var cred = credentialStorage.credential()
        if (cred == null) {
            s.addEvent("credentials_missing")
            s.addEvent("issuing_credential")
            cred = credentialIssuer.issueCredential()

            credentialStorage.storeCredential(cred)
            s.setAttribute("credentials.generated", true)
        }

        this.credential = cred
        credentialProvider.set(cred)

        s.addEvent("registering_jwt_provider")
        registerJwtProvider()
        s.addEvent("connecting_nats")
        setupNatsConnection(s)
        s.addEvent("registering_interface_bindings")
        registerInterfaceBindings()

        val registrationClient = registrationClientProvider.get()
        val reconnector = reconnectorProvider.get()
        s.addEvent("checking_registration")
        val registrationProtocol = RegistrationProtocol(
            registrationClient, cred, reconnector, registrationStateProvider, tracer
        )
        val state = registrationProtocol.checkAndRegister()
        when (state) {
            is RegistrationState.Bound -> {
                s.addEvent("registration_bound")
                s.setAttribute("organization.id", state.organizationId)
                s.setAttribute("organization.name", state.organizationName)
                s.addEvent("starting_heartbeat")
                startHeartbeat(cred.id, registrationClient)
            }

            is RegistrationState.Failed -> {
                logger.error { "Registration failed: ${state.message}" }
                s.setStatus(StatusCode.ERROR, "Registration failed: ${state.message}")
                throw IllegalStateException("Registration failed: ${state.message}")
            }

            else -> {
                s.setStatus(StatusCode.ERROR, "Unexpected registration state: $state")
                throw IllegalStateException("Unexpected registration state: $state")
            }
        }

        s.setStatus(StatusCode.OK)
    }

    private fun registerJwtProvider() {
        val jwtProvider = JwtProviderImpl(
            credentialProvider = { credential },
            jwtExchanger = jwtExchanger
        )

        jwtProviderHolder.set(jwtProvider)
    }

    private suspend fun setupNatsConnection(s: io.opentelemetry.api.trace.Span) {
        s.addEvent("nats_connecting")
        communicator.connect()
        s.addEvent("nats_connected")
    }

    private suspend fun registerInterfaceBindings() {
        natsClientProvider.awaitNonNull()
        val messageBus = NatsMessageBus(natsClientProvider)
        messageBusProvider.trySet(messageBus)

        val registrationClient = NatsRegistrationClient(messageBus, tracer)
        registrationClientProvider.trySet(registrationClient)

        reconnectorProvider.trySet(communicator)
    }

    suspend fun shutdown() = tracer.withSuspendSpan("registrar.shutdown") { s ->
        val cred = credential
        if (cred != null) {
            try {
                val registrationClient = registrationClientProvider.get()
                s.addEvent("sending_shutdown_notification")
                registrationClient.sendShutdown(cred.id)
                s.addEvent("shutdown_notification_sent")
            } catch (e: Exception) {
                s.recordException(e)
                logger.warn(e) { "Failed to send shutdown notification" }
            }
        }

        s.addEvent("stopping_heartbeat")
        heartbeatSender?.stop()
        s.setStatus(StatusCode.OK)
    }

    private fun startHeartbeat(serviceId: String, registrationClient: RegistrationClient) {
        heartbeatSender = HeartbeatSender(
            serviceId = serviceId,
            registrationClient = registrationClient,
            scope = coroutineScope,
            tracer = tracer
        )
        heartbeatSender?.start()
    }
}
