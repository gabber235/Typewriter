package com.typewritermc.expression.operations

import com.typewritermc.types.bytes
import com.typewritermc.types.duration
import com.typewritermc.types.floatScalar
import com.typewritermc.types.integer
import com.typewritermc.types.integerScalar
import com.typewritermc.types.scalarValue
import com.typewritermc.types.timestamp
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.withClue
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeUse
import java.math.BigInteger
import kotlin.time.Duration.Companion.seconds
import kotlin.time.Instant

val PortableScalarTextTest by testSuite {
    test("a scalar read from a stored value of every scalar kind displays as that stored value's text") {
        val stored =
            listOf(
                ScalarKind.UNIT to DataValue.UNIT,
                ScalarKind.BOOLEAN to DataValue.BooleanWrapper(true),
                ScalarKind.TEXT to DataValue.StringValueWrapper("hello"),
                ScalarKind.BYTES to DataValue.bytes(byteArrayOf(1, 2, -1)),
                integerScalar(IntegerWidth.SIGNED_EIGHT) to DataValue.integer(-8),
                integerScalar(IntegerWidth.SIGNED_SIXTEEN) to DataValue.integer(-16_000),
                integerScalar(IntegerWidth.SIGNED_THIRTY_TWO) to DataValue.integer(-2_000_000_000),
                integerScalar(IntegerWidth.SIGNED_SIXTY_FOUR) to DataValue.integer(Long.MIN_VALUE),
                integerScalar(IntegerWidth.UNSIGNED_EIGHT) to DataValue.integer(200),
                integerScalar(IntegerWidth.UNSIGNED_SIXTEEN) to DataValue.integer(60_000),
                integerScalar(IntegerWidth.UNSIGNED_THIRTY_TWO) to DataValue.integer(4_000_000_000),
                integerScalar(IntegerWidth.UNSIGNED_SIXTY_FOUR) to DataValue.integer(BigInteger("18446744073709551615")),
                floatScalar(FloatWidth.THIRTY_TWO) to DataValue.FloatWrapper(1.5),
                floatScalar(FloatWidth.SIXTY_FOUR) to DataValue.FloatWrapper(0.1),
                ScalarKind.DECIMAL to DataValue.DecimalWrapper("12.50"),
                ScalarKind.TIMESTAMP to DataValue.timestamp(Instant.fromEpochMilliseconds(1_700_000_000_000)),
                ScalarKind.DURATION to DataValue.duration(90.seconds),
                ScalarKind.TYPE to DataValue.TypeUseWrapper(TypeUse.ScalarWrapper(ScalarKind.TEXT)),
            )
        stored.forEach { (kind, value) ->
            withClue(kind) { portableScalarText(value.scalarValue(kind)) shouldBe PortableValueKernel.toText(value) }
        }
        portableScalarText(null) shouldBe "null"
    }
}
