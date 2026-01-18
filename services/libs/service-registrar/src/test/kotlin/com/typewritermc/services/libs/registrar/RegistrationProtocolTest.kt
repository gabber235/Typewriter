package com.typewritermc.services.libs.registrar

import com.typewritermc.services.libs.communicator.ServiceStatusResult
import com.typewritermc.services.libs.communicator.interfaces.Reconnector
import com.typewritermc.services.libs.communicator.interfaces.RegistrationClient
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.just
import io.mockk.mockk
import io.mockk.runs
import kotlinx.coroutines.Job

class RegistrationProtocolTest : FunSpec({

    test("should return Bound state when service is already bound") {
        val registrationClient = mockk<RegistrationClient>()
        val reconnector = mockk<Reconnector>()
        val credential = Credential(id = "test-service-id", name = "test-service", token = "test-token")

        coEvery { registrationClient.queryServiceStatus("test-service-id") } returns
            ServiceStatusResult.Bound(organizationId = "org-123", organizationName = "Test Org")

        val protocol = RegistrationProtocol(registrationClient, credential, reconnector)
        val result = protocol.checkAndRegister()

        result.shouldBeInstanceOf<RegistrationState.Bound>()
        result.organizationId shouldBe "org-123"
        result.organizationName shouldBe "Test Org"

        coVerify(exactly = 1) { registrationClient.queryServiceStatus("test-service-id") }
        coVerify(exactly = 0) { reconnector.reconnect() }
    }

    test("should return Failed state when query returns error") {
        val registrationClient = mockk<RegistrationClient>()
        val reconnector = mockk<Reconnector>()
        val credential = Credential(id = "test-service-id", name = "test-service", token = "test-token")

        coEvery { registrationClient.queryServiceStatus("test-service-id") } returns
            ServiceStatusResult.Error(code = 404, message = "Service not found")

        val protocol = RegistrationProtocol(registrationClient, credential, reconnector)
        val result = protocol.checkAndRegister()

        result.shouldBeInstanceOf<RegistrationState.Failed>()
        result.message shouldBe "Service not found"

        coVerify(exactly = 1) { registrationClient.queryServiceStatus("test-service-id") }
    }

    test("should wait for bound notification when unbound and reconnect after binding") {
        val registrationClient = mockk<RegistrationClient>()
        val reconnector = mockk<Reconnector>()
        val credential = Credential(id = "test-service-id", name = "test-service", token = "test-token")

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

        val protocol = RegistrationProtocol(registrationClient, credential, reconnector)
        val result = protocol.checkAndRegister()

        result.shouldBeInstanceOf<RegistrationState.Bound>()
        result.organizationId shouldBe "org-456"
        result.organizationName shouldBe "Bound Organization"

        coVerify(exactly = 1) { reconnector.reconnect() }
    }
})
