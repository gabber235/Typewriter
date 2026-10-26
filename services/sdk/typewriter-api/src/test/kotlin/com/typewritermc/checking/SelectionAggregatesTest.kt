package com.typewritermc.checking

import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.of
import com.typewritermc.expression.isNull
import com.typewritermc.expression.literal
import com.typewritermc.expression.operations.HostFailure
import com.typewritermc.expression.resourceValue
import com.typewritermc.library.Book
import com.typewritermc.library.BookDefinition
import com.typewritermc.library.BookDraftType
import com.typewritermc.types.ResourceId
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.ValueLocation
import java.math.BigInteger

val SelectionAggregatesTest by testSuite {
    val missing = ValueLocation.of(ResourceId("book:pending"))

    fun selection(
        vararg known: Int,
        undecided: Boolean = false,
        interrupted: Boolean = false,
    ) = PartialSelection(
        knownMatches = known.toList(),
        undecided = if (undecided) listOf(UndecidedCandidate(ResourceId("book:pending"), listOf(missing))) else emptyList(),
        completion = if (interrupted) InspectionCompletion.Interrupted("paused") else InspectionCompletion.Complete,
        failures = emptyList(),
    )

    fun available(value: Any?) = Availability.Available(value)

    val positive: (Int) -> Availability<Boolean> = { Availability.Available(it > 0) }
    val number: (Int) -> Availability<BigInteger> = { Availability.Available(it.toBigInteger()) }

    test("a complete selection answers every aggregate from its matches") {
        val values = selection(3, -1, 5)

        listOf(values.all(positive), values.any(positive), values.sum(number), values.minimum(number), values.maximum(number)) shouldBe
            listOf(
                available(false),
                available(true),
                available(BigInteger.valueOf(7)),
                available(BigInteger.valueOf(-1)),
                available(BigInteger.valueOf(5)),
            )
    }

    test("an empty complete selection gives the identity of each aggregate") {
        val none = selection()

        listOf(
            none.all(positive),
            none.any(positive),
            none.sum(number),
            none.minimum(number),
            none.maximum(number),
            none.singleOrNone(),
        ) shouldBe
            listOf(available(true), available(false), available(BigInteger.ZERO), available(null), available(null), available(null))
    }

    test("any and all answer early from a known match while other candidates are undecided") {
        val pending = selection(3, -1, undecided = true)

        pending.any(positive) shouldBe available(true)
        pending.all(positive) shouldBe available(false)
    }

    test("exact aggregates stay unavailable while a candidate is undecided") {
        val pending = selection(3, undecided = true)

        listOf(
            pending.sum(number),
            pending.minimum(number),
            pending.maximum(number),
            pending.singleOrNone(),
            pending.all(positive),
        ) shouldBe
            List(5) { Availability.Unavailable(listOf(missing)) }
    }

    test("an interrupted inspection stays unavailable without a missing input") {
        selection(3, interrupted = true).sum(number) shouldBe Availability.Unavailable(emptyList())
    }

    test("single or none fails once two values match, even while others are undecided") {
        val failed = selection(1, 2, undecided = true).singleOrNone() as Availability.Failed

        failed.diagnostic.failure shouldBe HostFailure.MultipleSelectionMatches
        failed.diagnostic.message shouldBe "More than one value matched."
    }

    test("a selection predicate that uses an operation outside the rule profile is refused when it is compiled") {
        shouldThrow<IllegalArgumentException> {
            BookDraftType.where {
                literal(ResourceId("book:other")).resourceValue<Book, com.typewritermc.expression.Handled>(BookDefinition.use.use).isNull()
            }
        }.message shouldBe "Selection predicates use the rule profile: outside_rule_profile."
    }
}
