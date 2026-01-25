package com.typewritermc.services.libs.registrar

import com.github.ajalt.mordant.rendering.TextColors.blue
import com.github.ajalt.mordant.rendering.TextColors.gray
import com.github.ajalt.mordant.rendering.TextStyles.bold
import com.typewritermc.services.libs.communicator.ServiceStatusResult
import com.typewritermc.services.libs.communicator.interfaces.Reconnector
import com.typewritermc.services.libs.communicator.interfaces.RegistrationClient
import com.typewritermc.services.libs.utils.StateProvider
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
    private val reconnector: Reconnector,
    private val stateProvider: StateProvider<RegistrationState>,
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
                val state = RegistrationState.Bound(status.organizationId, status.organizationName)
                stateProvider.set(state)
                return state
            }

            is ServiceStatusResult.Unbound -> {
                val pendingState = RegistrationState.Pending(status.token)
                stateProvider.set(pendingState)
                return handleUnboundState(serviceId, status.token)
            }

            is ServiceStatusResult.Error -> {
                logger.error { "Failed to query status: ${status.message} (code: ${status.code})" }
                val state = RegistrationState.Failed(status.message)
                stateProvider.set(state)
                return state
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

        val boundState = RegistrationState.Bound(orgId, orgName)
        stateProvider.set(boundState)
        return boundState
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
                        stateProvider.set(RegistrationState.Pending(status.token))
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

        fun padLine(text: String, displayLength: Int = text.length): String {
            return "║$text${" ".repeat(boxWidth - displayLength)}║"
        }

        fun centerLine(text: String): String {
            val padding = (boxWidth - text.length) / 2
            val extra = if ((boxWidth - text.length) % 2 == 1) 1 else 0
            return "║${" ".repeat(padding)}$text${" ".repeat(padding + extra)}║"
        }

        val styledToken = (bold + blue)(token)
        val tokenText = "    Registration Token:  $styledToken"
        val tokenDisplayLength = "    Registration Token:  $token".length

        val styledRefresh = gray("    Token refreshes every 2 minutes.")
        val refreshDisplayLength = "    Token refreshes every 2 minutes.".length

        val box = buildString {
            appendLine()
            appendLine("╔${"═".repeat(boxWidth)}╗")
            appendLine(centerLine("SERVICE REGISTRATION"))
            appendLine("╠${"═".repeat(boxWidth)}╣")
            appendLine(padLine(""))
            appendLine(padLine(tokenText, tokenDisplayLength))
            appendLine(padLine(""))
            appendLine(padLine("    Enter this token in the Typewriter Panel to bind"))
            appendLine(padLine("    this service to your organization."))
            appendLine(padLine(""))
            appendLine(padLine(styledRefresh, refreshDisplayLength))
            appendLine(padLine(""))
            appendLine("╚${"═".repeat(boxWidth)}╝")
            appendLine()
        }

        logger.info { box }
    }
}
