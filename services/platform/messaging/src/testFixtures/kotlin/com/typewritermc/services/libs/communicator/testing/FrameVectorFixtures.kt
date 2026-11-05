package com.typewritermc.services.libs.communicator.testing

import com.typewritermc.services.libs.communicator.transfer.PayloadHeaders
import com.typewritermc.services.libs.communicator.transfer.TransferFailure
import com.typewritermc.services.libs.communicator.transfer.TransferInterrupted
import com.typewritermc.services.libs.communicator.transfer.TransferTooLarge
import com.typewritermc.services.libs.communicator.transport.InboundMessage
import com.typewritermc.services.libs.communicator.transport.MessageHeaders
import com.typewritermc.services.libs.communicator.transport.Payload
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import java.nio.file.Files
import java.nio.file.Path
import kotlin.io.encoding.Base64

/** The shared frame vector cases, read from the `frames.json` the backend framer and the panel assemblers both check. */
fun frameVectorCases(): List<JsonObject> {
    val file =
        generateSequence(Path.of("").toAbsolutePath()) { it.parent }
            .map { it.resolve("skir-src/transport/v1/fixtures/frames.json") }
            .firstOrNull(Files::isRegularFile)
            ?: error("skir-src/transport/v1/fixtures/frames.json is missing; run cargo xtask generate")
    return Json
        .parseToJsonElement(Files.readString(file))
        .jsonObject
        .getValue("cases")
        .jsonArray
        .map { it.jsonObject }
}

/** The frame a vector describes: its headers as name and value pairs, and its body in base64, on [frameRequest]. */
fun JsonObject.vectorMessage(): InboundMessage {
    val headers =
        getValue("headers").jsonArray.map { pair ->
            val (name, value) = pair.jsonArray.map { it.jsonPrimitive.content }
            name to value
        }
    return InboundMessage(frameRequest, Payload.copyOf(base64("body")), headers = MessageHeaders.of(*headers.toTypedArray()))
}

/** Decodes the base64 string stored under [field]. */
fun JsonObject.base64(field: String): ByteArray = Base64.decode(getValue(field).jsonPrimitive.content)

/** The wire name of a transfer failure, the value the failure header carries. */
fun TransferFailure.wireName(): String =
    when (this) {
        is TransferTooLarge -> PayloadHeaders.TOO_LARGE
        is TransferInterrupted -> PayloadHeaders.INTERRUPTED
        else -> error("Unexpected transfer failure $this")
    }
