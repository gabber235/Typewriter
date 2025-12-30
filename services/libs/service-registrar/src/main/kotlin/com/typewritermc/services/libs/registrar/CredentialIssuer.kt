package com.typewritermc.services.libs.registrar

import jdk.internal.joptsimple.internal.Messages.message
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import org.koin.core.qualifier.named
import protokt.v1.typewriter.api.v1.IssueServiceIdentityRequest
import protokt.v1.typewriter.api.v1.IssueServiceIdentityResponse
import protokt.v1.typewriter.models.v1.ServiceMetadata
import protokt.v1.typewriter.models.v1.ServiceType
import java.net.HttpURLConnection
import java.net.URI

/**
 * Represents an entity capable of issuing credentials.
 *
 * Implementations of this interface are responsible for generating and issuing
 * instances of the [Credential] class. These credentials can then be used for
 * authentication and authorization purposes within the typewriter cloud.
 */
interface CredentialIssuer {
    fun issueCredential(): Credential
}

class BackendCredentialIssuer : CredentialIssuer, KoinComponent {
    private val serviceIssueUrl: String by inject(named("service-issue-url"))
    private val servicesInfo: ServicesInfo by inject()

    override fun issueCredential(): Credential {
        val request = IssueServiceIdentityRequest {
            metadata = ServiceMetadata {
                servicesInfo.realm?.let { realmVersion = it.version }
                servicesInfo.engine?.let { engineVersion = it.version }
            }
            serviceTypes = buildList {
                servicesInfo.realm?.let { add(ServiceType.REALM) }
                servicesInfo.engine?.let { add(ServiceType.ENGINE) }
            }
        }

        val url = URI(serviceIssueUrl).toURL()
        val connection = url.openConnection() as HttpURLConnection

        connection.requestMethod = "POST"
        connection.doOutput = true
        connection.setRequestProperty("Content-Type", "application/x-protobuf")

        request.serialize(connection.outputStream)

        val responseCode = connection.responseCode
        val stream = if (responseCode in 200..299) {
            connection.inputStream
        } else {
            connection.errorStream
        }

        val response = IssueServiceIdentityResponse.deserialize(stream)

        return when (val result = response.result) {
            is IssueServiceIdentityResponse.Result.Credentials -> Credential(
                id = result.credentials.serviceId,
                name = result.credentials.username,
                token = result.credentials.token
            )

            is IssueServiceIdentityResponse.Result.Error -> throw IssueException(
                "Service returned error (${result.error.code}): ${result.error.message}"
            )

            null -> throw IssueException("Empty response from identity service")
        }
    }
}

class IssueException(message: String) : RuntimeException(message)