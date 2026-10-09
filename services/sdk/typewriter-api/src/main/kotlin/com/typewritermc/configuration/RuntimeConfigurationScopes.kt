package com.typewritermc.configuration

import com.typewritermc.discovery.checkedGeneratedScope
import com.typewritermc.expression.Expr
import com.typewritermc.expression.ExpressionFactory
import com.typewritermc.expression.MissingPolicy
import com.typewritermc.types.Ref
import com.typewritermc.types.Resource
import java.math.BigDecimal
import kotlin.reflect.KClass
import kotlin.time.Duration
import kotlin.time.Instant

private class RuntimeField<V, E>(
    private val binding: RuntimeConfigurationBinding,
) : Field<V, E> {
    override fun rule(predicate: ConfigurationPredicate<E>): RuleDeclaration = binding.rule(predicate)

    override fun check(predicate: (V) -> Boolean): RuleDeclaration = binding.check(predicate)

    override fun oneOf(values: Iterable<V>) = binding.helper("one_of", values.toList(), "Value must be one of the declared choices")
}

private class RuntimeGeneric<T>(
    private val binding: RuntimeConfigurationBinding,
) : GenericValueConfigurationScope<T>,
    Field<T, GenericValueExpressions<T>> by RuntimeField(binding) {
    override fun whenText(configure: TextConfiguration) = binding.whenText(configure)
}

private class RuntimeText(
    private val binding: RuntimeConfigurationBinding,
) : Text,
    Field<String, TextExpressions> by RuntimeField(binding) {
    override fun nonEmpty() = binding.helper("nonEmpty", listOf())

    override fun nonBlank() = binding.helper("nonBlank", listOf())

    override fun minimumLength(value: Int) = binding.helper("minimumLength", listOf(value))

    override fun maximumLength(value: Int) = binding.helper("maximumLength", listOf(value))

    override fun lengthBetween(
        minimum: Int,
        maximum: Int,
    ) = binding.helper("lengthBetween", listOf(minimum, maximum))

    override fun minimumLines(value: Int) = binding.helper("minimumLines", listOf(value))

    override fun maximumLines(value: Int) = binding.helper("maximumLines", listOf(value))

    override fun singleLine() = binding.helper("singleLine", listOf())

    override fun regex(pattern: String) = binding.helper("regex", listOf(pattern))

    override fun startsWith(prefix: String) = binding.helper("startsWith", listOf(prefix))

    override fun endsWith(suffix: String) = binding.helper("endsWith", listOf(suffix))
}

private class RuntimeNumber<N>(
    private val binding: RuntimeConfigurationBinding,
) : Number<N>,
    Field<N, NumberExpressions<N>> by RuntimeField(binding) {
    override fun minimum(
        value: N,
        inclusive: Boolean,
    ) = binding.helper("minimum", listOf(value, inclusive))

    override fun maximum(
        value: N,
        inclusive: Boolean,
    ) = binding.helper("maximum", listOf(value, inclusive))

    override fun between(
        minimum: N,
        maximum: N,
    ) = binding.helper("between", listOf(minimum, maximum))

    override fun positive() = binding.helper("positive", listOf())

    override fun nonNegative() = binding.helper("nonNegative", listOf())
}

private class RuntimeInteger<N>(
    private val binding: RuntimeConfigurationBinding,
) : Integer<N>,
    Number<N> by RuntimeNumber(binding) {
    override fun multipleOf(value: N) = binding.helper("multipleOf", listOf(value))
}

private class RuntimeReal<N>(
    private val binding: RuntimeConfigurationBinding,
) : Real<N>,
    Number<N> by RuntimeNumber(binding)

private class RuntimeDecimal(
    private val binding: RuntimeConfigurationBinding,
) : Decimal,
    Number<BigDecimal> by RuntimeNumber(binding) {
    override fun multipleOf(value: BigDecimal) = binding.helper("multipleOf", listOf(value))

    override fun maximumScale(value: Int) = binding.helper("maximumScale", listOf(value))
}

private class RuntimeBytes(
    private val binding: RuntimeConfigurationBinding,
) : Bytes,
    Field<List<Byte>, BytesExpressions> by RuntimeField(binding) {
    override fun minimumLength(value: Int) = binding.helper("minimumLength", listOf(value))

    override fun maximumLength(value: Int) = binding.helper("maximumLength", listOf(value))
}

private class RuntimeBoolean(
    private val binding: RuntimeConfigurationBinding,
) : BooleanField,
    Field<Boolean, BooleanExpressions> by RuntimeField(binding)

private class RuntimeEnum<E>(
    private val binding: RuntimeConfigurationBinding,
) : EnumField<E>,
    Field<E, EnumExpressions<E>> by RuntimeField(binding)

private class RuntimeRecord<V, E>(
    private val binding: RuntimeConfigurationBinding,
) : RecordField<V, E>,
    Field<V, E> by RuntimeField(binding)

private class RuntimeLink<R : Resource>(
    private val binding: RuntimeConfigurationBinding,
) : LinkField<R>,
    Field<Ref<*, R>, LinkExpressions<R>> by RuntimeField(binding)

private class RuntimeTimestamp(
    private val binding: RuntimeConfigurationBinding,
) : TimestampField,
    Field<Instant, TimestampExpressions> by RuntimeField(binding) {
    override fun notBefore(value: Instant) = binding.helper("notBefore", listOf(value))

    override fun notAfter(value: Instant) = binding.helper("notAfter", listOf(value))
}

private class RuntimeDuration(
    private val binding: RuntimeConfigurationBinding,
) : DurationField,
    Field<Duration, DurationExpressions> by RuntimeField(binding) {
    override fun minimum(value: Duration) = binding.helper("minimum", listOf(value))

    override fun maximum(value: Duration) = binding.helper("maximum", listOf(value))

    override fun nonNegative() = binding.helper("nonNegative", listOf())
}

private class RuntimeColor(
    private val binding: RuntimeConfigurationBinding,
) : ColorField,
    Field<com.typewritermc.types.Color, ColorExpressions> by RuntimeField(binding) {
    override fun opaque() = binding.helper("opaque", listOf())
}

private class RuntimeNullable<V, S>(
    private val binding: RuntimeConfigurationBinding,
) : NullableField<V, S>,
    Field<V?, NullableExpressions<V>> by RuntimeField(binding) {
    override fun notNull() = binding.helper("notNull", emptyList())

    override fun whenPresent(configure: Configuration<S>) = binding.nested(configure, FieldPatternSegment.Values, samePath = true)
}

private class RuntimeCollection<V, E>(
    private val binding: RuntimeConfigurationBinding,
) : CollectionField<V, E>,
    Field<V, E> by RuntimeField(binding) {
    override fun nonEmpty() = binding.helper("nonEmpty", emptyList())

    override fun minimumItems(value: Int) = binding.helper("minimumItems", listOf(value))

    override fun maximumItems(value: Int) = binding.helper("maximumItems", listOf(value))

    override fun itemsBetween(
        minimum: Int,
        maximum: Int,
    ) = binding.helper("itemsBetween", listOf(minimum, maximum))
}

private class RuntimeList<T, S, E>(
    private val binding: RuntimeConfigurationBinding,
) : ListField<T, S, E>,
    CollectionField<List<T>, ListExpressions<T>> by RuntimeCollection(binding) {
    override fun items(configure: Configuration<S>) = binding.nested(configure, FieldPatternSegment.Items)

    override fun unique() = binding.helper("unique", emptyList())

    override fun uniqueBy(key: E.() -> Expr<*, MissingPolicy>) = binding.uniqueBy(key)
}

private class RuntimeSet<T, S>(
    private val binding: RuntimeConfigurationBinding,
) : SetField<T, S>,
    CollectionField<Set<T>, SetExpressions<T>> by RuntimeCollection(binding) {
    override fun items(configure: Configuration<S>) = binding.nested(configure, FieldPatternSegment.Items)
}

private class RuntimeMap<K, V, KS, VS>(
    private val binding: RuntimeConfigurationBinding,
) : MapField<K, V, KS, VS>,
    CollectionField<Map<K, V>, MapExpressions<K, V>> by RuntimeCollection(binding) {
    override fun keys(configure: Configuration<KS>) = binding.nested(configure, FieldPatternSegment.Keys)

    override fun values(configure: Configuration<VS>) = binding.nested(configure, FieldPatternSegment.Values)
}

internal fun <S : Any> RuntimeConfigurationBinding.createScope(scope: KClass<S>): S {
    val value: Any =
        when (scope) {
            Field::class -> RuntimeField<Any?, Any>(this)
            GenericValueConfigurationScope::class -> RuntimeGeneric<Any?>(this)
            Text::class -> RuntimeText(this)
            Number::class -> RuntimeNumber<Any?>(this)
            Integer::class -> RuntimeInteger<Any?>(this)
            Real::class -> RuntimeReal<Any?>(this)
            Decimal::class -> RuntimeDecimal(this)
            Bytes::class -> RuntimeBytes(this)
            BooleanField::class -> RuntimeBoolean(this)
            EnumField::class -> RuntimeEnum<Any?>(this)
            RecordField::class -> RuntimeRecord<Any?, Any>(this)
            NullableField::class -> RuntimeNullable<Any?, Any>(this)
            LinkField::class -> RuntimeLink<Resource>(this)
            TimestampField::class -> RuntimeTimestamp(this)
            DurationField::class -> RuntimeDuration(this)
            ColorField::class -> RuntimeColor(this)
            CollectionField::class -> RuntimeCollection<Any?, Any>(this)
            ListField::class -> RuntimeList<Any?, Any, Any>(this)
            SetField::class -> RuntimeSet<Any?, Any>(this)
            MapField::class -> RuntimeMap<Any?, Any?, Any, Any>(this)
            else -> error("No typed configuration factory was registered for ${scope.qualifiedName}.")
        }
    return checkedGeneratedScope(scope, value)
}

internal fun configurationExpressions(scope: KClass<*>): ExpressionFactory<*> =
    when (scope) {
        Text::class -> TextExpressionsFactory
        Number::class -> NumberExpressionsFactory
        Integer::class -> NumberExpressionsFactory
        Real::class -> NumberExpressionsFactory
        Decimal::class -> NumberExpressionsFactory
        Bytes::class -> BytesExpressionsFactory
        BooleanField::class -> BooleanExpressionsFactory
        EnumField::class -> EnumExpressionsFactory
        NullableField::class -> NullableExpressionsFactory
        LinkField::class -> LinkExpressionsFactory
        TimestampField::class -> TimestampExpressionsFactory
        DurationField::class -> DurationExpressionsFactory
        ColorField::class -> ColorExpressionsFactory
        ListField::class -> ListExpressionsFactory
        SetField::class -> SetExpressionsFactory
        MapField::class -> MapExpressionsFactory
        else -> GenericValueExpressionsFactory
    }
