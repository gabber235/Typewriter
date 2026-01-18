package com.typewritermc.services.libs.communicator.interfaces

import java.net.HttpURLConnection
import java.net.URI

class SimpleHttpClient : HttpClient {

    override fun get(url: String, headers: Map<String, String>): HttpResponse {
        val connection = URI(url).toURL().openConnection() as HttpURLConnection
        connection.requestMethod = "GET"
        headers.forEach { (key, value) -> connection.setRequestProperty(key, value) }

        return buildResponse(connection)
    }

    override fun post(url: String, body: ByteArray, headers: Map<String, String>): HttpResponse {
        val connection = URI(url).toURL().openConnection() as HttpURLConnection
        connection.requestMethod = "POST"
        connection.doOutput = true
        headers.forEach { (key, value) -> connection.setRequestProperty(key, value) }

        connection.outputStream.use { it.write(body) }

        return buildResponse(connection)
    }

    private fun buildResponse(connection: HttpURLConnection): HttpResponse {
        val statusCode = connection.responseCode
        val stream = if (statusCode in 200..299) {
            connection.inputStream
        } else {
            connection.errorStream
        }

        val responseHeaders = connection.headerFields
            .filterKeys { it != null }
            .mapValues { it.value.firstOrNull() ?: "" }

        return HttpResponse(
            statusCode = statusCode,
            body = stream,
            headers = responseHeaders
        )
    }
}
