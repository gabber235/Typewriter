package com.typewritermc.configuration

import com.typewritermc.expression.Expr
import com.typewritermc.expression.ExpressionFactory
import com.typewritermc.expression.MayBeMissing
import com.typewritermc.expression.MissingPolicy
import com.typewritermc.types.Ref
import com.typewritermc.types.Resource
import kotlin.reflect.KClass

object GenericValueExpressionsFactory : ExpressionFactory<GenericValueExpressions<*>> {
    @Suppress("UNCHECKED_CAST")
    override val scope = GenericValueExpressions::class as KClass<GenericValueExpressions<*>>

    override fun create(value: Expr<*, out MissingPolicy>): GenericValueExpressions<*> =
        object : GenericValueExpressions<Any?> {
            override val value = Expr<Any?, MayBeMissing> { environment -> value.lower(environment) }
        }
}

object TextExpressionsFactory : ExpressionFactory<TextExpressions> {
    override val scope = TextExpressions::class

    override fun create(value: Expr<*, out MissingPolicy>): TextExpressions =
        object : TextExpressions {
            override val value = Expr<String, MayBeMissing> { environment -> value.lower(environment) }
        }
}

object NumberExpressionsFactory : ExpressionFactory<NumberExpressions<*>> {
    @Suppress("UNCHECKED_CAST")
    override val scope = NumberExpressions::class as KClass<NumberExpressions<*>>

    override fun create(value: Expr<*, out MissingPolicy>): NumberExpressions<*> =
        object : NumberExpressions<Any?> {
            override val value = Expr<Any?, MayBeMissing> { environment -> value.lower(environment) }
        }
}

object BytesExpressionsFactory : ExpressionFactory<BytesExpressions> {
    override val scope = BytesExpressions::class

    override fun create(value: Expr<*, out MissingPolicy>): BytesExpressions =
        object : BytesExpressions {
            override val value = Expr<List<Byte>, MayBeMissing> { environment -> value.lower(environment) }
        }
}

object BooleanExpressionsFactory : ExpressionFactory<BooleanExpressions> {
    override val scope = BooleanExpressions::class

    override fun create(value: Expr<*, out MissingPolicy>): BooleanExpressions =
        object : BooleanExpressions {
            override val value = Expr<Boolean, MayBeMissing> { environment -> value.lower(environment) }
        }
}

object EnumExpressionsFactory : ExpressionFactory<EnumExpressions<*>> {
    @Suppress("UNCHECKED_CAST")
    override val scope = EnumExpressions::class as KClass<EnumExpressions<*>>

    override fun create(value: Expr<*, out MissingPolicy>): EnumExpressions<*> =
        object : EnumExpressions<Any?> {
            override val value = Expr<Any?, MayBeMissing> { environment -> value.lower(environment) }
        }
}

object NullableExpressionsFactory : ExpressionFactory<NullableExpressions<*>> {
    @Suppress("UNCHECKED_CAST")
    override val scope = NullableExpressions::class as KClass<NullableExpressions<*>>

    override fun create(value: Expr<*, out MissingPolicy>): NullableExpressions<*> =
        object : NullableExpressions<Any?> {
            override val value = Expr<Any?, MayBeMissing> { environment -> value.lower(environment) }
        }
}

object ListExpressionsFactory : ExpressionFactory<ListExpressions<*>> {
    @Suppress("UNCHECKED_CAST")
    override val scope = ListExpressions::class as KClass<ListExpressions<*>>

    override fun create(value: Expr<*, out MissingPolicy>): ListExpressions<*> =
        object : ListExpressions<Any?> {
            override val value = Expr<List<Any?>, MayBeMissing> { environment -> value.lower(environment) }
        }
}

object SetExpressionsFactory : ExpressionFactory<SetExpressions<*>> {
    @Suppress("UNCHECKED_CAST")
    override val scope = SetExpressions::class as KClass<SetExpressions<*>>

    override fun create(value: Expr<*, out MissingPolicy>): SetExpressions<*> =
        object : SetExpressions<Any?> {
            override val value = Expr<Set<Any?>, MayBeMissing> { environment -> value.lower(environment) }
        }
}

object MapExpressionsFactory : ExpressionFactory<MapExpressions<*, *>> {
    @Suppress("UNCHECKED_CAST")
    override val scope = MapExpressions::class as KClass<MapExpressions<*, *>>

    override fun create(value: Expr<*, out MissingPolicy>): MapExpressions<*, *> =
        object : MapExpressions<Any?, Any?> {
            override val value = Expr<Map<Any?, Any?>, MayBeMissing> { environment -> value.lower(environment) }
        }
}

object ItemExpressionsFactory : ExpressionFactory<ItemExpressions<*>> {
    @Suppress("UNCHECKED_CAST")
    override val scope = ItemExpressions::class as KClass<ItemExpressions<*>>

    override fun create(value: Expr<*, out MissingPolicy>): ItemExpressions<*> =
        object : ItemExpressions<Any?> {
            override val value = Expr<Any?, MayBeMissing> { environment -> value.lower(environment) }
        }
}

object LinkExpressionsFactory : ExpressionFactory<LinkExpressions<*>> {
    @Suppress("UNCHECKED_CAST")
    override val scope = LinkExpressions::class as KClass<LinkExpressions<*>>

    override fun create(value: Expr<*, out MissingPolicy>): LinkExpressions<*> =
        object : LinkExpressions<Resource> {
            override val value = Expr<Ref<*, Resource>, MayBeMissing> { environment -> value.lower(environment) }
        }
}

object TimestampExpressionsFactory : ExpressionFactory<TimestampExpressions> {
    override val scope = TimestampExpressions::class

    override fun create(value: Expr<*, out MissingPolicy>): TimestampExpressions =
        object : TimestampExpressions {
            override val value = Expr<kotlin.time.Instant, MayBeMissing> { environment -> value.lower(environment) }
        }
}

object DurationExpressionsFactory : ExpressionFactory<DurationExpressions> {
    override val scope = DurationExpressions::class

    override fun create(value: Expr<*, out MissingPolicy>): DurationExpressions =
        object : DurationExpressions {
            override val value = Expr<kotlin.time.Duration, MayBeMissing> { environment -> value.lower(environment) }
        }
}

object ColorExpressionsFactory : ExpressionFactory<ColorExpressions> {
    override val scope = ColorExpressions::class

    override fun create(value: Expr<*, out MissingPolicy>): ColorExpressions =
        object : ColorExpressions {
            override val value = Expr<com.typewritermc.types.Color, MayBeMissing> { environment -> value.lower(environment) }
        }
}
