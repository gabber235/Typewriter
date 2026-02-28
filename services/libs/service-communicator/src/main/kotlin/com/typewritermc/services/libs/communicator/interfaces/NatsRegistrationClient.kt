package com.typewritermc.services.libs.communicator.interfaces

import io.github.oshai.kotlinlogging.KotlinLogging
import kotlinx.coroutines.Job
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import protokt.v1.typewriter.api.v1.*
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import kotlin.time.Duration.Companion.seconds

private val logger = KotlinLogging.logger {}

sealed interface ServiceStatusResult {
    data class Bound(val organizationId: String, val organizationName: String) : ServiceStatusResult
    data class Unbound(val token: String) : ServiceStatusResult
    data class Error(val code: Int, val message: String) : ServiceStatusResult
}

class NatsRegistrationClient(private val messageBus: MessageBus) : RegistrationClient {

    override suspend fun queryServiceStatus(serviceId: String): ServiceStatusResult {
        val subject = "cloud.out.service.$serviceId.status"
        val request = GetServiceStatusRequest {}

        val outputStream = ByteArrayOutputStream()
        request.serialize(outputStream)
        val requestBytes = outputStream.toByteArray()

        logger.debug { "Querying service status on subject: $subject" }

        val response = try {
            messageBus.request(subject, requestBytes, timeout = 10.seconds)
        } catch (e: Exception) {
            logger.error(e) { "Failed to query service status" }
            return ServiceStatusResult.Error(-1, "NATS request failed: ${e.message}")
        }

        val responseData = response.data
        if (responseData == null || responseData.isEmpty()) {
            return ServiceStatusResult.Error(-1, "No response from backend (empty data)")
        }

        val statusResponse = try {
            GetServiceStatusResponse.deserialize(ByteArrayInputStream(responseData))
        } catch (e: Exception) {
            logger.error(e) { "Failed to deserialize status response" }
            return ServiceStatusResult.Error(-1, "Failed to parse response: ${e.message}")
        }

        return when (val result = statusResponse.result) {
            is GetServiceStatusResponse.Result.Status -> {
                val status = result.status
                when (val binding = status.binding) {
                    is ServiceStatus.Binding.Bound -> ServiceStatusResult.Bound(
                        organizationId = binding.bound.organizationId,
                        organizationName = binding.bound.organizationName
                    )

                    is ServiceStatus.Binding.Unbound -> ServiceStatusResult.Unbound(
                        token = binding.unbound.registrationToken
                    )

                    null -> ServiceStatusResult.Error(-1, "Status has no binding information")
                }
            }

            is GetServiceStatusResponse.Result.Error -> ServiceStatusResult.Error(
                code = result.error.code.toInt(),
                message = result.error.message
            )

            null -> ServiceStatusResult.Error(-1, "Empty response result")
        }
    }

    override suspend fun subscribeToBoundNotification(
        serviceId: String,
        onBound: suspend (organizationId: String, organizationName: String) -> Unit
    ): Job {
        val subject = "cloud.in.service.$serviceId.registration.bound"
        logger.info { "Subscribing to bound notification on: $subject" }

        val subscription = messageBus.subscribe(subject)

        return kotlinx.coroutines.CoroutineScope(currentCoroutineContext()).launch {
            try {
                val message = subscription.messages.first()
                val messageData = message.data ?: return@launch
                val notification = ServiceBoundNotification.deserialize(ByteArrayInputStream(messageData))
                logger.info { "Received bound notification for org: ${notification.organizationName}" }
                onBound(notification.organizationId, notification.organizationName)
            } catch (e: Exception) {
                logger.error(e) { "Error processing bound notification" }
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

        logger.trace { "Sending heartbeat on subject: $subject" }

        try {
            messageBus.publish(subject, requestBytes)
        } catch (e: Exception) {
            logger.warn(e) { "Failed to send heartbeat" }
        }
    }

    override suspend fun sendShutdown(serviceId: String) {
        val subject = "cloud.out.service.$serviceId.shutdown"
        val request = ServiceShutdownRequest {}

        val outputStream = ByteArrayOutputStream()
        request.serialize(outputStream)
        val requestBytes = outputStream.toByteArray()

        logger.info { "Sending shutdown notification on subject: $subject" }

        try {
            messageBus.publish(subject, requestBytes)
        } catch (e: Exception) {
            logger.warn(e) { "Failed to send shutdown notification" }
        }
    }
}
