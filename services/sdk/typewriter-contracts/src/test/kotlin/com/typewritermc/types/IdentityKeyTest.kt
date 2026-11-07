package com.typewritermc.types

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe

val IdentityKeyTest by testSuite {
    test("two links to one resource that differ only in their opposite share one identity") {
        linkTo("reward", "givenBy").identityKey() shouldBe linkTo("reward", null).identityKey()
    }

    test("links to different resources keep different identities") {
        linkTo("reward", "givenBy").identityKey() shouldNotBe linkTo("other", "givenBy").identityKey()
    }

    test("a set of such links compares by the same identity") {
        setValueOf(linkTo("reward", "first")).identityKey() shouldBe setValueOf(linkTo("reward", "second")).identityKey()
    }
}
