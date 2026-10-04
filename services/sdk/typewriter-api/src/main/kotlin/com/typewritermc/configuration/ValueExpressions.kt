package com.typewritermc.configuration

import com.typewritermc.expression.Expr
import com.typewritermc.expression.MayBeMissing
import com.typewritermc.types.Ref
import com.typewritermc.types.Resource
import kotlin.time.Duration
import kotlin.time.Instant

@Target(AnnotationTarget.PROPERTY_GETTER)
@Retention(AnnotationRetention.RUNTIME)
annotation class ExpressionField(
    val name: String,
)

interface GenericValueExpressions<T> {
    val value: Expr<T, MayBeMissing>
}

interface TextExpressions : GenericValueExpressions<String>

interface NumberExpressions<N> : GenericValueExpressions<N>

interface BytesExpressions : GenericValueExpressions<List<Byte>>

interface BooleanExpressions : GenericValueExpressions<Boolean>

interface EnumExpressions<E> : GenericValueExpressions<E>

interface NullableExpressions<V> : GenericValueExpressions<V?>

interface ListExpressions<T> : GenericValueExpressions<List<T>>

interface SetExpressions<T> : GenericValueExpressions<Set<T>>

interface MapExpressions<K, V> : GenericValueExpressions<Map<K, V>>

interface ItemExpressions<T> : GenericValueExpressions<T>

interface LinkExpressions<R : Resource> : GenericValueExpressions<Ref<*, R>>

interface TimestampExpressions : GenericValueExpressions<Instant>

interface DurationExpressions : GenericValueExpressions<Duration>

interface ColorExpressions : GenericValueExpressions<com.typewritermc.types.Color>
