package com.typewritermc.services.libs.communicator.interfaces

import kotlinx.coroutines.Job

interface RegistrationClient {
    suspend fun queryServiceStatus(serviceId: String): ServiceStatusResult

    suspend fun subscribeToBoundNotification(
        serviceId: String,
        onBound: suspend (organizationId: String, organizationName: String) -> Unit
    ): Job

    suspend fun sendHeartbeat(serviceId: String)

    suspend fun sendShutdown(serviceId: String)
}
