package com.typewritermc.services.libs.registrar

import com.typewritermc.services.libs.communicator.interfaces.HttpClient
import com.typewritermc.services.libs.telemetry.withSpan
import io.opentelemetry.api.trace.StatusCode
import io.opentelemetry.api.trace.Tracer
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
    private val servicesInfo: ServicesInfo,
    private val tracer: Tracer,
) : CredentialIssuer {
    override fun issueCredential(): Credential = tracer.withSpan("credential.issue") { s ->
        s.setAttribute("http.url", serviceIssueUrl)

        servicesInfo.realm?.let { s.setAttribute("service.realm.version", it.version) }
        servicesInfo.engine?.let { s.setAttribute("service.engine.version", it.version) }

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
            throw IssueException("Failed to issue credential: ${e.message}", e)
        }

        s.setAttribute("http.status_code", response.statusCode.toLong())

        if (!response.isSuccessful) {
            val errorCode = response.statusCode
            val errorBody = response.body.bufferedReader().readText()
            s.setAttribute("http.response.status_code", errorCode.toLong())
            s.setAttribute("http.response.body", errorBody)
            throw IssueException("Failed to issue credential: HTTP ${response.statusCode}")
        }

        val protoResponse = try {
            IssueServiceIdentityResponse.deserialize(response.body)
        } catch (e: Exception) {
            throw IssueException("Failed to parse credential response: ${e.message}", e)
        }

        when (val result = protoResponse.result) {
            is IssueServiceIdentityResponse.Result.Credentials -> {
                val id = result.credentials.serviceId
                val name = result.credentials.username
                val token = result.credentials.token
                s.setAttribute("result.service.id", id)
                    .setAttribute("result.service.name", name)
                    .setStatus(StatusCode.OK)
                Credential(id = id, name = name, token = token)
            }

            is IssueServiceIdentityResponse.Result.Error -> {
                val code = result.error.code ?: 0u
                val message = result.error.message ?: "Unknown error"
                s.setAttribute("result.error.code", code.toLong())
                s.setAttribute("result.error.message", message)
                throw IssueException(
                    "Service returned error ($code): $message"
                )
            }

            null -> {
                throw IssueException("Empty response from identity service")
            }
        }
    }
}

class IssueException(message: String, cause: Throwable? = null) : RuntimeException(message, cause)
