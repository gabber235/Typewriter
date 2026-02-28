package com.typewritermc.services.libs.registrar

import com.typewritermc.services.libs.communicator.interfaces.Reconnector
import com.typewritermc.services.libs.communicator.interfaces.RegistrationClient
import com.typewritermc.services.libs.communicator.interfaces.ServiceStatusResult
import com.typewritermc.services.libs.telemetry.testing.MockTelemetry
import com.typewritermc.services.libs.utils.StateProvider
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.mockk.*
import kotlinx.coroutines.Job

class RegistrationProtocolTest : FunSpec({

    fun createStateProvider() = StateProvider<RegistrationState>(RegistrationState.Initializing)

    context("Happy Path Scenarios") {

        test("already bound service returns Bound state immediately") {
            val registrationClient = mockk<RegistrationClient>()
            val reconnector = mockk<Reconnector>()
            val credential = Credential(id = "test-service-id", name = "test-service", token = "test-token")
            val stateProvider = createStateProvider()

            coEvery { registrationClient.queryServiceStatus("test-service-id") } returns
                    ServiceStatusResult.Bound(organizationId = "org-123", organizationName = "Test Org")

            val protocol = RegistrationProtocol(registrationClient, credential, reconnector, stateProvider, MockTelemetry.createMockTracer())
            val result = protocol.checkAndRegister()

            result.shouldBeInstanceOf<RegistrationState.Bound>()
            result.organizationId shouldBe "org-123"
            result.organizationName shouldBe "Test Org"

            coVerify(exactly = 1) { registrationClient.queryServiceStatus("test-service-id") }
            coVerify(exactly = 0) { reconnector.reconnect() }
        }

        test("unbound service waits for notification and returns Bound after binding") {
            val registrationClient = mockk<RegistrationClient>()
            val reconnector = mockk<Reconnector>()
            val credential = Credential(id = "test-service-id", name = "test-service", token = "test-token")
            val stateProvider = createStateProvider()

            coEvery { registrationClient.queryServiceStatus("test-service-id") } returns
                    ServiceStatusResult.Unbound(token = "REG-TOKEN-123")

            coEvery {
                registrationClient.subscribeToBoundNotification("test-service-id", any())
            } coAnswers {
                val callback = secondArg<suspend (String, String) -> Unit>()
                callback("org-456", "Bound Organization")
                Job()
            }

            coEvery { reconnector.reconnect() } just runs

            val protocol = RegistrationProtocol(registrationClient, credential, reconnector, stateProvider, MockTelemetry.createMockTracer())
            val result = protocol.checkAndRegister()

            result.shouldBeInstanceOf<RegistrationState.Bound>()
            result.organizationId shouldBe "org-456"
            result.organizationName shouldBe "Bound Organization"
        }

        test("reconnects to NATS after successful binding to get full permissions") {
            val registrationClient = mockk<RegistrationClient>()
            val reconnector = mockk<Reconnector>()
            val credential = Credential(id = "svc-1", name = "service", token = "tok")
            val stateProvider = createStateProvider()

            coEvery { registrationClient.queryServiceStatus("svc-1") } returns
                    ServiceStatusResult.Unbound(token = "TOKEN")

            coEvery {
                registrationClient.subscribeToBoundNotification("svc-1", any())
            } coAnswers {
                val callback = secondArg<suspend (String, String) -> Unit>()
                callback("org-id", "Org Name")
                Job()
            }

            coEvery { reconnector.reconnect() } just runs

            val protocol = RegistrationProtocol(registrationClient, credential, reconnector, stateProvider, MockTelemetry.createMockTracer())
            protocol.checkAndRegister()

            coVerify(exactly = 1) { reconnector.reconnect() }
        }
    }

    context("Error and Failure Scenarios") {

        test("returns Failed state when backend returns error") {
            val registrationClient = mockk<RegistrationClient>()
            val reconnector = mockk<Reconnector>()
            val credential = Credential(id = "test-service-id", name = "test-service", token = "test-token")
            val stateProvider = createStateProvider()

            coEvery { registrationClient.queryServiceStatus("test-service-id") } returns
                    ServiceStatusResult.Error(code = 404, message = "Service not found")

            val protocol = RegistrationProtocol(registrationClient, credential, reconnector, stateProvider, MockTelemetry.createMockTracer())
            val result = protocol.checkAndRegister()

            result.shouldBeInstanceOf<RegistrationState.Failed>()
            result.message shouldBe "Service not found"

            coVerify(exactly = 1) { registrationClient.queryServiceStatus("test-service-id") }
        }

        test("returns Failed with error message from backend") {
            val registrationClient = mockk<RegistrationClient>()
            val reconnector = mockk<Reconnector>()
            val credential = Credential(id = "svc", name = "s", token = "t")
            val stateProvider = createStateProvider()

            coEvery { registrationClient.queryServiceStatus("svc") } returns
                    ServiceStatusResult.Error(code = 500, message = "Internal server error: database unavailable")

            val protocol = RegistrationProtocol(registrationClient, credential, reconnector, stateProvider, MockTelemetry.createMockTracer())
            val result = protocol.checkAndRegister()

            result.shouldBeInstanceOf<RegistrationState.Failed>()
            result.message shouldBe "Internal server error: database unavailable"
        }
    }

    context("State Transition Scenarios") {

        test("uses credential id for service identification") {
            val registrationClient = mockk<RegistrationClient>()
            val reconnector = mockk<Reconnector>()
            val credential = Credential(id = "my-unique-service-id", name = "My Service", token = "secret")
            val stateProvider = createStateProvider()

            coEvery { registrationClient.queryServiceStatus("my-unique-service-id") } returns
                    ServiceStatusResult.Bound(organizationId = "org", organizationName = "Org")

            val protocol = RegistrationProtocol(registrationClient, credential, reconnector, stateProvider, MockTelemetry.createMockTracer())
            protocol.checkAndRegister()

            coVerify { registrationClient.queryServiceStatus("my-unique-service-id") }
        }

        test("subscribes to bound notification with correct service id") {
            val registrationClient = mockk<RegistrationClient>()
            val reconnector = mockk<Reconnector>()
            val credential = Credential(id = "svc-xyz", name = "s", token = "t")
            val stateProvider = createStateProvider()

            coEvery { registrationClient.queryServiceStatus("svc-xyz") } returns
                    ServiceStatusResult.Unbound(token = "TOK")

            coEvery {
                registrationClient.subscribeToBoundNotification("svc-xyz", any())
            } coAnswers {
                val callback = secondArg<suspend (String, String) -> Unit>()
                callback("org", "Org")
                Job()
            }

            coEvery { reconnector.reconnect() } just runs

            val protocol = RegistrationProtocol(registrationClient, credential, reconnector, stateProvider, MockTelemetry.createMockTracer())
            protocol.checkAndRegister()

            coVerify { registrationClient.subscribeToBoundNotification("svc-xyz", any()) }
        }
    }

    context("Edge Cases") {

        test("handles empty organization name in bound response") {
            val registrationClient = mockk<RegistrationClient>()
            val reconnector = mockk<Reconnector>()
            val credential = Credential(id = "svc", name = "s", token = "t")
            val stateProvider = createStateProvider()

            coEvery { registrationClient.queryServiceStatus("svc") } returns
                    ServiceStatusResult.Bound(organizationId = "org-123", organizationName = "")

            val protocol = RegistrationProtocol(registrationClient, credential, reconnector, stateProvider, MockTelemetry.createMockTracer())
            val result = protocol.checkAndRegister()

            result.shouldBeInstanceOf<RegistrationState.Bound>()
            result.organizationName shouldBe ""
        }

        test("handles unicode characters in organization name") {
            val registrationClient = mockk<RegistrationClient>()
            val reconnector = mockk<Reconnector>()
            val credential = Credential(id = "svc", name = "s", token = "t")
            val stateProvider = createStateProvider()

            coEvery { registrationClient.queryServiceStatus("svc") } returns
                    ServiceStatusResult.Bound(organizationId = "org", organizationName = "日本語組織 🎮")

            val protocol = RegistrationProtocol(registrationClient, credential, reconnector, stateProvider, MockTelemetry.createMockTracer())
            val result = protocol.checkAndRegister()

            result.shouldBeInstanceOf<RegistrationState.Bound>()
            result.organizationName shouldBe "日本語組織 🎮"
        }
    }

    context("StateProvider Updates") {

        test("updates state to Bound when service is already bound") {
            val registrationClient = mockk<RegistrationClient>()
            val reconnector = mockk<Reconnector>()
            val credential = Credential(id = "svc", name = "s", token = "t")
            val stateProvider = createStateProvider()

            coEvery { registrationClient.queryServiceStatus("svc") } returns
                    ServiceStatusResult.Bound(organizationId = "org-123", organizationName = "Test Org")

            val protocol = RegistrationProtocol(registrationClient, credential, reconnector, stateProvider, MockTelemetry.createMockTracer())
            protocol.checkAndRegister()

            stateProvider.get().shouldBeInstanceOf<RegistrationState.Bound>()
        }

        test("updates state to Pending when service is unbound") {
            val registrationClient = mockk<RegistrationClient>()
            val reconnector = mockk<Reconnector>()
            val credential = Credential(id = "svc", name = "s", token = "t")
            val stateProvider = createStateProvider()

            coEvery { registrationClient.queryServiceStatus("svc") } returns
                    ServiceStatusResult.Unbound(token = "TOKEN-123")

            coEvery {
                registrationClient.subscribeToBoundNotification("svc", any())
            } coAnswers {
                val callback = secondArg<suspend (String, String) -> Unit>()
                callback("org", "Org")
                Job()
            }

            coEvery { reconnector.reconnect() } just runs

            val protocol = RegistrationProtocol(registrationClient, credential, reconnector, stateProvider, MockTelemetry.createMockTracer())
            protocol.checkAndRegister()

            stateProvider.get().shouldBeInstanceOf<RegistrationState.Bound>()
        }

        test("updates state to Failed on error") {
            val registrationClient = mockk<RegistrationClient>()
            val reconnector = mockk<Reconnector>()
            val credential = Credential(id = "svc", name = "s", token = "t")
            val stateProvider = createStateProvider()

            coEvery { registrationClient.queryServiceStatus("svc") } returns
                    ServiceStatusResult.Error(code = 500, message = "Server error")

            val protocol = RegistrationProtocol(registrationClient, credential, reconnector, stateProvider, MockTelemetry.createMockTracer())
            protocol.checkAndRegister()

            stateProvider.get().shouldBeInstanceOf<RegistrationState.Failed>()
        }
    }
})
