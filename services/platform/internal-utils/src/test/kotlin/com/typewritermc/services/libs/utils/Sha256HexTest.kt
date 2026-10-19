package com.typewritermc.services.libs.utils

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val Sha256HexTest by testSuite {
    test("formats SHA 256 digests as lowercase hexadecimal") {
        "abc".sha256Hex() shouldBe "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        byteArrayOf().sha256Hex() shouldBe "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
    }
}
