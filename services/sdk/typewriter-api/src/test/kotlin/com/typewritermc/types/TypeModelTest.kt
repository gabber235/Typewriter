@file:OptIn(kotlinx.serialization.ExperimentalSerializationApi::class, kotlin.time.ExperimentalTime::class)

package com.typewritermc.types

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.shouldBe
import kotlinx.serialization.cbor.Cbor
import kotlinx.serialization.decodeFromByteArray
import kotlinx.serialization.encodeToByteArray
import java.math.BigInteger
import kotlin.time.Duration.Companion.seconds
import kotlin.time.Instant

val TypeModelTest by testSuite {
    test("CBOR preserves the complete portable type graph") {
        val graph =
            TypeGraph(
                root = TypeExpression.Named(StandardTypes.optionOf(TypeExpression.StringType(minimumLength = 1))),
                definitions =
                    StandardTypes.definitions +
                        TypeDefinition(
                            id = ResolvedTypeRef(TypeId.Qualified("example", "Event"), revision = 3),
                            kind = NominalTypeKind.CONCRETE,
                            representation =
                                TypeExpression.Record(
                                    listOf(
                                        TypeField("at", TypeExpression.Timestamp()),
                                        TypeField("wait", TypeExpression.Duration(), DataValue.Duration(5.seconds)),
                                        TypeField(
                                            "count",
                                            TypeExpression.Integer(
                                                IntegerWidth.SIGNED_64,
                                                minimum = BigInteger.ZERO,
                                            ),
                                        ),
                                    ),
                                ),
                        ),
            )

        val encoded = Cbor.Default.encodeToByteArray(graph)

        Cbor.Default.decodeFromByteArray<TypeGraph>(encoded) shouldBe graph
    }

    test("standard catalog contains nullable and logical platform types") {
        StandardTypes.definitions.map { it.id } shouldBe
            listOf(
                StandardTypes.option,
                StandardTypes.some,
                StandardTypes.none,
                StandardTypes.color,
                StandardTypes.dateTime,
                StandardTypes.duration,
            )
        StandardTypes.dateTime.id shouldBe TypeId.Qualified("kernel/v1", "DateTime")
    }

    test("declared identities require canonical UUID text") {
        DeclaredTypeId.parse("019d1c2a8f7b7cc18c2a4a7b2fd1e281").toString() shouldBe
            "019d1c2a8f7b7cc18c2a4a7b2fd1e281"

        shouldThrow<IllegalArgumentException> {
            DeclaredTypeId.parse("019d1c2a-8f7b-7cc1-8c2a-4a7b2fd1e281")
        }
    }

    test("model rejects contradictory collection constraints") {
        shouldThrow<IllegalArgumentException> {
            TypeExpression.ListType(TypeExpression.StringType(), minimumLength = 2, maximumLength = 1)
        }
    }

    test("Kotlin temporal values remain available to callers") {
        val timestamp = Instant.parse("2026-08-22T12:34:56.123456789Z")
        val value = DataValue.Timestamp(timestamp)

        value.value shouldBe timestamp
        DataValue.Duration(5.seconds).value shouldBe 5.seconds
    }

    test("Kotlin values convert through concise construction and extraction helpers") {
        42.toDataValue().integerOrNull shouldBe BigInteger.valueOf(42)
        true.toDataValue().booleanOrNull shouldBe true
        "hello".toDataValue().stringOrNull shouldBe "hello"
        5.seconds.toDataValue().durationOrNull shouldBe 5.seconds

        val record = mapOf("answer" to 42.toDataValue()).toRecordValue()

        record.requireField("answer").integerOrNull shouldBe BigInteger.valueOf(42)
        record["missing"].shouldBeNull()
    }

    test("option helpers preserve Some values and Kotlin null") {
        val type = TypeExpression.StringType()
        val some = "value".toDataValue().toOptionValue(type)
        val none = null.toOptionValue(type)

        some.unwrapOption()?.stringOrNull shouldBe "value"
        none.unwrapOption().shouldBeNull()
        type.optional shouldBe TypeExpression.Named(StandardTypes.optionOf(type))
    }
}
