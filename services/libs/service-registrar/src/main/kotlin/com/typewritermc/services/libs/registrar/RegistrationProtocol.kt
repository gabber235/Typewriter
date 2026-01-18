package com.typewritermc.services.libs.registrar

import com.typewritermc.services.libs.communicator.ServiceStatusResult
import com.typewritermc.services.libs.communicator.interfaces.Reconnector
import com.typewritermc.services.libs.communicator.interfaces.RegistrationClient
import io.github.oshai.kotlinlogging.KLogger
import io.github.oshai.kotlinlogging.KotlinLogging.logger
import kotlinx.coroutines.Job
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlin.time.Duration.Companion.minutes

class RegistrationProtocol(
    private val registrationClient: RegistrationClient,
    private val credential: Credential,
    private val reconnector: Reconnector
) {
    private val logger: KLogger = logger {}

    private val boundChannel = Channel<Pair<String, String>>(1)
    private var requeryJob: Job? = null
    private var subscriptionJob: Job? = null

    suspend fun checkAndRegister(): RegistrationState {
        val serviceId = credential.id

        when (val status = registrationClient.queryServiceStatus(serviceId)) {
            is ServiceStatusResult.Bound -> {
                logger.info { "Service already bound to organization: ${status.organizationName}" }
                return RegistrationState.Bound(status.organizationId, status.organizationName)
            }

            is ServiceStatusResult.Unbound -> {
                return handleUnboundState(serviceId, status.token)
            }

            is ServiceStatusResult.Error -> {
                logger.error { "Failed to query status: ${status.message} (code: ${status.code})" }
                return RegistrationState.Failed(status.message)
            }
        }
    }

    private suspend fun handleUnboundState(serviceId: String, token: String): RegistrationState {
        displayToken(token)

        subscriptionJob = registrationClient.subscribeToBoundNotification(serviceId) { orgId, orgName ->
            boundChannel.send(orgId to orgName)
        }

        scheduleRequery(serviceId)

        val (orgId, orgName) = boundChannel.receive()

        cleanup()

        logger.info { "Service bound! Reconnecting to get full permissions..." }
        reconnector.reconnect()

        return RegistrationState.Bound(orgId, orgName)
    }

    private suspend fun scheduleRequery(serviceId: String) {
        requeryJob = kotlinx.coroutines.CoroutineScope(currentCoroutineContext()).launch {
            while (isActive) {
                delay(2.minutes)
                logger.debug { "Requerying status to refresh token..." }

                when (val status = registrationClient.queryServiceStatus(serviceId)) {
                    is ServiceStatusResult.Bound -> {
                        boundChannel.send(status.organizationId to status.organizationName)
                        return@launch
                    }

                    is ServiceStatusResult.Unbound -> {
                        displayToken(status.token)
                    }

                    is ServiceStatusResult.Error -> {
                        logger.warn { "Requery failed: ${status.message}" }
                    }
                }
            }
        }
    }

    private fun cleanup() {
        requeryJob?.cancel()
        subscriptionJob?.cancel()
        requeryJob = null
        subscriptionJob = null
    }

    private fun displayToken(token: String) {
        val boxWidth = 60
        val tokenLine = "    Registration Token:  $token"
        val paddedToken = tokenLine.padEnd(boxWidth - 1) + "║"

        val box = buildString {
            appendLine()
            appendLine("╔${"═".repeat(boxWidth)}╗")
            appendLine("║${" ".repeat((boxWidth - 20) / 2)}SERVICE REGISTRATION${" ".repeat((boxWidth - 20) / 2)}║")
            appendLine("╠${"═".repeat(boxWidth)}╣")
            appendLine("║${" ".repeat(boxWidth)}║")
            appendLine("║$paddedToken")
            appendLine("║${" ".repeat(boxWidth)}║")
            appendLine("║    Enter this token in the TypeWriter Panel to bind${" ".repeat(boxWidth - 53)}║")
            appendLine("║    this service to your organization.${" ".repeat(boxWidth - 40)}║")
            appendLine("║${" ".repeat(boxWidth)}║")
            appendLine("║    Token refreshes every 2 minutes.${" ".repeat(boxWidth - 38)}║")
            appendLine("║${" ".repeat(boxWidth)}║")
            appendLine("╚${"═".repeat(boxWidth)}╝")
            appendLine()
        }

        logger.info { box }
    }
}
