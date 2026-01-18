package com.typewritermc.services.libs.registrar

import com.typewritermc.services.libs.communicator.JwtProvider
import com.typewritermc.services.libs.communicator.NatsCommunicator
import com.typewritermc.services.libs.communicator.interfaces.MessageBus
import com.typewritermc.services.libs.communicator.interfaces.NatsMessageBus
import com.typewritermc.services.libs.communicator.interfaces.NatsRegistrationClient
import com.typewritermc.services.libs.communicator.interfaces.Reconnector
import com.typewritermc.services.libs.communicator.interfaces.RegistrationClient
import io.github.oshai.kotlinlogging.KLogger
import io.github.oshai.kotlinlogging.KotlinLogging.logger
import io.natskt.api.NatsClient
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import org.koin.core.context.loadKoinModules
import org.koin.core.module.dsl.singleOf
import org.koin.core.qualifier.named
import org.koin.dsl.bind
import org.koin.dsl.module
import org.koin.dsl.onClose

val SERVICE_REGISTRAR_MODULE = module {
    singleOf(::ServiceRegistrar) onClose { it?.shutdown() }
    singleOf<CredentialIssuer>(::BackendCredentialIssuer)
    singleOf<JwtExchanger>(::AuthentikJwtExchanger)

    single(named("service-issue-url")) {
        val apiBase: String = get(named("api-base-url"))
        "$apiBase/service/identity/issue"
    }

    single(named("jwt-token-endpoint")) {
        val authBase: String = get(named("auth-base-url"))
        "$authBase/application/o/token/"
    }
    single(named("jwt-client-id")) {
        getProperty("JWT_CLIENT_ID", "typewriter-services")
    }
    single(named("jwt-scopes")) {
        getProperty("JWT_SCOPES", "openid profile entitlements")
    }
}

class ServiceRegistrar(
    private val credentialStorage: CredentialStorage,
    private val credentialIssuer: CredentialIssuer,
    private val jwtExchanger: JwtExchanger,
) : KoinComponent {
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

        loadKoinModules(module { single { cred } })

        registerJwtProvider()
        setupNatsConnection()
        registerInterfaceBindings()

        val registrationClient: RegistrationClient by inject()
        val reconnector: Reconnector by inject()
        val registrationProtocol = RegistrationProtocol(registrationClient, cred, reconnector)
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

    /**
     * Late register the JwtProvider implementation.
     * This allows service-communicator to use JWT without circular dependencies.
     */
    private fun registerJwtProvider() {
        logger.debug { "Registering JwtProvider implementation" }

        val jwtProviderModule = module {
            single<JwtProvider> {
                JwtProviderImpl(
                    credentialProvider = { credential },
                    jwtExchanger = jwtExchanger
                )
            }
        }

        loadKoinModules(jwtProviderModule)
        logger.debug { "JwtProvider registered" }
    }

    /**
     * Setup NATS connection using the communicator.
     */
    private suspend fun setupNatsConnection() {
        logger.info { "Setting up NATS connection" }

        val communicator: NatsCommunicator by inject()
        communicator.connect()

        logger.info { "NATS connection established" }
    }

    /**
     * Register interface bindings for dependency injection.
     * These bindings wrap the concrete implementations with testable interfaces.
     */
    private fun registerInterfaceBindings() {
        logger.debug { "Registering interface bindings" }

        val interfaceModule = module {
            single<MessageBus> {
                val natsClient: NatsClient = get()
                NatsMessageBus(natsClient)
            }
            single<RegistrationClient> {
                val messageBus: MessageBus = get()
                NatsRegistrationClient(messageBus)
            }
            single<Reconnector> {
                get<NatsCommunicator>()
            }
        }

        loadKoinModules(interfaceModule)
        logger.debug { "Interface bindings registered" }
    }

    fun shutdown() {
        logger.info { "Shutting down service registrar" }
        logger.info { "Service registrar shut down" }
    }
}
