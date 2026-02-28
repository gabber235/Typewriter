package com.typewritermc.services.libs.communicator.interfaces

import com.typewritermc.services.libs.telemetry.withSuspendSpan
import io.opentelemetry.api.trace.SpanKind
import io.opentelemetry.api.trace.StatusCode
import io.opentelemetry.api.trace.Tracer
import kotlinx.coroutines.Job
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import protokt.v1.typewriter.api.v1.*
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import kotlin.time.Duration.Companion.seconds

sealed interface ServiceStatusResult {
    data class Bound(val organizationId: String, val organizationName: String) : ServiceStatusResult
    data class Unbound(val token: String) : ServiceStatusResult
    data class Error(val code: Int, val message: String) : ServiceStatusResult
}

class NatsRegistrationClient(
    private val messageBus: MessageBus,
    private val tracer: Tracer
) : RegistrationClient {

    override suspend fun queryServiceStatus(serviceId: String): ServiceStatusResult = tracer.withSuspendSpan(
        name = "registration.query_status",
        kind = SpanKind.CLIENT
    ) { span ->
        val subject = "cloud.out.service.$serviceId.status"
        val request = GetServiceStatusRequest {}

        val outputStream = ByteArrayOutputStream()
        request.serialize(outputStream)
        val requestBytes = outputStream.toByteArray()

        span.setAttribute("messaging.destination", subject)

        val response = try {
            messageBus.request(subject, requestBytes, timeout = 10.seconds)
        } catch (e: Exception) {
            span.recordException(e)
            span.setStatus(StatusCode.ERROR, "Failed to query service status")
            return@withSuspendSpan ServiceStatusResult.Error(-1, "NATS request failed: ${e.message}")
        }

        val responseData = response.data
        if (responseData == null || responseData.isEmpty()) {
            span.setStatus(StatusCode.ERROR, "No response from backend (empty data)")
            return@withSuspendSpan ServiceStatusResult.Error(-1, "No response from backend (empty data)")
        }

        val statusResponse = try {
            GetServiceStatusResponse.deserialize(ByteArrayInputStream(responseData))
        } catch (e: Exception) {
            span.recordException(e)
            span.setStatus(StatusCode.ERROR, "Failed to deserialize status response")
            return@withSuspendSpan ServiceStatusResult.Error(-1, "Failed to parse response: ${e.message}")
        }

        when (val result = statusResponse.result) {
            is GetServiceStatusResponse.Result.Status -> {
                val status = result.status
                when (val binding = status.binding) {
                    is ServiceStatus.Binding.Bound -> {
                        val orgId = binding.bound.organizationId
                        val orgName = binding.bound.organizationName ?: ""
                        span.addEvent("service_bound")
                        span.setAttribute("organization.id", orgId)
                        span.setAttribute("organization.name", orgName)
                        ServiceStatusResult.Bound(
                            organizationId = orgId,
                            organizationName = orgName
                        )
                    }

                    is ServiceStatus.Binding.Unbound -> {
                        span.addEvent("service_unbound")
                        binding.unbound.registrationToken?.let { span.setAttribute("registration_token", it) }
                        ServiceStatusResult.Unbound(
                            token = binding.unbound.registrationToken ?: ""
                        )
                    }

                    null -> {
                        span.setStatus(StatusCode.ERROR, "Status has no binding information")
                        ServiceStatusResult.Error(-1, "Status has no binding information")
                    }
                }
            }

            is GetServiceStatusResponse.Result.Error -> {
                val code = result.error.code ?: 0u
                val errorMsg = result.error.message ?: "unknown error"
                span.setAttribute("response.error.code", code.toLong())
                span.setAttribute("response.error.message", errorMsg)
                span.setStatus(StatusCode.ERROR, "Service status error: $errorMsg")
                ServiceStatusResult.Error(
                    code = (result.error.code ?: 0u).toInt(),
                    message = errorMsg
                )
            }

            null -> {
                span.setStatus(StatusCode.ERROR, "Empty response result")
                ServiceStatusResult.Error(-1, "Empty response result")
            }
        }
    }

    override suspend fun subscribeToBoundNotification(
        serviceId: String,
        onBound: suspend (organizationId: String, organizationName: String) -> Unit
    ): Job = tracer.withSuspendSpan(
        name = "registration.subscribe_bound",
        kind = SpanKind.CLIENT
    ) { span ->
        val subject = "cloud.in.service.$serviceId.registration.bound"
        span.setAttribute("messaging.subscription", subject)
        span.addEvent("subscribing")

        val subscription = messageBus.subscribe(subject)
        span.addEvent("subscribed")

        kotlinx.coroutines.CoroutineScope(currentCoroutineContext()).launch {
            try {
                val message = subscription.messages.first()
                val messageData = message.data ?: return@launch
                val notification = ServiceBoundNotification.deserialize(ByteArrayInputStream(messageData))
                val orgId = notification.organizationId
                val orgName = notification.organizationName ?: ""
                span.addEvent("bound_notification_received")
                span.setAttribute("organization.id", orgId)
                span.setAttribute("organization.name", orgName)
                onBound(orgId, orgName)
            } catch (e: Exception) {
                span.recordException(e)
                span.setStatus(StatusCode.ERROR, "Error processing bound notification")
            } finally {
                subscription.unsubscribe()
            }
        }
    }

    override suspend fun sendHeartbeat(serviceId: String) {
        val subject = "cloud.out.service.$serviceId.heartbeat"
        val request = ServiceHeartbeatRequest {}

        val outputStream = ByteArrayOutputStream()
        request.serialize(outputStream)
        val requestBytes = outputStream.toByteArray()

        try {
            messageBus.publish(subject, requestBytes)
        } catch (e: Exception) {
            // Parent span from HeartbeatSender handles error recording
            throw e
        }
    }

    override suspend fun sendShutdown(serviceId: String) {
        tracer.withSuspendSpan(
            name = "registration.shutdown",
            kind = SpanKind.CLIENT
        ) { span ->
            val subject = "cloud.out.service.$serviceId.shutdown"
            val request = ServiceShutdownRequest {}

            val outputStream = ByteArrayOutputStream()
            request.serialize(outputStream)
            val requestBytes = outputStream.toByteArray()

            span.setAttribute("messaging.destination", subject)
            span.addEvent("sending_shutdown")

            try {
                messageBus.publish(subject, requestBytes)
                span.addEvent("shutdown_sent")
            } catch (e: Exception) {
                span.recordException(e)
                span.setStatus(StatusCode.ERROR, "Failed to send shutdown notification")
                throw e
            }
        }
    }
}
