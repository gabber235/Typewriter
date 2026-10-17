package com.typewritermc.configuration

import com.typewritermc.expression.Expr
import com.typewritermc.expression.MissingPolicy

typealias ListConfiguration<T, ItemScope, ItemExpressionScope> =
    Configuration<ListField<T, ItemScope, ItemExpressionScope>>
typealias SetConfiguration<T, ItemScope> = Configuration<SetField<T, ItemScope>>
typealias MapConfiguration<K, V, KeyScope, ValueScope> = Configuration<MapField<K, V, KeyScope, ValueScope>>

interface CollectionField<V, Expressions> : Field<V, Expressions> {
    fun nonEmpty()

    fun minimumItems(value: Int)

    fun maximumItems(value: Int)

    fun itemsBetween(
        minimum: Int,
        maximum: Int,
    )
}

interface ListField<T, ItemScope, ItemExpressionScope> : CollectionField<List<T>, ListExpressions<T>> {
    fun items(configure: Configuration<ItemScope>)

    fun unique()

    fun uniqueBy(key: ItemExpressionScope.() -> Expr<*, MissingPolicy>)
}

interface SetField<T, ItemScope> : CollectionField<Set<T>, SetExpressions<T>> {
    fun items(configure: Configuration<ItemScope>)
}

interface MapField<K, V, KeyScope, ValueScope> : CollectionField<Map<K, V>, MapExpressions<K, V>> {
    fun keys(configure: Configuration<KeyScope>)

    fun values(configure: Configuration<ValueScope>)
}
