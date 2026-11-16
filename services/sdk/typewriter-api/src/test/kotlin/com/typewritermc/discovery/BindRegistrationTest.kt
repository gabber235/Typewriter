package com.typewritermc.discovery

import com.typewritermc.testkit.origin
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val BindRegistrationTest by testSuite {
    test("a registered bind makes its parameter computed in the catalog editors and engines read") {
        val assembly = assembleBoard(binder(BOARD_ARTIFACT) { bind(boardParameter("V")) {} })

        assembly.checkedParameters() shouldBe listOf("T" to false, "V" to true)
        assembly.publishedParameters() shouldBe listOf("T" to false, "V" to true)
        assembly.dynamics.failures shouldBe emptyList()
    }

    test("a bind on a type another artifact declares is rejected at load and leaves the parameter chosen") {
        val assembly = assembleBoard(binder(OTHER_ARTIFACT) { bind(boardParameter("V")) {} })

        assembly.dynamics.failures.map { it.code } shouldBe listOf("bind_foreign_type")
        assembly.checkedParameters() shouldBe listOf("T" to false, "V" to false)
    }

    test("a bind for a parameter its type does not have is rejected at load") {
        val assembly = assembleBoard(binder(BOARD_ARTIFACT) { bind(boardParameter("W")) {} })

        assembly.dynamics.failures.map { it.code } shouldBe listOf("bind_unknown_parameter")
        assembly.checkedParameters() shouldBe listOf("T" to false, "V" to false)
    }

    test("two binds of one parameter are reported at load, and both stay so the parameter stays computed") {
        val second = origin("more board binds", artifact = "test:board")
        val assembly =
            assembleBoard(binder(BOARD_ARTIFACT) { bind(boardParameter("V")) {} }, binder(second) { bind(boardParameter("V")) {} })

        assembly.dynamics.failures.map { it.provider.origin to it.code } shouldBe
            listOf(BOARD_ARTIFACT to "duplicate_bind", second to "duplicate_bind")
        assembly.dynamics.binds.size shouldBe 2
        assembly.checkedParameters() shouldBe listOf("T" to false, "V" to true)
    }

    test("registration runs at load, so a provider whose register throws is known with the catalog") {
        val assembly = assembleBoard(binder(BOARD_ARTIFACT) { error("broken provider") })

        assembly.dynamics.failures.map { it.code } shouldBe listOf("dynamic_registration_failed")
        assembly.checkedParameters() shouldBe listOf("T" to false, "V" to false)
    }
}
