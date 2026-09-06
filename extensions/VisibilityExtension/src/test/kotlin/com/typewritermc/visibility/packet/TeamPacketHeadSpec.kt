package com.typewritermc.visibility.packet

import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerTeams
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe

private fun varInt(value: Int): List<Byte> {
    var remaining = value
    val bytes = ArrayList<Byte>()
    while (true) {
        if (remaining and 0x7F.inv() == 0) {
            bytes.add(remaining.toByte())
            return bytes
        }
        bytes.add(((remaining and 0x7F) or 0x80).toByte())
        remaining = remaining ushr 7
    }
}

private fun string(value: String): List<Byte> {
    val encoded = value.toByteArray(Charsets.UTF_8)
    return varInt(encoded.size) + encoded.toList()
}

private fun packet(
    teamName: String,
    mode: Int,
    members: List<String>? = null,
    trailing: List<Byte> = emptyList(),
): List<Byte> {
    val bytes = ArrayList<Byte>()
    bytes.addAll(string(teamName))
    bytes.add(mode.toByte())
    if (members != null) {
        bytes.addAll(varInt(members.size))
        members.forEach { bytes.addAll(string(it)) }
    }
    bytes.addAll(trailing)
    return bytes
}

private fun read(bytes: List<Byte>): TeamPacketHead? {
    var index = 0
    return decodeTeamPacketHead(bytes.size) { if (index >= bytes.size) null else bytes[index++] }
}

class TeamPacketHeadSpec : FunSpec({
    test("reads the name and the entries of an add") {
        val head = read(packet("staff", 3, listOf("Alice", "Bob")))

        head.shouldNotBeNull()
        head.teamName shouldBe "staff"
        head.mode shouldBe WrapperPlayServerTeams.TeamMode.ADD_ENTITIES
        head.members.shouldNotBeNull() shouldContainExactly listOf("Alice", "Bob")
    }

    test("reads the entries of a remove of entries") {
        val head = read(packet("staff", 4, listOf("Alice")))

        head.shouldNotBeNull().mode shouldBe WrapperPlayServerTeams.TeamMode.REMOVE_ENTITIES
        head.members.shouldNotBeNull() shouldContainExactly listOf("Alice")
    }

    test("an empty entry list reads as no entries rather than as unreachable") {
        val head = read(packet("staff", 3, emptyList()))

        head.shouldNotBeNull().members.shouldNotBeNull() shouldContainExactly emptyList()
    }

    /**
     * The create carries component data between the mode and the entries, so the entries are
     * deliberately reported as unreachable rather than misread.
     */
    test("a create reports its entries as unreachable") {
        val head = read(packet("staff", 0, trailing = listOf(1, 2, 3, 4, 5).map { it.toByte() }))

        head.shouldNotBeNull()
        head.teamName shouldBe "staff"
        head.mode shouldBe WrapperPlayServerTeams.TeamMode.CREATE
        head.members.shouldBeNull()
    }

    test("modes that cannot move an entry report no entries") {
        read(packet("staff", 1)).shouldNotBeNull().members.shouldBeNull()
        read(packet("staff", 2, trailing = listOf(9.toByte()))).shouldNotBeNull().members.shouldBeNull()
    }

    test("a mode outside the protocol is refused") {
        read(packet("staff", 7)).shouldBeNull()
    }

    test("a name of more bytes than the packet has is refused") {
        // A length that cannot possibly be satisfied must not become an allocation of that size.
        val bytes = varInt(1 shl 20) + listOf<Byte>(3)
        read(bytes).shouldBeNull()
    }

    test("an entry count of more entries than the packet has room for is refused") {
        val bytes = string("staff") + listOf<Byte>(3) + varInt(1 shl 20)
        read(bytes).shouldBeNull()
    }

    test("running out of bytes part way through the entries is refused") {
        val full = packet("staff", 3, listOf("Alice", "Bob"))
        read(full.dropLast(2)).shouldBeNull()
    }

    test("a team name outside ascii survives the round trip") {
        val head = read(packet("gilde_grün", 3, listOf("Åke")))

        head.shouldNotBeNull().teamName shouldBe "gilde_grün"
        head.members.shouldNotBeNull() shouldContainExactly listOf("Åke")
    }

    test("only the head is consumed, so the rest of the packet is left alone") {
        val bytes = packet("staff", 3, listOf("Alice")) + listOf<Byte>(42, 43)
        var index = 0
        val head = decodeTeamPacketHead(bytes.size) { if (index >= bytes.size) null else bytes[index++] }

        head.shouldNotBeNull()
        bytes.size - index shouldBe 2
    }
})
