package com.typewritermc.loader.standalone.shell.commands.testing

import com.typewritermc.services.libs.registrar.OrganizationBinding
import com.typewritermc.services.libs.registrar.ReadySession
import com.typewritermc.services.libs.registrar.ServiceId
import com.typewritermc.services.libs.registrar.ServiceIdentity
import com.typewritermc.services.libs.registrar.ServiceRole

fun readySession() =
    ReadySession(
        identity = identity,
        binding = OrganizationBinding("organization123", "Test Organization"),
    )

val identity =
    ServiceIdentity(
        serviceId = ServiceId("service123"),
        displayName = "Loader Service",
        username = "loader_service",
        role = ServiceRole.Host("1.0.0"),
    )
