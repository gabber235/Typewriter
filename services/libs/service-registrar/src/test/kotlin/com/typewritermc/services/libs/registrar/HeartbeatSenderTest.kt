package com.typewritermc.services.libs.registrar

import com.typewritermc.services.libs.communicator.interfaces.RegistrationClient
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.mockk.Runs
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.just
import io.mockk.mockk
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest

@OptIn(ExperimentalCoroutinesApi::class)
class HeartbeatSenderTest : FunSpec({

    val serviceId = "test-service-id"
    val intervalMs = 1000L

    context("Happy Path") {

        test("heartbeat is sent when started") {
            runTest {
                val registrationClient = mockk<RegistrationClient>()
                coEvery { registrationClient.sendHeartbeat(any()) } just Runs

                val sender = HeartbeatSender(
                    serviceId = serviceId,
                    registrationClient = registrationClient,
                    scope = this,
                    intervalMs = intervalMs
                )

                sender.start()
                runCurrent()

                coVerify(exactly = 1) { registrationClient.sendHeartbeat(serviceId) }

                sender.stop()
            }
        }

        test("heartbeats are sent periodically") {
            runTest {
                val registrationClient = mockk<RegistrationClient>()
                coEvery { registrationClient.sendHeartbeat(any()) } just Runs

                val sender = HeartbeatSender(
                    serviceId = serviceId,
                    registrationClient = registrationClient,
                    scope = this,
                    intervalMs = intervalMs
                )

                sender.start()
                runCurrent()

                advanceTimeBy(intervalMs)
                runCurrent()

                advanceTimeBy(intervalMs)
                runCurrent()

                coVerify(atLeast = 3) { registrationClient.sendHeartbeat(serviceId) }

                sender.stop()
            }
        }
    }

    context("Error & Failure Scenarios") {

        test("continues sending heartbeats after client exception") {
            runTest {
                var callCount = 0
                val registrationClient = mockk<RegistrationClient>()
                coEvery { registrationClient.sendHeartbeat(any()) } answers {
                    callCount++
                    if (callCount == 1) {
                        throw RuntimeException("Network error")
                    }
                }

                val sender = HeartbeatSender(
                    serviceId = serviceId,
                    registrationClient = registrationClient,
                    scope = this,
                    intervalMs = intervalMs
                )

                sender.start()
                runCurrent()

                advanceTimeBy(intervalMs)
                runCurrent()

                advanceTimeBy(intervalMs)
                runCurrent()

                coVerify(atLeast = 3) { registrationClient.sendHeartbeat(serviceId) }

                sender.stop()
            }
        }

        test("stop cancels the heartbeat loop") {
            runTest {
                val registrationClient = mockk<RegistrationClient>()
                coEvery { registrationClient.sendHeartbeat(any()) } just Runs

                val sender = HeartbeatSender(
                    serviceId = serviceId,
                    registrationClient = registrationClient,
                    scope = this,
                    intervalMs = intervalMs
                )

                sender.start()
                runCurrent()

                val callsBeforeStop = 1
                coVerify(exactly = callsBeforeStop) { registrationClient.sendHeartbeat(serviceId) }

                sender.stop()

                advanceTimeBy(intervalMs * 5)
                runCurrent()

                coVerify(exactly = callsBeforeStop) { registrationClient.sendHeartbeat(serviceId) }
            }
        }
    }

    context("Edge Cases") {

        test("start is idempotent when already running") {
            runTest {
                val registrationClient = mockk<RegistrationClient>()
                coEvery { registrationClient.sendHeartbeat(any()) } just Runs

                val sender = HeartbeatSender(
                    serviceId = serviceId,
                    registrationClient = registrationClient,
                    scope = this,
                    intervalMs = intervalMs
                )

                sender.start()
                runCurrent()

                sender.start()
                runCurrent()

                advanceTimeBy(intervalMs)
                runCurrent()

                coVerify(exactly = 2) { registrationClient.sendHeartbeat(serviceId) }

                sender.stop()
            }
        }

        test("stop is safe to call when not running") {
            runTest {
                val registrationClient = mockk<RegistrationClient>()

                val sender = HeartbeatSender(
                    serviceId = serviceId,
                    registrationClient = registrationClient,
                    scope = this,
                    intervalMs = intervalMs
                )

                sender.stop()

                val noExceptionThrown = true
                noExceptionThrown shouldBe true
            }
        }

        test("stop can be called multiple times safely") {
            runTest {
                val registrationClient = mockk<RegistrationClient>()
                coEvery { registrationClient.sendHeartbeat(any()) } just Runs

                val sender = HeartbeatSender(
                    serviceId = serviceId,
                    registrationClient = registrationClient,
                    scope = this,
                    intervalMs = intervalMs
                )

                sender.start()
                runCurrent()

                sender.stop()
                sender.stop()

                val noExceptionThrown = true
                noExceptionThrown shouldBe true
            }
        }
    }
})
