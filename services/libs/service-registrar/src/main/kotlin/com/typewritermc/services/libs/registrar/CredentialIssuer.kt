package com.typewritermc.services.libs.registrar

import com.typewritermc.services.libs.communicator.interfaces.HttpClient
import io.github.oshai.kotlinlogging.KLogger
import io.github.oshai.kotlinlogging.KotlinLogging.logger
import protokt.v1.typewriter.api.v1.IssueServiceIdentityRequest
import protokt.v1.typewriter.api.v1.IssueServiceIdentityResponse
import protokt.v1.typewriter.models.v1.ServiceMetadata
import protokt.v1.typewriter.models.v1.ServiceType
import java.io.ByteArrayOutputStream

interface CredentialIssuer {
    fun issueCredential(): Credential
}

class BackendCredentialIssuer(
    private val httpClient: HttpClient,
    private val serviceIssueUrl: String,
    private val servicesInfo: ServicesInfo
) : CredentialIssuer {
    private val logger: KLogger = logger {}

    override fun issueCredential(): Credential {
        logger.debug { "Issuing new service credential from $serviceIssueUrl" }

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

        val requestBytes = ByteArrayOutputStream().also { request.serialize(it) }.toByteArray()
        val headers = mapOf("Content-Type" to "application/x-protobuf")

        val response = try {
            httpClient.post(serviceIssueUrl, requestBytes, headers)
        } catch (e: Exception) {
            logger.error(e) { "Failed to issue credential: connection error" }
            throw IssueException("Failed to issue credential: ${e.message}", e)
        }

        if (!response.isSuccessful) {
            val errorBody = response.body.bufferedReader().readText()
            logger.error { "Credential issuance failed: HTTP ${response.statusCode} - $errorBody" }
            throw IssueException("Failed to issue credential: HTTP ${response.statusCode}")
        }

        val protoResponse = try {
            IssueServiceIdentityResponse.deserialize(response.body)
        } catch (e: Exception) {
            logger.error(e) { "Failed to parse credential response" }
            throw IssueException("Failed to parse credential response", e)
        }

        return when (val result = protoResponse.result) {
            is IssueServiceIdentityResponse.Result.Credentials -> {
                logger.info { "Credential issued successfully: ${result.credentials.serviceId}" }
                Credential(
                    id = result.credentials.serviceId,
                    name = result.credentials.username,
                    token = result.credentials.token
                )
            }

            is IssueServiceIdentityResponse.Result.Error -> {
                logger.error { "Backend returned error: ${result.error.code} - ${result.error.message}" }
                throw IssueException(
                    "Service returned error (${result.error.code}): ${result.error.message}"
                )
            }

            null -> throw IssueException("Empty response from identity service")
        }
    }
}

class IssueException(message: String, cause: Throwable? = null) : RuntimeException(message, cause)
