package com.typewritermc.loader.testing

import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.registrar.MessagingOperation
import com.typewritermc.services.libs.registrar.OrganizationBinding
import com.typewritermc.services.libs.registrar.ReadySession
import com.typewritermc.services.libs.registrar.RegistrarFailure
import com.typewritermc.services.libs.registrar.RegistrarStage
import com.typewritermc.services.libs.registrar.RegistrarState
import com.typewritermc.services.libs.registrar.RetrySchedule
import com.typewritermc.services.libs.registrar.ServiceId
import com.typewritermc.services.libs.registrar.ServiceIdentity
import com.typewritermc.services.libs.registrar.ServiceRole
import com.typewritermc.services.libs.telemetry.serviceTelemetry
import io.opentelemetry.api.OpenTelemetry
import io.opentelemetry.context.propagation.ContextPropagators
import kotlin.time.Duration.Companion.seconds

/** A hosted messaging session [id] for an organization, whose communicator sends over [transport]. */
fun hostedSession(
    transport: FakeMessageTransport,
    id: Long = 1,
) = HostedMessagingSession(
    id,
    "organization",
    Communicator(transport, OpenTelemetry.noop().serviceTelemetry("loader test"), ContextPropagators.noop()),
)

fun degradedState() =
    RegistrarState.DegradedAfterReady(
        readySession,
        RegistrarStage.CONNECTING,
        RegistrarFailure.Messaging(MessagingOperation.CONNECTIVITY),
        RetrySchedule(1, 1.seconds),
    )

val binding = OrganizationBinding("organization", "Organization")

private val readySession =
    ReadySession(
        ServiceIdentity(ServiceId("service"), "Service", "service-user", ServiceRole.Host("1")),
        binding,
    )
