package com.typewritermc.types

import com.typewritermc.protocol.skir.fromBoundedBytes
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.kotest.matchers.types.shouldBeSameInstanceAs
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring.PreparedEdit
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ValueLocation
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference
import skirout.editor.v1.type_catalog.FieldValue as WireField

val SkirValueDepthTest by testSuite {
    test("deep values fail the portable check rather than overflowing") {
        var value: DataValue = DataValue.UNFILLED
        repeat(10_000) { value = DataValue.record(mapOf("child" to value)) }

        shouldThrow<IllegalArgumentException> { value.requirePortable() }.message shouldBe
            "Authored value exceeds the supported nesting depth."
    }

    test("the portable check admits the authored nesting boundary") {
        val supported = wireValue(512)

        supported.requirePortable() shouldBeSameInstanceAs supported
        shouldThrow<IllegalArgumentException> { wireValue(513).requirePortable() }
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

private fun wireValue(depth: Int): DataValue {
    var value: DataValue = DataValue.UNFILLED
    repeat(depth) { value = DataValue.createRecord(fields = listOf(WireField(name = "child", value = value))) }
    return value
}

private fun preparedEdit(value: DataValue): PreparedEdit =
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
