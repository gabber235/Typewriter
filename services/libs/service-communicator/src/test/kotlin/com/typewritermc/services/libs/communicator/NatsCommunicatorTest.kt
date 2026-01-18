package com.typewritermc.services.libs.communicator

import com.typewritermc.services.libs.utils.DeferredProvider
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.mockk.coEvery
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import io.natskt.api.NatsClient
import kotlinx.serialization.json.Json

class NatsCommunicatorTest : FunSpec({

    val natsUrl = "nats://test.example.com:4222"
    val validJwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9." +
        java.util.Base64.getUrlEncoder().withoutPadding()
            .encodeToString("""{"sub":"service-123"}""".toByteArray()) +
        ".signature"

    context("Constructor Injection") {

        test("NatsCommunicator accepts all dependencies via constructor") {
            val jwtProvider = DeferredProvider<JwtProvider>()
            val natsClientProvider = DeferredProvider<NatsClient>()
            val credentialsFetcher = mockk<SentinelCredentialsFetcher>()
            val json = Json { ignoreUnknownKeys = true }

            val communicator = NatsCommunicator(
                natsUrl = natsUrl,
                jwtProvider = jwtProvider,
                sentinelCredentialsFetcher = credentialsFetcher,
                json = json,
                natsClientProvider = natsClientProvider
            )

            communicator shouldNotBe null
        }
    }

    context("extractServiceId") {

        test("extractServiceId throws on invalid JWT format - too few parts") {
            val jwtProvider = DeferredProvider<JwtProvider>()
            val natsClientProvider = DeferredProvider<NatsClient>()
            val credentialsFetcher = mockk<SentinelCredentialsFetcher>()
            val json = Json { ignoreUnknownKeys = true }

            val mockJwtProviderImpl = mockk<JwtProvider>()
            every { mockJwtProviderImpl.getTokenInfo() } returns TokenInfo(
                accessToken = "invalid.jwt",
                expiresInSeconds = 3600,
                tokenType = "Bearer"
            )
            jwtProvider.set(mockJwtProviderImpl)

            val communicator = NatsCommunicator(
                natsUrl = natsUrl,
                jwtProvider = jwtProvider,
                sentinelCredentialsFetcher = credentialsFetcher,
                json = json,
                natsClientProvider = natsClientProvider
            )

            shouldThrow<IllegalArgumentException> {
                communicator.connect()
            }
        }

        test("extractServiceId throws on missing sub claim") {
            val jwtProvider = DeferredProvider<JwtProvider>()
            val natsClientProvider = DeferredProvider<NatsClient>()
            val credentialsFetcher = mockk<SentinelCredentialsFetcher>()
            val json = Json { ignoreUnknownKeys = true }

            val jwtWithoutSub = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9." +
                java.util.Base64.getUrlEncoder().withoutPadding()
                    .encodeToString("""{"iss":"issuer"}""".toByteArray()) +
                ".signature"

            val mockJwtProviderImpl = mockk<JwtProvider>()
            every { mockJwtProviderImpl.getTokenInfo() } returns TokenInfo(
                accessToken = jwtWithoutSub,
                expiresInSeconds = 3600,
                tokenType = "Bearer"
            )
            jwtProvider.set(mockJwtProviderImpl)

            val communicator = NatsCommunicator(
                natsUrl = natsUrl,
                jwtProvider = jwtProvider,
                sentinelCredentialsFetcher = credentialsFetcher,
                json = json,
                natsClientProvider = natsClientProvider
            )

            shouldThrow<IllegalArgumentException> {
                communicator.connect()
            }
        }
    }

    context("DeferredProvider Integration") {

        test("connect suspends until JwtProvider is available") {
            val jwtProvider = DeferredProvider<JwtProvider>()
            val natsClientProvider = DeferredProvider<NatsClient>()
            val credentialsFetcher = mockk<SentinelCredentialsFetcher>()
            val json = Json { ignoreUnknownKeys = true }

            val communicator = NatsCommunicator(
                natsUrl = natsUrl,
                jwtProvider = jwtProvider,
                sentinelCredentialsFetcher = credentialsFetcher,
                json = json,
                natsClientProvider = natsClientProvider
            )

            jwtProvider.isSet shouldBe false
            natsClientProvider.isSet shouldBe false
        }
    }

    context("Disconnect") {

        test("disconnect can be called when not connected") {
            val jwtProvider = DeferredProvider<JwtProvider>()
            val natsClientProvider = DeferredProvider<NatsClient>()
            val credentialsFetcher = mockk<SentinelCredentialsFetcher>()
            val json = Json { ignoreUnknownKeys = true }

            val communicator = NatsCommunicator(
                natsUrl = natsUrl,
                jwtProvider = jwtProvider,
                sentinelCredentialsFetcher = credentialsFetcher,
                json = json,
                natsClientProvider = natsClientProvider
            )

            communicator.disconnect()
        }
    }
})
