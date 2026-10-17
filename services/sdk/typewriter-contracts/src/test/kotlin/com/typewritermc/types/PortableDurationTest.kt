package com.typewritermc.types

import com.typewritermc.types.skir.SkirConversionResult
import com.typewritermc.types.skir.SkirDataValueCodec
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.boolean
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import java.nio.file.Files
import java.nio.file.Path
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.nanoseconds
import skirout.editor.v1.type_catalog.DataValue as WireValue
import skirout.kernel.v1.duration.Duration as WireDuration

val PortableDurationTest by testSuite {
    val fixturePath =
        generateSequence(Path.of("").toAbsolutePath()) {
            it.parent
        }.map { it.resolve("skir-src/editor/v1/fixtures/portable_duration_conformance.json") }.first(Files::exists)
    val fixture = Json.parseToJsonElement(Files.readString(fixturePath)).jsonObject
    fixture
        .getValue("maximumMilliseconds")
        .jsonPrimitive.content
        .toLong() shouldBe MAX_PORTABLE_DURATION_MILLISECONDS
    fixture.getValue("cases").jsonArray.forEach { item ->
        val case = item.jsonObject
        test(case.getValue("id").jsonPrimitive.content) {
            val milliseconds =
                case
                    .getValue("milliseconds")
                    .jsonPrimitive.content
                    .toLong()
            val admitted = case.getValue("admitted").jsonPrimitive.boolean
            milliseconds.isPortableDurationMilliseconds() shouldBe admitted
            val wire = WireValue.createDuration(value = WireDuration(milliseconds = milliseconds))
            val result = SkirDataValueCodec.decode(wire)
            if (admitted) {
                val duration = result.shouldBeInstanceOf<SkirConversionResult.Success<DataValue>>().value as DataValue.Duration
                duration.value.inWholeMilliseconds shouldBe milliseconds
                SkirDataValueCodec.encode(duration).shouldBeInstanceOf<SkirConversionResult.Success<WireValue>>().value shouldBe wire
            } else {
                shouldThrow<IllegalArgumentException> { DataValue.Duration(milliseconds.milliseconds) }
                result
                    .shouldBeInstanceOf<SkirConversionResult.Failure>()
                    .diagnostics
                    .single()
                    .message shouldBe
                    "Duration millisecond count exceeds the finite portable range."
            }
        }
    }
    fixture.getValue("steps").jsonArray.forEach { item ->
        val case = item.jsonObject
        test(case.getValue("id").jsonPrimitive.content) {
            val initial =
                case
                    .getValue("value")
                    .jsonPrimitive.content
                    .toLong()
            val increment =
                case
                    .getValue("increment")
                    .jsonPrimitive.content
                    .toLong()
            val admitted = case.getValue("admitted").jsonPrimitive.boolean
            (initial + increment).isPortableDurationMilliseconds() shouldBe admitted
            (initial.milliseconds + increment.milliseconds).isPortableDuration() shouldBe admitted
        }
    }
    test("model rejects infinite and fractional millisecond durations") {
        shouldThrow<IllegalArgumentException> { DataValue.Duration(Duration.INFINITE) }
        shouldThrow<IllegalArgumentException> { DataValue.Duration(-Duration.INFINITE) }
        shouldThrow<IllegalArgumentException> { DataValue.Duration(1.nanoseconds) }
    }
}
