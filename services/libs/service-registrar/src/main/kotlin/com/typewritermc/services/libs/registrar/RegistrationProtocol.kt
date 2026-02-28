package com.typewritermc.services.libs.registrar

import com.github.ajalt.mordant.rendering.TextColors.blue
import com.github.ajalt.mordant.rendering.TextColors.gray
import com.github.ajalt.mordant.rendering.TextStyles.bold
import com.typewritermc.services.libs.communicator.interfaces.Reconnector
import com.typewritermc.services.libs.communicator.interfaces.RegistrationClient
import com.typewritermc.services.libs.communicator.interfaces.ServiceStatusResult
import com.typewritermc.services.libs.telemetry.withSuspendSpan
import com.typewritermc.services.libs.utils.StateProvider
import io.github.oshai.kotlinlogging.KLogger
import io.github.oshai.kotlinlogging.KotlinLogging.logger
import io.opentelemetry.api.trace.SpanKind
import io.opentelemetry.api.trace.StatusCode
import io.opentelemetry.api.trace.Tracer
import kotlinx.coroutines.*
import kotlinx.coroutines.channels.Channel
import kotlin.time.Duration.Companion.minutes

class RegistrationProtocol(
    private val registrationClient: RegistrationClient,
    private val credential: Credential,
    private val reconnector: Reconnector,
    private val stateProvider: StateProvider<RegistrationState>,
    private val tracer: Tracer,
) {
    private val logger: KLogger = logger {}

    private val boundChannel = Channel<Pair<String, String>>(1)
    private var requeryJob: Job? = null
    private var subscriptionJob: Job? = null

    suspend fun checkAndRegister(): RegistrationState =
        tracer.withSuspendSpan("registration.check_and_register", SpanKind.CLIENT) { s ->
            val serviceId = credential.id
            s.setAttribute("service.id", serviceId)

            when (val status = registrationClient.queryServiceStatus(serviceId)) {
                is ServiceStatusResult.Bound -> {
                    s.addEvent("already_bound")
                    val state = RegistrationState.Bound(status.organizationId, status.organizationName)
                    stateProvider.set(state)
                    s.setAttribute("organization.id", status.organizationId)
                    s.setAttribute("organization.name", status.organizationName)
                    s.setStatus(StatusCode.OK)
                    state
                }

                is ServiceStatusResult.Unbound -> {
                    val pendingState = RegistrationState.Pending(status.token)
                    stateProvider.set(pendingState)
                    s.addEvent("service_unbound")
                    handleUnboundState(serviceId, status.token)
                }

                is ServiceStatusResult.Error -> {
                    logger.error { "Failed to query status: ${status.message} (code: ${status.code})" }
                    s.setAttribute("error.code", status.code.toLong())
                    s.setStatus(StatusCode.ERROR, status.message)
                    val state = RegistrationState.Failed(status.message)
                    stateProvider.set(state)
                    state
                }
            }
        }

    private suspend fun handleUnboundState(serviceId: String, token: String): RegistrationState =
        tracer.withSuspendSpan("registration.handle_unbound") { s ->
            s.setAttribute("service.id", serviceId)

            s.addEvent("displaying_registration_token")
            displayToken(token)

            s.addEvent("subscribing_to_bound_notification")
            subscriptionJob = registrationClient.subscribeToBoundNotification(serviceId) { orgId, orgName ->
                boundChannel.send(orgId to orgName)
            }

            scheduleRequery(serviceId)

            s.addEvent("waiting_for_binding")
            val (orgId, orgName) = boundChannel.receive()

            cleanup()

            s.addEvent("service_bound_reconnecting")
            s.addEvent("reconnecting")
            reconnector.reconnect()

            val boundState = RegistrationState.Bound(orgId, orgName)
            stateProvider.set(boundState)
            s.setAttribute("organization.id", orgId)
            s.setAttribute("organization.name", orgName)
            s.setStatus(StatusCode.OK)
            boundState
        }

    private suspend fun scheduleRequery(serviceId: String) {
        requeryJob = CoroutineScope(currentCoroutineContext()).launch {
            while (isActive) {
                delay(2.minutes)

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
