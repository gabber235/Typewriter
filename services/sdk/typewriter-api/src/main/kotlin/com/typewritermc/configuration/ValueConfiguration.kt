package com.typewritermc.configuration

import com.typewritermc.types.Ref
import com.typewritermc.types.Resource
import java.math.BigDecimal
import kotlin.time.Duration
import kotlin.time.Instant

typealias IntegerConfiguration<N> = Configuration<Integer<N>>
typealias RealConfiguration<N> = Configuration<Real<N>>
typealias DecimalConfiguration = Configuration<Decimal>
typealias BytesConfiguration = Configuration<Bytes>
typealias ColorConfiguration = Configuration<ColorField>

interface Integer<N> : Number<N> {
    fun multipleOf(value: N)
}

interface Real<N> : Number<N>

interface Decimal : Number<BigDecimal> {
    fun multipleOf(value: BigDecimal)

    fun maximumScale(value: Int)
}

interface Bytes : Field<List<Byte>, BytesExpressions> {
    fun minimumLength(value: Int)

    fun maximumLength(value: Int)
}

interface BooleanField : Field<Boolean, BooleanExpressions>

interface EnumField<E> : Field<E, EnumExpressions<E>>

interface RecordField<V, Expressions> : Field<V, Expressions>

interface NullableField<V, ValueScope> : Field<V?, NullableExpressions<V>> {
    fun notNull()

    fun whenPresent(configure: Configuration<ValueScope>)
}

interface LinkField<R : Resource> : Field<Ref<*, R>, LinkExpressions<R>>

interface TimestampField : Field<Instant, TimestampExpressions> {
    fun notBefore(value: Instant)

    fun notAfter(value: Instant)
}

interface DurationField : Field<Duration, DurationExpressions> {
    fun minimum(value: Duration)

    fun maximum(value: Duration)

    fun nonNegative()
}

interface ColorField : Field<com.typewritermc.types.Color, ColorExpressions> {
    fun opaque()
}
