package com.typewritermc.visibility.packet

import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.shouldBe
import java.nio.ByteBuffer
import java.util.UUID

private fun source(bytes: ByteArray): () -> Byte? {
    val iterator = bytes.iterator()
    return { if (iterator.hasNext()) iterator.next() else null }
}

private fun playerInfoHead(count: Int, profileId: UUID?): ByteArray {
    val buffer = ByteBuffer.allocate(1 + 1 + Long.SIZE_BYTES * 2)
    buffer.put(0b10)
    buffer.put(count.toByte())
    if (profileId != null) {
        buffer.putLong(profileId.mostSignificantBits)
        buffer.putLong(profileId.leastSignificantBits)
    }
    return buffer.array().copyOf(buffer.position())
}

private fun entityEvent(entityId: Int, eventId: Int): ByteArray =
    ByteBuffer.allocate(Int.SIZE_BYTES + 1).putInt(entityId).put(eventId.toByte()).array()

class OwnPlayerPacketDecodingSpec : FunSpec({

    val viewer = UUID.randomUUID()

    test("a packet about the viewer alone carries their entry") {
        mayCarryEntryOf(viewer, source(playerInfoHead(1, viewer))) shouldBe true
    }

    test("a packet about somebody else alone does not") {
        mayCarryEntryOf(viewer, source(playerInfoHead(1, UUID.randomUUID()))) shouldBe false
    }

    test("a list of several players has to be decoded to tell") {
        mayCarryEntryOf(viewer, source(playerInfoHead(3, null))) shouldBe true
    }

    test("an empty or truncated packet carries nothing") {
        mayCarryEntryOf(viewer, source(playerInfoHead(0, null))) shouldBe false
        mayCarryEntryOf(viewer, source(playerInfoHead(1, viewer).copyOf(10))) shouldBe false
        mayCarryEntryOf(viewer, source(ByteArray(0))) shouldBe false
    }

    test("each permission level event about the player's own entity reads as its level") {
        for (level in 0..4) {
            decodeOwnPermissionLevel(42, source(entityEvent(42, 24 + level))) shouldBe level
        }
    }

    test("a permission level event about another entity is ignored") {
        decodeOwnPermissionLevel(42, source(entityEvent(43, 28))).shouldBeNull()
    }

    test("any other event about the player's own entity is ignored") {
        decodeOwnPermissionLevel(42, source(entityEvent(42, 2))).shouldBeNull()
        decodeOwnPermissionLevel(42, source(entityEvent(42, 29))).shouldBeNull()
    }

    test("a truncated entity event gives nothing") {
        decodeOwnPermissionLevel(42, source(entityEvent(42, 24).copyOf(3))).shouldBeNull()
        decodeOwnPermissionLevel(42, source(entityEvent(42, 24).copyOf(4))).shouldBeNull()
    }

    test("a negative entity id survives the decode") {
        decodeOwnPermissionLevel(-7, source(entityEvent(-7, 26))) shouldBe 2
    }
})
