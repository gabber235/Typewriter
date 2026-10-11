package com.typewritermc.configuration

import com.typewritermc.expression.Expr
import com.typewritermc.expression.MissingPolicy

typealias Configuration<Scope> = Scope.() -> Unit
typealias TextConfiguration = Configuration<Text>
typealias NumberConfiguration<N> = Configuration<Number<N>>
typealias ConfigurationPredicate<Expressions> = Expressions.() -> Expr<Boolean, MissingPolicy>

interface Field<V, Expressions> {
    fun rule(predicate: ConfigurationPredicate<Expressions>): RuleDeclaration

    fun check(predicate: (V) -> Boolean): RuleDeclaration

    fun oneOf(values: Iterable<V>)
}

interface GenericValueConfigurationScope<T> : Field<T, GenericValueExpressions<T>> {
    fun whenText(configure: TextConfiguration)
}

fun <V, Expressions> Field<V, Expressions>.oneOf(
    first: V,
    vararg remaining: V,
) {
    oneOf(listOf(first) + remaining)
}

interface RuleDeclaration {
    fun error(
        message: String,
        at: RelativeFieldPattern? = null,
    )
}

interface Text : Field<String, TextExpressions> {
    fun nonEmpty()

    fun nonBlank()

    fun minimumLength(value: Int)

    fun maximumLength(value: Int)

    fun lengthBetween(
        minimum: Int,
        maximum: Int,
    )

    fun minimumLines(value: Int)

    fun maximumLines(value: Int)

    fun singleLine()

    fun regex(pattern: String)

    fun startsWith(prefix: String)

    fun endsWith(suffix: String)
}

interface Number<N> : Field<N, NumberExpressions<N>> {
    fun minimum(
        value: N,
        inclusive: Boolean = true,
    )

    fun maximum(
        value: N,
        inclusive: Boolean = true,
    )

    fun between(
        minimum: N,
        maximum: N,
    )

    fun positive()

    fun nonNegative()
}
