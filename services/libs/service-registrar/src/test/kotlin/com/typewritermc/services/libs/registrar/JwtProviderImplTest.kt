package com.typewritermc.services.libs.registrar

import com.typewritermc.services.libs.communicator.JwtProvisionException
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify

class JwtProviderImplTest : FunSpec({

    context("Happy Path Scenarios") {

        test("getJwt returns access token from exchanger") {
            val credential = Credential(id = "svc-1", name = "service-user", token = "app-password")
            val credentialProvider = { credential }
            val jwtExchanger = mockk<JwtExchanger>()

            every { jwtExchanger.exchangeForJwt(credential) } returns TokenResponse(
                accessToken = "jwt-token-abc123",
                expiresIn = 3600,
                tokenType = "Bearer"
            )

            val provider = JwtProviderImpl(credentialProvider, jwtExchanger)
            val jwt = provider.getJwt()

            jwt shouldBe "jwt-token-abc123"
        }

        test("getTokenInfo returns complete token information") {
            val credential = Credential(id = "svc", name = "user", token = "pass")
            val credentialProvider = { credential }
            val jwtExchanger = mockk<JwtExchanger>()

            every { jwtExchanger.exchangeForJwt(credential) } returns TokenResponse(
                accessToken = "token-xyz",
                expiresIn = 7200,
                tokenType = "Bearer"
            )

            val provider = JwtProviderImpl(credentialProvider, jwtExchanger)
            val tokenInfo = provider.getTokenInfo()

            tokenInfo.accessToken shouldBe "token-xyz"
            tokenInfo.expiresInSeconds shouldBe 7200
            tokenInfo.tokenType shouldBe "Bearer"
        }

        test("getJwt fetches credential from provider each time") {
            var callCount = 0
            val credentialProvider = {
                callCount++
                Credential(id = "svc", name = "user-$callCount", token = "pass")
            }
            val jwtExchanger = mockk<JwtExchanger>()

            every { jwtExchanger.exchangeForJwt(any()) } returns TokenResponse(
                accessToken = "token",
                expiresIn = 3600,
                tokenType = "Bearer"
            )

            val provider = JwtProviderImpl(credentialProvider, jwtExchanger)
            provider.getJwt()
            provider.getJwt()

            callCount shouldBe 2
        }
    }

    context("Error and Failure Scenarios") {

        test("getJwt throws JwtProvisionException when credential provider returns null") {
            val credentialProvider: () -> Credential? = { null }
            val jwtExchanger = mockk<JwtExchanger>()

            val provider = JwtProviderImpl(credentialProvider, jwtExchanger)

            val exception = shouldThrow<JwtProvisionException> {
                provider.getJwt()
            }

            exception.message shouldContain "Credentials not initialized"
        }

        test("getTokenInfo throws JwtProvisionException when credential provider returns null") {
            val credentialProvider: () -> Credential? = { null }
            val jwtExchanger = mockk<JwtExchanger>()

            val provider = JwtProviderImpl(credentialProvider, jwtExchanger)

            val exception = shouldThrow<JwtProvisionException> {
                provider.getTokenInfo()
            }

            exception.message shouldContain "Credentials not initialized"
        }

        test("getJwt wraps JwtExchangeException in JwtProvisionException") {
            val credential = Credential(id = "svc", name = "user", token = "pass")
            val credentialProvider = { credential }
            val jwtExchanger = mockk<JwtExchanger>()

            every { jwtExchanger.exchangeForJwt(credential) } throws
                JwtExchangeException("HTTP 401 Unauthorized")

            val provider = JwtProviderImpl(credentialProvider, jwtExchanger)

            val exception = shouldThrow<JwtProvisionException> {
                provider.getJwt()
            }

            exception.message shouldContain "Failed to exchange credential"
            (exception.cause is JwtExchangeException) shouldBe true
        }

        test("getTokenInfo preserves original cause in exception") {
            val credential = Credential(id = "svc", name = "user", token = "pass")
            val credentialProvider = { credential }
            val jwtExchanger = mockk<JwtExchanger>()

            val originalException = JwtExchangeException("Connection refused")
            every { jwtExchanger.exchangeForJwt(credential) } throws originalException

            val provider = JwtProviderImpl(credentialProvider, jwtExchanger)

            val exception = shouldThrow<JwtProvisionException> {
                provider.getTokenInfo()
            }

            exception.cause shouldBe originalException
        }
    }

    context("Edge Cases") {

        test("getJwt works with credential containing special characters") {
            val credential = Credential(
                id = "svc-特殊",
                name = "user@domain.com",
                token = "p@ss=word&special"
            )
            val credentialProvider = { credential }
            val jwtExchanger = mockk<JwtExchanger>()

            every { jwtExchanger.exchangeForJwt(credential) } returns TokenResponse(
                accessToken = "token",
                expiresIn = 3600,
                tokenType = "Bearer"
            )

            val provider = JwtProviderImpl(credentialProvider, jwtExchanger)
            val jwt = provider.getJwt()

            jwt shouldBe "token"
            verify { jwtExchanger.exchangeForJwt(credential) }
        }
    }
})
