package com.typewritermc.types

import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldValue
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.ListPayload
import skirout.editor.v1.type_catalog.MapPayload
import skirout.editor.v1.type_catalog.MapRow
import skirout.editor.v1.type_catalog.NamedValue
import skirout.editor.v1.type_catalog.RecordPayload
import java.lang.management.ManagementFactory
import java.util.concurrent.CyclicBarrier
import java.util.concurrent.TimeUnit
import kotlin.concurrent.thread
import kotlin.system.exitProcess

object SkirColdProbeMain {
    @JvmStatic
    fun main(arguments: Array<String>) {
        when (arguments.single()) {
            "concurrent" -> concurrentFirstAccess()
            else -> serialFirstAccess(arguments.single())
        }
    }

    private fun serialFirstAccess(entry: String) {
        val serializer =
            when (entry) {
                "FieldValue" -> FieldValue.serializer
                "RecordPayload" -> RecordPayload.serializer
                "NamedValue" -> NamedValue.serializer
                "ListItem" -> ListItem.serializer
                "ListPayload" -> ListPayload.serializer
                "MapRow" -> MapRow.serializer
                "MapPayload" -> MapPayload.serializer
                "DataValue" -> DataValue.serializer
                else -> error("Unknown serializer entry $entry")
            }

        check(serializer.typeDescriptor.toString().isNotEmpty())
        check(FieldValue.typeDescriptor.fields.isNotEmpty())
        check(DataValue.typeDescriptor.variants.isNotEmpty())

        val value =
            DataValue.createRecord(
                fields = listOf(FieldValue(name = "name", value = DataValue.StringValueWrapper("value"))),
            )
        val bytes = DataValue.serializer.toBytes(value)
        check(DataValue.serializer.fromBytes(bytes) == value)
        println("ok $entry ${bytes.size}")
    }

    private fun concurrentFirstAccess() {
        val barrier = CyclicBarrier(2)
        val failures = mutableListOf<Throwable>()
        val fieldThread =
            thread(name = "field", isDaemon = true) {
                capture(failures) {
                    barrier.await(10, TimeUnit.SECONDS)
                    FieldValue.serializer
                }
            }
        val valueThread =
            thread(name = "value", isDaemon = true) {
                capture(failures) {
                    barrier.await(10, TimeUnit.SECONDS)
                    DataValue.serializer
                }
            }

        val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(30)
        joinUntil(fieldThread, deadline)
        joinUntil(valueThread, deadline)
        if (fieldThread.isAlive || valueThread.isAlive) {
            System.err.println("deadlock field=${fieldThread.state} value=${valueThread.state}")
            val bean = ManagementFactory.getThreadMXBean()
            val deadlocked = bean.findDeadlockedThreads()?.toSet().orEmpty()
            dumpThread(fieldThread, fieldThread.threadId() in deadlocked)
            dumpThread(valueThread, valueThread.threadId() in deadlocked)
            exitProcess(2)
        }
        if (failures.isNotEmpty()) {
            failures.forEach(Throwable::printStackTrace)
            exitProcess(1)
        }
        println("ok concurrent cold initialization")
    }

    private fun dumpThread(
        thread: Thread,
        deadlocked: Boolean,
    ) {
        System.err.println("thread ${thread.name} id=${thread.threadId()} state=${thread.state} deadlocked=$deadlocked")
        thread.stackTrace.forEach { frame -> System.err.println("  at $frame") }
    }

    private fun joinUntil(
        thread: Thread,
        deadline: Long,
    ) {
        val remaining = deadline - System.nanoTime()
        if (remaining <= 0) return
        thread.join(TimeUnit.NANOSECONDS.toMillis(remaining).coerceAtLeast(1))
    }

    private inline fun capture(
        failures: MutableList<Throwable>,
        action: () -> Unit,
    ) {
        try {
            action()
        } catch (failure: Throwable) {
            synchronized(failures) {
                failures += failure
            }
        }
    }
}
