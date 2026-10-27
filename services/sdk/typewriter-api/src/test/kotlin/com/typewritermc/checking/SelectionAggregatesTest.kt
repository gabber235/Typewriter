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

    test("a complete selection answers every aggregate from its matches") {
        val values = partialSelection(3, -1, 5)

        listOf(
            values.all {
                Availability.Available(it > 0)
            },
            values.any {
                Availability.Available(it > 0)
            },
            values.sum {
                Availability.Available(it.toBigInteger())
            },
            values.minimum {
                Availability.Available(
                    it.toBigInteger(),
                )
            },
            values.maximum { Availability.Available(it.toBigInteger()) },
        ) shouldBe
            listOf(
                Availability.Available(false),
                Availability.Available(true),
                Availability.Available(BigInteger.valueOf(7)),
                Availability.Available(BigInteger.valueOf(-1)),
                Availability.Available(BigInteger.valueOf(5)),
            )
    }

    test("an empty complete selection gives the identity of each aggregate") {
        val none = partialSelection()

        listOf(
            none.all { Availability.Available(it > 0) },
            none.any { Availability.Available(it > 0) },
            none.sum { Availability.Available(it.toBigInteger()) },
            none.minimum { Availability.Available(it.toBigInteger()) },
            none.maximum { Availability.Available(it.toBigInteger()) },
            none.singleOrNone(),
        ) shouldBe
            listOf(
                Availability.Available(true),
                Availability.Available(false),
                Availability.Available(BigInteger.ZERO),
                Availability.Available(null),
                Availability.Available(null),
                Availability.Available(null),
            )
    }

    test("any and all answer early from a known match while other candidates are undecided") {
        val pending = partialSelection(3, -1, undecidedAt = missing)

        pending.any { Availability.Available(it > 0) } shouldBe Availability.Available(true)
        pending.all { Availability.Available(it > 0) } shouldBe Availability.Available(false)
    }

    test("exact aggregates stay unavailable while a candidate is undecided") {
        val pending = partialSelection(3, undecidedAt = missing)

        listOf(
            pending.sum { Availability.Available(it.toBigInteger()) },
            pending.minimum { Availability.Available(it.toBigInteger()) },
            pending.maximum { Availability.Available(it.toBigInteger()) },
            pending.singleOrNone(),
            pending.all { Availability.Available(it > 0) },
        ) shouldBe
            List(5) { Availability.Unavailable(listOf(missing)) }
    }

    test("an interrupted inspection stays unavailable without a missing input") {
        partialSelection(3, interrupted = true).sum { Availability.Available(it.toBigInteger()) } shouldBe
            Availability.Unavailable(emptyList())
    }

    test("single or none fails once two values match, even while others are undecided") {
        val failed = partialSelection(1, 2, undecidedAt = missing).singleOrNone() as Availability.Failed

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
