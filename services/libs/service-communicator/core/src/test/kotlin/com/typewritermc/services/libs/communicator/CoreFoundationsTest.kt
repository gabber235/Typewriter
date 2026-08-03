package com.typewritermc.services.libs.communicator

import com.typewritermc.services.libs.communicator.address.AddressValues
import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.address.addressTemplate
import com.typewritermc.services.libs.communicator.address.addressValuesOf
import com.typewritermc.services.libs.communicator.contract.PayloadCodec
import com.typewritermc.services.libs.communicator.transport.InboundMessage
import com.typewritermc.services.libs.communicator.transport.MessageHeaders
import com.typewritermc.services.libs.communicator.transport.OutboundMessage
import com.typewritermc.services.libs.communicator.transport.TransportDelivery
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.communicator.transport.TransportResult
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import java.util.Locale

data class ExampleAddress(
    val service: String,
    val organization: String,
)

private val template =
    addressTemplate(
        "realm.{service}.organization.{organization}",
        { addressValuesOf("service" to it.service, "organization" to it.organization) },
        { ExampleAddress(it.require("service"), it.require("organization")) },
    )

private val codec =
    object : PayloadCodec<String> {
        override fun encode(value: String): ByteArray = value.encodeToByteArray()

        override fun decode(payload: ByteArray): String = payload.decodeToString()
    }

val CoreFoundationsTest by testSuite {
    test("addresses render and structurally match") {
        val value = ExampleAddress("engine", "org-1")
        template.render(value).value shouldBe "realm.engine.organization.org-1"
        template.match(MessageAddress.of("realm.engine.organization.org-1")) shouldBe value
        template.match(MessageAddress.of("other.engine.organization.org-1")) shouldBe null
    }

    test("bound subscriptions retain stable templates and use one concrete address") {
        val value = ExampleAddress("engine", "org-1")
        val bound = template.subscribedAt(value)

        bound.template shouldBe template.template
        bound.subscriptionPattern.value shouldBe "realm.engine.organization.org-1"
        bound.render(value) shouldBe template.render(value)
    }

    test("patterns reject malformed literals and placeholders") {
        listOf(
            "",
            " ",
            ".a",
            "a.",
            "a..b",
            "a.*",
            "a.>",
            "a. b",
            "a.{x}.{x}",
            "a.{bad-name}",
            "a.{1bad}",
            "a.{}",
            "a.{{x}}",
            "a.{x",
            "a.x}",
            "a.x{y}",
        ).forEach { pattern ->
            shouldThrow<IllegalArgumentException> {
                addressTemplate(pattern, { addressValuesOf() }, { Any() })
            }
        }
    }

    test("concrete addresses and rendered values reject injection") {
        listOf("", " ", ".a", "a.", "a..b", "a.*", "a.>", "a.{x}", "a.x y").forEach {
            shouldThrow<IllegalArgumentException> { MessageAddress.of(it) }
        }
        listOf("", "bad.value", "*", ">", "{bad}", "bad value", "bad\tvalue").forEach { value ->
            shouldThrow<IllegalArgumentException> { template.render(ExampleAddress(value, "org")) }
        }
    }

    test("renderer keys and address values are exact and unique") {
        shouldThrow<IllegalArgumentException> { AddressValues.of("key" to "one", "key" to "two") }
        val missing = addressTemplate("a.{x}", { addressValuesOf() }, { ExampleAddress("", "") })
        val extra = addressTemplate("a.{x}", { addressValuesOf("x" to "x", "y" to "y") }, { ExampleAddress("", "") })
        shouldThrow<IllegalArgumentException> { missing.render(ExampleAddress("x", "y")) }
        shouldThrow<IllegalArgumentException> { extra.render(ExampleAddress("x", "y")) }
    }

    test("headers compare without case or insertion order and preserve value order") {
        val first = MessageHeaders.of("TraceParent" to "one", "X-Test" to "a", "traceparent" to "two")
        val second = MessageHeaders.of("x-test" to "a", "TRACEPARENT" to "one", "TraceParent" to "two")
        first shouldBe second
        first.hashCode() shouldBe second.hashCode()
        first shouldBe first
        (first == MessageHeaders.of("traceparent" to "two", "traceparent" to "one", "x-test" to "a")) shouldBe false
    }

    test("header canonicalization is independent of default locale") {
        val previous = Locale.getDefault()
        try {
            Locale.setDefault(Locale.forLanguageTag("tr-TR"))
            MessageHeaders.of("I-Test" to "value")["i-test"] shouldBe listOf("value")
        } finally {
            Locale.setDefault(previous)
        }
    }

    test("header lookup and iteration cannot mutate source") {
        val headers = MessageHeaders.of("X-Test" to "one")
        shouldThrow<UnsupportedOperationException> { (headers["x-test"] as MutableList<String>).add("two") }
        val iterated = headers.first().second
        shouldThrow<UnsupportedOperationException> { (iterated as MutableList<String>).clear() }
        headers["x-test"] shouldBe listOf("one")
    }

    test("headers reject invalid names and unsafe values") {
        listOf("", "x test", "x:test", "x(test)", "x@test", "x\tname", "x\u0080name").forEach {
            shouldThrow<IllegalArgumentException> { MessageHeaders.of(it to "value") }
        }
        listOf("nul\u0000", "cr\r", "lf\n", "bell\u0007", "delete\u007f").forEach {
            shouldThrow<IllegalArgumentException> { MessageHeaders.of("X-Test" to it) }
        }
        MessageHeaders.of("X-Test" to "tab\tallowed")["x-test"] shouldBe listOf("tab\tallowed")
    }

    test("inbound and outbound envelopes use content equality and complete hashes") {
        val headers = MessageHeaders.of("X-Test" to "one")
        val address = MessageAddress.of("book.get")
        val reply = MessageAddress.of("reply.here")
        val outbound = OutboundMessage(address, byteArrayOf(1, 2), reply, headers)
        outbound shouldBe OutboundMessage(address, byteArrayOf(1, 2), reply, MessageHeaders.of("x-test" to "one"))
        outbound.hashCode() shouldBe OutboundMessage(address, byteArrayOf(1, 2), reply, headers).hashCode()
        val inbound = InboundMessage(address, byteArrayOf(1, 2), reply, headers)
        inbound shouldBe InboundMessage(address, byteArrayOf(1, 2), reply, MessageHeaders.of("x-test" to "one"))
        inbound.hashCode() shouldBe InboundMessage(address, byteArrayOf(1, 2), reply, headers).hashCode()
    }

    test("all transport failures and delivery variants remain typed") {
        val cause = IllegalStateException("failure")
        listOf(
            TransportError.Timeout(),
            TransportError.Unavailable(cause),
            TransportError.NoResponders(cause),
            TransportError.Failure(cause),
        ).forEach { error ->
            TransportResult.Failure(error).error shouldBe error
            TransportDelivery.Failure(error).error shouldBe error
        }
        TransportResult.Success("value").value shouldBe "value"
        TransportDelivery.Completed shouldBe TransportDelivery.Completed
    }

    test("codec exposes explicit encode and decode") {
        codec.decode(codec.encode("value")) shouldBe "value"
    }
}
