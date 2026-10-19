package com.typewritermc.types

import com.typewritermc.protocol.skir.fromBoundedBytes
import com.typewritermc.types.skir.SkirConversionResult
import com.typewritermc.types.skir.SkirDataValueCodec
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring.PreparedEdit
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.ValueLocation
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference
import skirout.editor.v1.type_catalog.DataValue as WireValue
import skirout.editor.v1.type_catalog.FieldValue as WireField

val SkirValueDepthTest by testSuite {
    test("deep authored encoding returns a diagnostic rather than overflowing") {
        var value: DataValue = DataValue.Unfilled
        repeat(10_000) { value = DataValue.Record(mapOf("child" to value)) }

        val result = SkirDataValueCodec.encode(value).shouldBeInstanceOf<SkirConversionResult.Failure>()
        result.diagnostics.single().message shouldBe "Authored value exceeds the supported nesting depth."
    }

    test("deep wire decoding returns a diagnostic rather than overflowing") {
        var value: WireValue = WireValue.UNFILLED
        repeat(10_000) { value = WireValue.createRecord(fields = listOf(WireField(name = "child", value = value))) }

        val result = SkirDataValueCodec.decode(value).shouldBeInstanceOf<SkirConversionResult.Failure>()
        result.diagnostics.single().message shouldBe "Authored value exceeds the supported nesting depth."
    }

    test("encode and decode admit the same value nesting boundary") {
        var value: DataValue = DataValue.Unfilled
        repeat(512) { value = DataValue.Record(mapOf("child" to value)) }

        val encoded = SkirDataValueCodec.encode(value).shouldBeInstanceOf<SkirConversionResult.Success<*>>()
        val decoded = SkirDataValueCodec.decode(encoded.value as WireValue).shouldBeInstanceOf<SkirConversionResult.Success<*>>()
        decoded.value shouldBe value

        SkirDataValueCodec
            .encode(DataValue.Record(mapOf("child" to value)))
            .shouldBeInstanceOf<SkirConversionResult.Failure>()
    }

    test("raw prepared edit binary decoding admits the authored boundary and rejects excessive depth") {
        val supported = preparedEdit(wireValue(512))
        val supportedResult = decodeOnProductionStack(PreparedEdit.serializer.toBytes(supported).toByteArray())
        supportedResult.getOrThrow() shouldBe supported

        val excessive = preparedEdit(wireValue(530))
        val excessiveResult = decodeOnProductionStack(PreparedEdit.serializer.toBytes(excessive).toByteArray())
        excessiveResult.exceptionOrNull().shouldBeInstanceOf<IllegalArgumentException>()
    }

    test("hostile binary and JSON nesting fail with a normal exception instead of exhausting the stack") {
        val depth = 100_000
        val binary = "skir".encodeToByteArray() + ByteArray(depth) { 247.toByte() } + byteArrayOf(0)
        val json = ("[".repeat(depth) + "]".repeat(depth)).encodeToByteArray()

        decodeOnProductionStack(binary).exceptionOrNull().shouldBeInstanceOf<IllegalArgumentException>()
        decodeOnProductionStack(json).exceptionOrNull().shouldBeInstanceOf<IllegalArgumentException>()
    }
}

private fun wireValue(depth: Int): WireValue {
    var value: WireValue = WireValue.UNFILLED
    repeat(depth) { value = WireValue.createRecord(fields = listOf(WireField(name = "child", value = value))) }
    return value
}

private fun preparedEdit(value: WireValue): PreparedEdit =
    PreparedEdit(
        catalog = CatalogGeneration(value = "catalog"),
        expectations = emptyList(),
        intents = listOf(EditIntent.createSetValue(at = ValueLocation.partial(), value = value)),
    )

private fun decodeOnProductionStack(bytes: ByteArray): Result<PreparedEdit> {
    val result = AtomicReference<Result<PreparedEdit>>()
    val thread =
        Thread(
            null,
            { result.set(runCatching { PreparedEdit.serializer.fromBoundedBytes(bytes) }) },
            "prepared edit depth",
            1024L * 1024L,
        )
    thread.isDaemon = true
    thread.start()
    thread.join(TimeUnit.SECONDS.toMillis(10))
    if (thread.isAlive) {
        thread.interrupt()
        error("Prepared edit decoding exceeded its time limit.")
    }
    return result.get()
}
