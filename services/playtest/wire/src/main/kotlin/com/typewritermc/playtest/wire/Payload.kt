package com.typewritermc.playtest.wire

import skirout.harness.v1.wire.StepAck
import skirout.harness.v1.wire.Watch

/**
 * The payloads Paper and the client send each other on the game connection itself, beside the game's
 * own packets, so they keep their order with them. Each has its channel, and its body is the Skir
 * binary form of the payload; Paper and the client write and read a body only through here.
 */
object Payload {
    /** The channel of [Watch], from Paper to the client. */
    const val WATCH_CHANNEL = "playtest:watch"

    /** The channel of [StepAck], from the client to Paper. */
    const val STEP_CHANNEL = "playtest:step"

    @JvmStatic
    fun body(watch: Watch): ByteArray = Watch.serializer.toBytes(watch).toByteArray()

    @JvmStatic
    fun body(ack: StepAck): ByteArray = StepAck.serializer.toBytes(ack).toByteArray()

    /** Reads the whole of [body]: a body that ends early, carries more or holds no watch is refused. */
    @JvmStatic
    @Throws(WireException::class)
    fun watch(body: ByteArray): Watch = Wire.decode(Watch.serializer, body)

    /** Reads the whole of [body]: a body that ends early, carries more or holds no ack is refused. */
    @JvmStatic
    @Throws(WireException::class)
    fun stepAck(body: ByteArray): StepAck = Wire.decode(StepAck.serializer, body)
}
