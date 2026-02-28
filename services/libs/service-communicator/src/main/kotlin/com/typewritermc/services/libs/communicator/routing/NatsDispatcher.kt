package com.typewritermc.services.libs.communicator.routing

import com.typewritermc.services.libs.telemetry.withSuspendSpan
import io.github.oshai.kotlinlogging.KotlinLogging
import io.opentelemetry.api.trace.SpanKind
import io.opentelemetry.api.trace.Tracer
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch

private val logger = KotlinLogging.logger {}

class NatsDispatcher(
    private val routing: NatsRouting,
    private val scope: CoroutineScope,
    private val tracer: Tracer
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
                    tracer.withSuspendSpan(route.pattern.pattern, SpanKind.SERVER) { span ->
                        // TODO: Extract trace context from NATS headers for distributed tracing
                        span.setAttribute("messaging.system", "nats")
                            .setAttribute("messaging.origin", message.subject)
                            .setAttribute("messaging.operation", "receive")

                        if (message.replyTo != null) {
                            span.setAttribute("messaging.destination", message.replyTo)
                        }


                        val params = route.pattern.extractParams(message.subject)
                        val context = NatsContextImpl(
                            message = message,
                            params = SubjectParams(params),
                            messageBus = routing.messageBus,
                            span = span
                        )
                        route.handler.invoke(context)
                    }
                } catch (_: Exception) {
                    // It will already be logged by the span and captured.
                    // We want to prevent propagation so it doesn't cancel the subscription.
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
