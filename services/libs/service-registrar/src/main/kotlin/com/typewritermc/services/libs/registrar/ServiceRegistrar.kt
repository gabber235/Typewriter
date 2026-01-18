package com.typewritermc.services.libs.registrar

import com.typewritermc.services.libs.communicator.JwtProvider
import com.typewritermc.services.libs.communicator.NatsCommunicator
import com.typewritermc.services.libs.communicator.interfaces.MessageBus
import com.typewritermc.services.libs.communicator.interfaces.NatsMessageBus
import com.typewritermc.services.libs.communicator.interfaces.NatsRegistrationClient
import com.typewritermc.services.libs.communicator.interfaces.Reconnector
import com.typewritermc.services.libs.communicator.interfaces.RegistrationClient
import com.typewritermc.services.libs.utils.DeferredProvider
import com.typewritermc.services.libs.utils.StateProvider
import io.github.oshai.kotlinlogging.KLogger
import io.github.oshai.kotlinlogging.KotlinLogging.logger
import io.natskt.api.NatsClient

class ServiceRegistrar(
    private val credentialStorage: CredentialStorage,
    private val credentialIssuer: CredentialIssuer,
    private val jwtExchanger: JwtExchanger,
    private val communicator: NatsCommunicator,
    private val credentialProvider: DeferredProvider<Credential>,
    private val jwtProviderHolder: DeferredProvider<JwtProvider>,
    private val natsClientProvider: DeferredProvider<NatsClient>,
    private val messageBusProvider: DeferredProvider<MessageBus>,
    private val registrationClientProvider: DeferredProvider<RegistrationClient>,
    private val reconnectorProvider: DeferredProvider<Reconnector>,
    private val registrationStateProvider: StateProvider<RegistrationState>,
) {
    private val logger: KLogger = logger {}

    private var credential: Credential? = null

    suspend fun initialize() {
        logger.info { "Initializing service registrar" }

        var cred = credentialStorage.credential()
        if (cred == null) {
            logger.info { "No credentials found, generating new credentials" }
            cred = credentialIssuer.issueCredential()

            credentialStorage.storeCredential(cred)
            logger.info { "New credentials generated: $cred" }
        } else {
            logger.debug { "Found credentials: $cred" }
        }

        this.credential = cred
        credentialProvider.set(cred)

        registerJwtProvider()
        setupNatsConnection()
        registerInterfaceBindings()

        val registrationClient = registrationClientProvider.get()
        val reconnector = reconnectorProvider.get()
        val registrationProtocol = RegistrationProtocol(
            registrationClient, cred, reconnector, registrationStateProvider
        )
        val state = registrationProtocol.checkAndRegister()
        when (state) {
            is RegistrationState.Bound -> {
                logger.info { "Service bound to organization: ${state.organizationName}" }
            }
            is RegistrationState.Failed -> {
                logger.error { "Registration failed: ${state.message}" }
                throw IllegalStateException("Registration failed: ${state.message}")
            }
            else -> {
                throw IllegalStateException("Unexpected registration state: $state")
            }
        }

        logger.info { "Service registrar initialized" }
    }

    private fun registerJwtProvider() {
        logger.debug { "Registering JwtProvider implementation" }

        val jwtProvider = JwtProviderImpl(
            credentialProvider = { credential },
            jwtExchanger = jwtExchanger
        )

        jwtProviderHolder.set(jwtProvider)
        logger.debug { "JwtProvider registered" }
    }

    private suspend fun setupNatsConnection() {
        logger.info { "Setting up NATS connection" }
        communicator.connect()
        logger.info { "NATS connection established" }
    }

    private suspend fun registerInterfaceBindings() {
        logger.debug { "Registering interface bindings" }

        val natsClient = natsClientProvider.get()
        val messageBus = NatsMessageBus(natsClient)
        messageBusProvider.trySet(messageBus)

        val registrationClient = NatsRegistrationClient(messageBus)
        registrationClientProvider.trySet(registrationClient)

        reconnectorProvider.trySet(communicator)

        logger.debug { "Interface bindings registered" }
    }

    fun shutdown() {
        logger.info { "Shutting down service registrar" }
        logger.info { "Service registrar shut down" }
    }
}
