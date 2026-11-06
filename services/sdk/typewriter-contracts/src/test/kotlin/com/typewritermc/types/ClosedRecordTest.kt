package com.typewritermc.types

import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.complete
import com.typewritermc.testkit.ready
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.collections.shouldNotContain
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.type_catalog.RecordForm

val ClosedRecordTest by testSuite {
    val door = id("door")
    val window = id("window")

    test("a closed union's concrete forms are its cases in declared order") {
        val catalog =
            catalog(
                closedRecord(door, listOf(door.member("SHUT"), door.member("OPEN"))),
                unitCase(door, "OPEN"),
                unitCase(door, "SHUT"),
            )

        catalog.concreteForms(catalog.ready(door.use())).map { it.use } shouldContainExactly
            listOf(door.member("SHUT").use(), door.member("OPEN").use())
    }

    test("a closed union's concrete forms reach through a closed case to its own cases") {
        val placement = id("placement")
        val cue = id("cue")
        val graph = id("graph")
        val catalog =
            catalog(
                closedRecord(placement, listOf(graph, cue)),
                bareRecord(graph, RecordForm.CONCRETE, placement),
                closedRecord(cue, listOf(cue.member("KEYFRAME"))).copy(parents = listOf(placement.namedTemplate())),
                unitCase(cue, "KEYFRAME"),
            )

        catalog.concreteForms(catalog.ready(placement.use())).map { it.use } shouldContainExactly
            listOf(graph.use(), cue.member("KEYFRAME").use())
    }

    test("a value of a case reads as its union") {
        val catalog = catalog(*enumDefinitions(door, "OPEN", "SHUT").toTypedArray())

        catalog.ready(door.use()).complete(caseValue(door, "OPEN")).shouldBeInstanceOf<CompletenessResult.Complete>()
    }

    test("a case of another union is refused") {
        val catalog = catalog(*(enumDefinitions(door, "OPEN") + enumDefinitions(window, "OPEN")).toTypedArray())

        val refused = catalog.ready(door.use()).complete(caseValue(window, "OPEN"))

        (refused as CompletenessResult.Invalid).problems.map { it.code } shouldContain "unreadable_actual_type"
    }

    test("a type naming a closed parent that does not list it is refused as a declaration") {
        val catalog = catalog(*enumDefinitions(door, "OPEN").toTypedArray(), unitCase(door, "STRAY"))

        catalog.unavailableCodes(door.member("STRAY")) shouldContain "not_a_listed_case"
        catalog.unavailableCodes(door.member("OPEN")) shouldBe emptyList()
    }

    test("a listed case that does not name its parent is refused as a declaration") {
        val catalog = catalog(closedRecord(door, listOf(door.member("ORPHAN"))), unitCase(door, "ORPHAN", parent = null))

        catalog.unavailableCodes(door) shouldContain "case_missing_parent"
    }

    test("anyone can add a subtype to an open record") {
        val shape = id("shape")
        val circle = id("circle")
        val catalog = catalog(bareRecord(shape, RecordForm.OPEN), bareRecord(circle, RecordForm.CONCRETE, shape))

        val forms = catalog.concreteForms(catalog.ready(shape.use())).map { it.use }

        forms shouldContain circle.use()
        forms shouldNotContain shape.use()
    }
}
