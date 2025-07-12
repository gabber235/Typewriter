package com.typewritermc.engine.paper.serialization.serializer

import com.typewritermc.core.serialization.serializer
import kotlinx.serialization.KSerializer
import kotlinx.serialization.builtins.serializer

object IntRangeSerializer : KSerializer<ClosedRange<Int>> by serializer(
    "start", { start }, Int.serializer(),
    "endInclusive", { endInclusive }, Int.serializer(),
    ::IntRange
)

object LongRangeSerializer : KSerializer<ClosedRange<Long>> by serializer(
    "start", { start }, Long.serializer(),
    "endInclusive", { endInclusive }, Long.serializer(),
    ::LongRange
)

object DoubleRangeSerializer : KSerializer<ClosedRange<Double>> by serializer(
    "start", { start }, Double.serializer(),
    "endInclusive", { endInclusive }, Double.serializer(),
    { s, e -> s..e }
)

object FloatRangeSerializer : KSerializer<ClosedRange<Float>> by serializer(
    "start", { start }, Float.serializer(),
    "endInclusive", { endInclusive }, Float.serializer(),
    { s, e -> s..e }
)