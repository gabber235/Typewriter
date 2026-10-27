package com.typewritermc.types

import com.typewritermc.protocol.skir.fromBoundedBytes
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring.PreparedEdit
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ValueLocation
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference
import skirout.editor.v1.type_catalog.FieldValue as WireField

/** A record nested [depth] times, the innermost one unfilled. */
fun wireValue(depth: Int): DataValue {
    var value: DataValue = DataValue.UNFILLED
    repeat(depth) { value = DataValue.createRecord(fields = listOf(WireField(name = "child", value = value))) }
    return value
}

/** A prepared edit that sets the whole value at the root location, with no expectations. */
fun preparedEdit(value: DataValue): PreparedEdit =
    PreparedEdit(
        catalog = CatalogGeneration(value = "catalog"),
        expectations = emptyList(),
        intents = listOf(EditIntent.createSetValue(at = ValueLocation.partial(), value = value)),
    )

/**
 * Decodes [bytes] as a bounded prepared edit on a thread with a 1 MiB stack, so depth limits are checked where
 * production runs. Fails when decoding takes longer than ten seconds.
 */
fun decodeOnProductionStack(bytes: ByteArray): Result<PreparedEdit> {
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
