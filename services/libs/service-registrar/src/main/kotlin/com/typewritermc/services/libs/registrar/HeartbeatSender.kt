package com.typewritermc.services.libs.registrar

import com.typewritermc.services.libs.communicator.interfaces.RegistrationClient
import io.github.oshai.kotlinlogging.KLogger
import io.github.oshai.kotlinlogging.KotlinLogging.logger
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlin.time.Duration.Companion.seconds

class HeartbeatSender(
    private val serviceId: String,
    private val registrationClient: RegistrationClient,
    private val scope: CoroutineScope,
    private val intervalMs: Long = 30.seconds.inWholeMilliseconds,
) {
    private val logger: KLogger = logger {}
    private var job: Job? = null

    fun start() {
        if (job != null) {
            logger.warn { "HeartbeatSender already running" }
            return
        }

        logger.info { "Starting heartbeat sender (interval: ${intervalMs}ms)" }

        job = scope.launch {
            while (isActive) {
                try {
                    registrationClient.sendHeartbeat(serviceId)
                    logger.debug { "Heartbeat sent" }
                } catch (e: Exception) {
                    logger.warn(e) { "Failed to send heartbeat" }
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
