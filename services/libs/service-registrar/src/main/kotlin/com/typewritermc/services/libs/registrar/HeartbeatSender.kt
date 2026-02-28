package com.typewritermc.services.libs.registrar

import com.typewritermc.services.libs.communicator.interfaces.RegistrationClient
import com.typewritermc.services.libs.telemetry.hideLog
import com.typewritermc.services.libs.telemetry.withSuspendSpan
import io.github.oshai.kotlinlogging.KLogger
import io.github.oshai.kotlinlogging.KotlinLogging.logger
import io.opentelemetry.api.trace.SpanKind
import io.opentelemetry.api.trace.Tracer
import kotlinx.coroutines.*
import kotlin.time.Duration.Companion.seconds

class HeartbeatSender(
    private val serviceId: String,
    private val registrationClient: RegistrationClient,
    private val scope: CoroutineScope,
    private val tracer: Tracer,
    private val intervalMs: Long = 30.seconds.inWholeMilliseconds,
) {
    private val logger: KLogger = logger {}
    private var job: Job? = null

    fun start() {
        if (job != null) {
            logger.warn { "HeartbeatSender already running" }
            return
        }

        job = scope.launch {
            while (isActive) {
                try {
                    tracer.withSuspendSpan("heartbeat.send", SpanKind.CLIENT) { span ->
                        span.setAttribute("service.id", serviceId).hideLog()
                        registrationClient.sendHeartbeat(serviceId)
                    }
                } catch (_: Exception) {
                    // It will already be logged by the span and captured.
                    // We want to prevent propagation so it doesn't break the loop even when temporarily it stops working.
                }
                delay(intervalMs)
            }
        }
    }

    fun stop() {
        job?.cancel()
        job = null
        logger.info { "HeartbeatSender stopped" }
    }
}
