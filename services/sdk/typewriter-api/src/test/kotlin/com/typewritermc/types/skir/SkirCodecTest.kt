@file:OptIn(kotlin.time.ExperimentalTime::class)

package com.typewritermc.types.skir

import com.typewritermc.types.ConversionId
import com.typewritermc.types.DataMapEntry
import com.typewritermc.types.DataValue
import com.typewritermc.types.IntegerWidth
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeParameter
import com.typewritermc.types.TypeVariance
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import java.math.BigInteger
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.nanoseconds
import kotlin.time.Instant

val SkirCodecTest by testSuite {
    test("catalog converts to Skir and back without losing represented fields") {
        val catalog =
            TypeCatalog(
                listOf(
                    TypeDefinition(
                        id = ResolvedTypeRef(TypeId.Qualified("example", "Box"), revision = 2),
                        kind = NominalTypeKind.CONCRETE,
                        representation =
                            TypeExpression.Integer(
                                width = IntegerWidth.SIGNED_32,
                                minimum = BigInteger.ZERO,
                                maximum = BigInteger.TEN,
                                maximumInclusive = false,
                                multipleOf = BigInteger.TWO,
                            ),
                        parameters =
                            listOf(
                                TypeParameter(
                                    name = "T",
                                    upperBounds = listOf(TypeExpression.StringType(), TypeExpression.Any),
                                    variance = TypeVariance.COVARIANT,
                                ),
                            ),
                        displayName = "Box",
                        outgoingConversionIds = listOf(ConversionId("example", "box_to_string")),
                    ),
                ),
            )

        val wire = SkirTypeCodec.encode(catalog).successValue()

        SkirTypeCodec.decode(wire).successValue() shouldBe catalog
    }

    test("nested data values convert in both directions") {
        val value =
            DataValue.Record(
                mapOf(
                    "created" to DataValue.Timestamp(Instant.parse("2026-08-22T12:34:56.123456789Z")),
                    "delay" to DataValue.Duration(1500.milliseconds),
                    "items" to
                        DataValue.MapValue(
                            listOf(DataMapEntry(DataValue.StringValue("answer"), DataValue.Integer(BigInteger.valueOf(42)))),
                        ),
                ),
            )

        val wire = SkirDataValueCodec.encode(value).successValue()

        SkirDataValueCodec.decode(wire).successValue() shouldBe value
    }

    test("conversion reports Kotlin constraints missing from Skir") {
        val result = SkirTypeCodec.encode(TypeExpression.StringType(patterns = listOf("a", "b")))

        (result is SkirConversionResult.Failure) shouldBe true
    }

    test("duration conversion rejects precision Skir cannot preserve") {
        val result = SkirDataValueCodec.encode(DataValue.Duration(1.nanoseconds))

        (result is SkirConversionResult.Failure) shouldBe true
    }

    test("extension API converts values in both directions") {
        val value = DataValue.StringValue("hello")

        value
            .toSkir()
            .getOrThrow()
            .toTypewriter()
            .getOrThrow() shouldBe value
        TypeExpression.Any
            .toSkir()
            .getOrThrow()
            .toTypewriter()
            .getOrThrow() shouldBe TypeExpression.Any
    }
}

private fun <Value> SkirConversionResult<Value>.successValue(): Value = getOrThrow()
