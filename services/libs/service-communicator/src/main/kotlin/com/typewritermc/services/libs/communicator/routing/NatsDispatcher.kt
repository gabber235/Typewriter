package com.typewritermc.services.libs.communicator.routing

import io.github.oshai.kotlinlogging.KotlinLogging
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch

private val logger = KotlinLogging.logger {}

class NatsDispatcher(
    private val routing: NatsRouting,
    private val scope: CoroutineScope
) {
    private val jobs = mutableListOf<Job>()

    fun start() {
        routing.routes.forEach { route ->
            val job = scope.launch {
                subscribeToRoute(route)
            }
            jobs.add(job)
        }
        logger.info { "Started ${jobs.size} NATS route handlers" }
    }

    private suspend fun subscribeToRoute(route: Route) {
        val subscription = routing.messageBus.subscribe(route.pattern.subscriptionSubject)

        subscription.messages.collect { message ->
            scope.launch {
                try {
                    val params = route.pattern.extractParams(message.subject)
                    val context = NatsContextImpl(
                        message = message,
                        params = SubjectParams(params),
                        messageBus = routing.messageBus
                    )
                    route.handler.invoke(context)
                } catch (e: Exception) {
                    logger.error(e) { "Error handling ${message.subject}" }
                }
            }
        }
    }

    fun stop() {
        jobs.forEach { it.cancel() }
        jobs.clear()
        logger.info { "Stopped NATS route handlers" }
    }
}
