package com.typewritermc.visibility.packet

import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.shouldBe

private fun decode(vararg bytes: Int): Int? {
    val iterator = bytes.map { it.toByte() }.iterator()
    return decodeVarInt { if (iterator.hasNext()) iterator.next() else null }
}

class VarIntDecodingSpec : FunSpec({

    test("a single byte number reads as itself") {
        decode(0x00) shouldBe 0
        decode(0x01) shouldBe 1
        decode(0x7F) shouldBe 127
    }

    test("a continuation bit carries into the next byte") {
        decode(0x80, 0x01) shouldBe 128
        decode(0xDD, 0xC7, 0x01) shouldBe 25565
    }

    test("a full five byte number reads back as the negative it encodes") {
        decode(0xFF, 0xFF, 0xFF, 0xFF, 0x0F) shouldBe -1
        decode(0x80, 0x80, 0x80, 0x80, 0x08) shouldBe Int.MIN_VALUE
    }

    test("bytes that run out mid number give nothing rather than a wrong id") {
        decode().shouldBeNull()
        decode(0x80).shouldBeNull()
        decode(0xFF, 0xFF).shouldBeNull()
    }

    test("a number that never ends within five bytes gives nothing") {
        decode(0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01).shouldBeNull()
    }

    test("only the bytes of the number itself are consumed") {
        val bytes = listOf(0x80, 0x01, 0x2A).map { it.toByte() }
        val iterator = bytes.iterator()

        decodeVarInt { if (iterator.hasNext()) iterator.next() else null } shouldBe 128
        iterator.next() shouldBe 0x2A.toByte()
    }
})
