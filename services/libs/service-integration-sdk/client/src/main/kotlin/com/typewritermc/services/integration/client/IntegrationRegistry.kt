package com.typewritermc.services.integration.client

import com.typewritermc.services.integration.IntegrationId
import com.typewritermc.services.integration.IntegrationRegistration

class IntegrationRegistry {
    private val registrations = linkedMapOf<IntegrationId, RegisteredIntegration>()
    private var nextLease = 1L

    @Synchronized
    fun register(registration: IntegrationRegistration): RegistrationResult {
        if (registration.id in registrations) return RegistrationResult.Duplicate(registration.id)
        val lease = IntegrationLease(registration.id, nextLease++)
        registrations[registration.id] = RegisteredIntegration(registration, lease)
        return RegistrationResult.Registered(lease)
    }

    @Synchronized
    fun unregister(lease: IntegrationLease): Boolean {
        val registered = registrations[lease.integrationId] ?: return false
        if (registered.lease != lease) return false
        registrations.remove(lease.integrationId)
        return true
    }

    @Synchronized
    fun registration(id: IntegrationId): IntegrationRegistration? = registrations[id]?.registration

    @Synchronized
    fun registrations(): List<IntegrationRegistration> = registrations.values.map(RegisteredIntegration::registration)
}

@ConsistentCopyVisibility
data class IntegrationLease internal constructor(
    val integrationId: IntegrationId,
    internal val sequence: Long,
)

sealed interface RegistrationResult {
    data class Registered(
        val lease: IntegrationLease,
    ) : RegistrationResult

    data class Duplicate(
        val integrationId: IntegrationId,
    ) : RegistrationResult
}

private data class RegisteredIntegration(
    val registration: IntegrationRegistration,
    val lease: IntegrationLease,
)
