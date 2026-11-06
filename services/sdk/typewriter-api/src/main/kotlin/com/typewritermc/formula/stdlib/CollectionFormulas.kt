package com.typewritermc.formula.stdlib

import com.typewritermc.formula.TypewriterFormulaName
import com.typewritermc.formula.TypewriterFormulaProvider

/**
 * List and map functions. Sums are checked like the arithmetic operators. Kotlin's own collection functions of these
 * names would hide or be shadowed by them, so each function has another Kotlin name.
 */
@TypewriterFormulaProvider
object CollectionFormulas {
    @TypewriterFormulaName("emptyList")
    fun <T> noItems(): List<T> = emptyList()

    @TypewriterFormulaName("size")
    val <T> List<T>.itemCount: Int get() = size

    @TypewriterFormulaName("isEmpty")
    fun <T> List<T>.hasNoItems(): Boolean = isEmpty()

    @TypewriterFormulaName("contains")
    fun <T> List<T>.includes(item: T): Boolean = item in this

    /** The item at [index], or null when the list has no such item. */
    @TypewriterFormulaName("get")
    fun <T> List<T>.itemAt(index: Int): T? = getOrNull(index)

    @TypewriterFormulaName("firstOrNull")
    fun <T> List<T>.firstItem(): T? = firstOrNull()

    @TypewriterFormulaName("map")
    fun <T, R> List<T>.mapped(transform: (T) -> R): List<R> = map(transform)

    @TypewriterFormulaName("filter")
    fun <T> List<T>.kept(predicate: (T) -> Boolean): List<T> = filter(predicate)

    @TypewriterFormulaName("count")
    fun <T> List<T>.counted(predicate: (T) -> Boolean): Int = count(predicate)

    @TypewriterFormulaName("any")
    fun <T> List<T>.anyItem(predicate: (T) -> Boolean): Boolean = any(predicate)

    @TypewriterFormulaName("all")
    fun <T> List<T>.everyItem(predicate: (T) -> Boolean): Boolean = all(predicate)

    @TypewriterFormulaName("sumOf")
    fun <T> List<T>.summed(selector: (T) -> Int): Int = fold(0) { total, item -> Math.addExact(total, selector(item)) }

    @TypewriterFormulaName("fold")
    fun <T, R> List<T>.folded(
        initial: R,
        operation: (total: R, item: T) -> R,
    ): R = fold(initial, operation)

    @TypewriterFormulaName("plus")
    fun <T> List<T>.joined(other: List<T>): List<T> = this + other

    /** The value at [key], or null when the map has none. */
    @TypewriterFormulaName("get")
    fun <K, V> Map<K, V>.valueAt(key: K): V? = this[key]

    @TypewriterFormulaName("size")
    val <K, V> Map<K, V>.entryCount: Int get() = size

    @TypewriterFormulaName("containsKey")
    fun <K, V> Map<K, V>.hasKey(key: K): Boolean = key in this

    @TypewriterFormulaName("keys")
    val <K, V> Map<K, V>.keyList: List<K> get() = keys.toList()

    @TypewriterFormulaName("values")
    val <K, V> Map<K, V>.valueList: List<V> get() = values.toList()
}
