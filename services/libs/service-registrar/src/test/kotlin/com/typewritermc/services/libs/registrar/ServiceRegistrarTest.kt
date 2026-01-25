package com.typewritermc.services.libs.registrar

import com.typewritermc.services.libs.communicator.JwtProvider
import com.typewritermc.services.libs.communicator.NatsCommunicator
import com.typewritermc.services.libs.communicator.ServiceStatusResult
import com.typewritermc.services.libs.communicator.interfaces.MessageBus
import com.typewritermc.services.libs.communicator.interfaces.Reconnector
import com.typewritermc.services.libs.communicator.interfaces.RegistrationClient
import com.typewritermc.services.libs.utils.DeferredProvider
import com.typewritermc.services.libs.utils.StateProvider
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.mockk.Runs
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.just
import io.mockk.mockk
import io.natskt.api.NatsClient
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope

@OptIn(ExperimentalCoroutinesApi::class)
class ServiceRegistrarTest : FunSpec({

    context("Constructor Injection") {

        test("ServiceRegistrar accepts all dependencies via constructor") {
            val registrar = createServiceRegistrar()
            registrar shouldNotBe null
        }
    }

    context("Credential Initialization") {

        test("uses stored credential when available") {
            val storedCredential = Credential(id = "stored-id", name = "stored", token = "token")
            val credentialStorage = mockk<CredentialStorage>()
            coEvery { credentialStorage.credential() } returns storedCredential

            val credentialProvider = DeferredProvider<Credential>()
            val registrar = createServiceRegistrar(
                credentialStorage = credentialStorage,
                credentialProvider = credentialProvider
            )

            credentialProvider.isSet shouldBe false

            registrar.initialize()

            credentialProvider.isSet shouldBe true
            credentialProvider.getOrNull() shouldBe storedCredential
        }

        test("issues new credential when none stored") {
            val newCredential = Credential(id = "new-id", name = "new", token = "token")
            val credentialStorage = mockk<CredentialStorage>()
            val credentialIssuer = mockk<CredentialIssuer>()

            coEvery { credentialStorage.credential() } returns null
            coEvery { credentialIssuer.issueCredential() } returns newCredential
            coEvery { credentialStorage.storeCredential(newCredential) } just Runs

            val credentialProvider = DeferredProvider<Credential>()
            val registrar = createServiceRegistrar(
                credentialStorage = credentialStorage,
                credentialIssuer = credentialIssuer,
                credentialProvider = credentialProvider
            )

            registrar.initialize()

            coVerify { credentialIssuer.issueCredential() }
            coVerify { credentialStorage.storeCredential(newCredential) }
            credentialProvider.getOrNull() shouldBe newCredential
        }
    }

    context("JwtProvider Registration") {

        test("sets JwtProvider in deferred holder") {
            val storedCredential = Credential(id = "id", name = "n", token = "t")
            val credentialStorage = mockk<CredentialStorage>()
            coEvery { credentialStorage.credential() } returns storedCredential

            val jwtProviderHolder = DeferredProvider<JwtProvider>()
            val registrar = createServiceRegistrar(
                credentialStorage = credentialStorage,
                jwtProviderHolder = jwtProviderHolder
            )

            jwtProviderHolder.isSet shouldBe false

            registrar.initialize()

            jwtProviderHolder.isSet shouldBe true
        }
    }

    context("Interface Bindings") {

        test("sets MessageBus provider after NATS connection") {
            val messageBusProvider = DeferredProvider<MessageBus>()
            val registrar = createServiceRegistrar(messageBusProvider = messageBusProvider)

            messageBusProvider.isSet shouldBe false

            registrar.initialize()

            messageBusProvider.isSet shouldBe true
        }

        test("preserves pre-set RegistrationClient provider during initialization") {
            val mockRegistrationClient = mockk<RegistrationClient>()
            coEvery { mockRegistrationClient.queryServiceStatus(any()) } returns ServiceStatusResult.Bound(
                organizationId = "org-id",
                organizationName = "Test Org"
            )

            val registrationClientProvider = DeferredProvider<RegistrationClient>()
            registrationClientProvider.set(mockRegistrationClient)

            val registrar = createServiceRegistrar(
                registrationClientProvider = registrationClientProvider,
                preSetRegistrationClient = false
            )

            registrar.initialize()

            registrationClientProvider.isSet shouldBe true
            registrationClientProvider.getOrNull() shouldBe mockRegistrationClient
        }

        test("preserves pre-set Reconnector provider during initialization") {
            val mockReconnector = mockk<Reconnector>()
            val reconnectorProvider = DeferredProvider<Reconnector>()
            reconnectorProvider.set(mockReconnector)

            val mockRegistrationClient = mockk<RegistrationClient>()
            coEvery { mockRegistrationClient.queryServiceStatus(any()) } returns ServiceStatusResult.Bound(
                organizationId = "org-id",
                organizationName = "Test Org"
            )
            val registrationClientProvider = DeferredProvider<RegistrationClient>()
            registrationClientProvider.set(mockRegistrationClient)

            val registrar = createServiceRegistrar(
                reconnectorProvider = reconnectorProvider,
                registrationClientProvider = registrationClientProvider,
                preSetRegistrationClient = false
            )

            registrar.initialize()

            reconnectorProvider.isSet shouldBe true
            reconnectorProvider.getOrNull() shouldBe mockReconnector
        }
    }

    context("No KoinComponent") {

        test("ServiceRegistrar class does not implement KoinComponent") {
            val registrar = createServiceRegistrar()
            val interfaces = registrar::class.java.interfaces.map { it.simpleName }
            interfaces.contains("KoinComponent") shouldBe false
        }
    }

    context("Heartbeat Lifecycle") {

        test("heartbeat sender starts when service is bound") {
            val mockRegistrationClient = mockk<RegistrationClient>()
            coEvery { mockRegistrationClient.queryServiceStatus(any()) } returns ServiceStatusResult.Bound(
                organizationId = "org-id",
                organizationName = "Test Org"
            )
            coEvery { mockRegistrationClient.sendHeartbeat(any()) } just Runs

            val registrationClientProvider = DeferredProvider<RegistrationClient>()
            registrationClientProvider.set(mockRegistrationClient)

            val mockReconnector = mockk<Reconnector>()
            val reconnectorProvider = DeferredProvider<Reconnector>()
            reconnectorProvider.set(mockReconnector)

            val testScope = TestScope()

            val registrar = createServiceRegistrar(
                registrationClientProvider = registrationClientProvider,
                reconnectorProvider = reconnectorProvider,
                preSetRegistrationClient = false,
                coroutineScope = testScope
            )

            registrar.initialize()
            testScope.testScheduler.runCurrent()

            coVerify(atLeast = 1) { mockRegistrationClient.sendHeartbeat("default-id") }
        }

        test("heartbeat sender stops on shutdown") {
            val mockRegistrationClient = mockk<RegistrationClient>()
            coEvery { mockRegistrationClient.queryServiceStatus(any()) } returns ServiceStatusResult.Bound(
                organizationId = "org-id",
                organizationName = "Test Org"
            )
            coEvery { mockRegistrationClient.sendHeartbeat(any()) } just Runs
            coEvery { mockRegistrationClient.sendShutdown(any()) } just Runs

            val registrationClientProvider = DeferredProvider<RegistrationClient>()
            registrationClientProvider.set(mockRegistrationClient)

            val mockReconnector = mockk<Reconnector>()
            val reconnectorProvider = DeferredProvider<Reconnector>()
            reconnectorProvider.set(mockReconnector)

            val testScope = TestScope()

            val registrar = createServiceRegistrar(
                registrationClientProvider = registrationClientProvider,
                reconnectorProvider = reconnectorProvider,
                preSetRegistrationClient = false,
                coroutineScope = testScope
            )

            registrar.initialize()
            testScope.testScheduler.runCurrent()

            val callCountBeforeShutdown = 1
            coVerify(exactly = callCountBeforeShutdown) { mockRegistrationClient.sendHeartbeat("default-id") }

            testScope.launch { registrar.shutdown() }
            testScope.testScheduler.runCurrent()

            testScope.testScheduler.advanceTimeBy(60_000)
            testScope.testScheduler.runCurrent()

            coVerify(exactly = callCountBeforeShutdown) { mockRegistrationClient.sendHeartbeat("default-id") }
            coVerify(exactly = 1) { mockRegistrationClient.sendShutdown("default-id") }
        }

        test("shutdown sends notification before stopping heartbeat") {
            val mockRegistrationClient = mockk<RegistrationClient>()
            coEvery { mockRegistrationClient.queryServiceStatus(any()) } returns ServiceStatusResult.Bound(
                organizationId = "org-id",
                organizationName = "Test Org"
            )
            coEvery { mockRegistrationClient.sendHeartbeat(any()) } just Runs
            coEvery { mockRegistrationClient.sendShutdown(any()) } just Runs

            val registrationClientProvider = DeferredProvider<RegistrationClient>()
            registrationClientProvider.set(mockRegistrationClient)

            val mockReconnector = mockk<Reconnector>()
            val reconnectorProvider = DeferredProvider<Reconnector>()
            reconnectorProvider.set(mockReconnector)

            val testScope = TestScope()

            val registrar = createServiceRegistrar(
                registrationClientProvider = registrationClientProvider,
                reconnectorProvider = reconnectorProvider,
                preSetRegistrationClient = false,
                coroutineScope = testScope
            )

            registrar.initialize()
            testScope.testScheduler.runCurrent()

            testScope.launch { registrar.shutdown() }
            testScope.testScheduler.runCurrent()

            coVerify(exactly = 1) { mockRegistrationClient.sendShutdown("default-id") }
        }
    }
})

private fun createServiceRegistrar(
    credentialStorage: CredentialStorage? = null,
    credentialIssuer: CredentialIssuer? = null,
    jwtExchanger: JwtExchanger? = null,
    communicator: NatsCommunicator? = null,
    credentialProvider: DeferredProvider<Credential>? = null,
    jwtProviderHolder: DeferredProvider<JwtProvider>? = null,
    natsClientProvider: StateProvider<NatsClient?>? = null,
    messageBusProvider: DeferredProvider<MessageBus>? = null,
    registrationClientProvider: DeferredProvider<RegistrationClient>? = null,
    reconnectorProvider: DeferredProvider<Reconnector>? = null,
    registrationStateProvider: StateProvider<RegistrationState>? = null,
    coroutineScope: CoroutineScope? = null,
    preSetRegistrationClient: Boolean = true
): ServiceRegistrar {
    val storedCredential = Credential(id = "default-id", name = "default", token = "token")

    val storage = credentialStorage ?: mockk<CredentialStorage>().also {
        coEvery { it.credential() } returns storedCredential
    }

    val issuer = credentialIssuer ?: mockk<CredentialIssuer>()
    val exchanger = jwtExchanger ?: mockk<JwtExchanger>()

    val natsClient = mockk<NatsClient>()
    val natsProvider = natsClientProvider ?: StateProvider<NatsClient?>(natsClient)

    val comm = communicator ?: mockk<NatsCommunicator>().also {
        coEvery { it.connect() } just Runs
    }

    val credProvider = credentialProvider ?: DeferredProvider()
    val jwtHolder = jwtProviderHolder ?: DeferredProvider()
    val msgBusProvider = messageBusProvider ?: DeferredProvider()

    val regClientProvider = registrationClientProvider ?: DeferredProvider<RegistrationClient>()
    if (preSetRegistrationClient && !regClientProvider.isSet) {
        val mockRegClient = mockk<RegistrationClient>()
        coEvery { mockRegClient.queryServiceStatus(any()) } returns ServiceStatusResult.Bound(
            organizationId = "org-id",
            organizationName = "Test Organization"
        )
        coEvery { mockRegClient.sendHeartbeat(any()) } just Runs
        regClientProvider.set(mockRegClient)
    }

    val reconProvider = reconnectorProvider ?: DeferredProvider<Reconnector>()
    if (preSetRegistrationClient && !reconProvider.isSet) {
        reconProvider.set(mockk())
    }

    val stateProvider: StateProvider<RegistrationState> =
        registrationStateProvider ?: StateProvider(RegistrationState.Initializing)

    val scope = coroutineScope ?: TestScope()

    return ServiceRegistrar(
        credentialStorage = storage,
        credentialIssuer = issuer,
        jwtExchanger = exchanger,
        communicator = comm,
        credentialProvider = credProvider,
        jwtProviderHolder = jwtHolder,
        natsClientProvider = natsProvider,
        messageBusProvider = msgBusProvider,
        registrationClientProvider = regClientProvider,
        reconnectorProvider = reconProvider,
        registrationStateProvider = stateProvider,
        coroutineScope = scope
    )
}
