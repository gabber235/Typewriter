package com.typewritermc.services.libs.registrar.http

import java.io.InputStream

data class HttpResponse(
    val statusCode: Int,
    val body: InputStream,
    val headers: Map<String, String> = emptyMap()
) {
    val isSuccessful: Boolean get() = statusCode in 200..299
}

interface HttpClient {
    fun get(
        url: String,
        headers: Map<String, String> = emptyMap()
    ): HttpResponse

    fun post(
        url: String,
        body: ByteArray,
        headers: Map<String, String> = emptyMap()
    ): HttpResponse
}
