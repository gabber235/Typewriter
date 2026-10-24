@file:OptIn(ExperimentalTypeInference::class)

package com.typewritermc.expression.shortcuts

import com.typewritermc.expression.Expr
import com.typewritermc.expression.MayBeMissing
import com.typewritermc.expression.MissingPolicy
import com.typewritermc.expression.compare
import com.typewritermc.expression.contains
import com.typewritermc.expression.div
import com.typewritermc.expression.entryOf
import com.typewritermc.expression.eq
import com.typewritermc.expression.filter
import com.typewritermc.expression.flatten
import com.typewritermc.expression.fold
import com.typewritermc.expression.get
import com.typewritermc.expression.groupBy
import com.typewritermc.expression.indexOf
import com.typewritermc.expression.join
import com.typewritermc.expression.lastIndexOf
import com.typewritermc.expression.let
import com.typewritermc.expression.listExpr
import com.typewritermc.expression.literal
import com.typewritermc.expression.map
import com.typewritermc.expression.minus
import com.typewritermc.expression.not
import com.typewritermc.expression.numericLiteral
import com.typewritermc.expression.operations.SortDirection
import com.typewritermc.expression.plus
import com.typewritermc.expression.rangeExpr
import com.typewritermc.expression.size
import com.typewritermc.expression.slice
import com.typewritermc.expression.sortedBy
import com.typewritermc.expression.subtract
import com.typewritermc.expression.toDouble
import com.typewritermc.expression.toList
import com.typewritermc.expression.toMap
import com.typewritermc.expression.toSet
import com.typewritermc.expression.toText
import com.typewritermc.expression.zip
import java.math.BigDecimal
import java.math.BigInteger
import kotlin.experimental.ExperimentalTypeInference

/*
 * Collection shortcuts. A collection is a list, a set, or (through toList) a map's entries. A shortcut that runs a
 * lambda for every item lowers to the each primitives (collection.map, collection.filter, collection.group_by), which
 * evaluate every item before the result is known: any, all, none and find do not stop at the first decisive item.
 * Their results are MayBeMissing because an unfilled item makes the call missing at that item. Results keep the source
 * item identities unless the KDoc says otherwise.
 */

/** Whether this collection has no items. */
@JvmName("collectionIsEmpty")
fun <T, M : MissingPolicy> Expr<out Collection<T>, M>.isEmpty(): Expr<Boolean, M> = size eq literal(0).lift()

/** Whether this collection has an item. */
@JvmName("collectionIsNotEmpty")
fun <T, M : MissingPolicy> Expr<out Collection<T>, M>.isNotEmpty(): Expr<Boolean, M> = isEmpty().not()

/** Whether this map has no entries. */
@JvmName("mapIsEmpty")
fun <K, V, M : MissingPolicy> Expr<out Map<K, V>, M>.isEmpty(): Expr<Boolean, M> = size eq literal(0).lift()

/** Whether this map has an entry. */
@JvmName("mapIsNotEmpty")
fun <K, V, M : MissingPolicy> Expr<out Map<K, V>, M>.isNotEmpty(): Expr<Boolean, M> = isEmpty().not()

/** The number of items for which [predicate] holds. */
fun <T, M : MissingPolicy> Expr<out Collection<T>, M>.count(
    predicate: Expr<T, MayBeMissing>.() -> Expr<Boolean, out MissingPolicy>,
): Expr<Int, MayBeMissing> = filter(predicate).size

/** Whether [predicate] holds for an item. Every item evaluates. */
fun <T, M : MissingPolicy> Expr<out Collection<T>, M>.any(
    predicate: Expr<T, MayBeMissing>.() -> Expr<Boolean, out MissingPolicy>,
): Expr<Boolean, MayBeMissing> = filter(predicate).isNotEmpty()

/** Whether [predicate] holds for every item; true without items. Every item evaluates. */
fun <T, M : MissingPolicy> Expr<out Collection<T>, M>.all(
    predicate: Expr<T, MayBeMissing>.() -> Expr<Boolean, out MissingPolicy>,
): Expr<Boolean, MayBeMissing> = filter { predicate().not() }.isEmpty()

/** Whether [predicate] holds for no item. Every item evaluates. */
fun <T, M : MissingPolicy> Expr<out Collection<T>, M>.none(
    predicate: Expr<T, MayBeMissing>.() -> Expr<Boolean, out MissingPolicy>,
): Expr<Boolean, MayBeMissing> = filter(predicate).isEmpty()

/** The first item for which [predicate] holds, or null. Every item evaluates. */
fun <T, M : MissingPolicy> Expr<out Collection<T>, M>.find(
    predicate: Expr<T, MayBeMissing>.() -> Expr<Boolean, out MissingPolicy>,
): Expr<T?, MayBeMissing> = filter(predicate).firstOrNull()

/** The last item for which [predicate] holds, or null. Every item evaluates. */
fun <T, M : MissingPolicy> Expr<out Collection<T>, M>.findLast(
    predicate: Expr<T, MayBeMissing>.() -> Expr<Boolean, out MissingPolicy>,
): Expr<T?, MayBeMissing> = filter(predicate).lastOrNull()

/** The first item; fails with collection_key_absent when the list is empty. */
@JvmName("listFirst")
fun <T, M : MissingPolicy> Expr<out List<T>, M>.first(): Expr<T, MayBeMissing> = this[0]

/** The last item; fails with collection_key_absent when the list is empty. */
@JvmName("listLast")
fun <T, M : MissingPolicy> Expr<out List<T>, M>.last(): Expr<T, MayBeMissing> = let(this) { items -> items[items.size - 1] }

/** The first item, or null when the list is empty. */
@JvmName("listFirstOrNull")
fun <T, M : MissingPolicy> Expr<out List<T>, M>.firstOrNull(): Expr<T?, MayBeMissing> =
    let(this) { items -> choose(items.isEmpty(), nullLiteral(), items[0].orNull()) }

/** The last item, or null when the list is empty. */
@JvmName("listLastOrNull")
fun <T, M : MissingPolicy> Expr<out List<T>, M>.lastOrNull(): Expr<T?, MayBeMissing> =
    let(this) { items -> choose(items.isEmpty(), nullLiteral(), items[items.size - 1].orNull()) }

/** The only item, or null when the list does not have exactly one. */
@JvmName("listSingleOrNull")
fun <T, M : MissingPolicy> Expr<out List<T>, M>.singleOrNull(): Expr<T?, MayBeMissing> =
    let(this) { items -> choose(items.size eq literal(1), items[0].orNull(), nullLiteral()) }

/** The first [count] items, or every item when the list is shorter; fails with slice_range when negative. */
@JvmName("listTake")
fun <T, M : MissingPolicy> Expr<out List<T>, M>.take(count: Expr<Int, M>): Expr<List<T>, M> =
    shared(this) { items -> items.slice(literal(0).lift(), min(count, items.size)) }

/** The first [count] items, or every item when the list is shorter. */
@JvmName("listTakeRaw")
fun <T, M : MissingPolicy> Expr<out List<T>, M>.take(count: Int): Expr<List<T>, M> = take(literal(count).lift())

/** This list without its first [count] items; empty when it is shorter. */
@JvmName("listDrop")
fun <T, M : MissingPolicy> Expr<out List<T>, M>.drop(count: Expr<Int, M>): Expr<List<T>, M> =
    shared(this) { items -> shared(items.size) { size -> items.slice(min(count, size), size) } }

/** This list without its first [count] items; empty when it is shorter. */
@JvmName("listDropRaw")
fun <T, M : MissingPolicy> Expr<out List<T>, M>.drop(count: Int): Expr<List<T>, M> = drop(literal(count).lift())

/** The last [count] items, or every item when the list is shorter. */
@JvmName("listTakeLast")
fun <T, M : MissingPolicy> Expr<out List<T>, M>.takeLast(count: Expr<Int, M>): Expr<List<T>, M> =
    shared(this) { items -> shared(items.size) { size -> items.slice(size - min(count, size), size) } }

/** The last [count] items, or every item when the list is shorter. */
@JvmName("listTakeLastRaw")
fun <T, M : MissingPolicy> Expr<out List<T>, M>.takeLast(count: Int): Expr<List<T>, M> = takeLast(literal(count).lift())

/** This list without its last [count] items; empty when it is shorter. */
@JvmName("listDropLast")
fun <T, M : MissingPolicy> Expr<out List<T>, M>.dropLast(count: Expr<Int, M>): Expr<List<T>, M> =
    shared(this) { items -> shared(items.size) { size -> items.slice(literal(0).lift(), size - min(count, size)) } }

/** This list without its last [count] items; empty when it is shorter. */
@JvmName("listDropLastRaw")
fun <T, M : MissingPolicy> Expr<out List<T>, M>.dropLast(count: Int): Expr<List<T>, M> = dropLast(literal(count).lift())

/** The distinct items in order of first occurrence, with the identities of those first occurrences. */
fun <T, M : MissingPolicy> Expr<out Collection<T>, M>.distinct(): Expr<List<T>, M> = toSet().toList()

/** The first item of every distinct [selector] key, in order of first occurrence, with that item's identity. */
fun <T, K, M : MissingPolicy> Expr<out Collection<T>, M>.distinctBy(
    selector: Expr<T, MayBeMissing>.() -> Expr<K, out MissingPolicy>,
): Expr<List<T>, MayBeMissing> = groupBy(selector).map { entryValue[0] }

/** Whether no two items share a [selector] key. */
fun <T, K, M : MissingPolicy> Expr<out Collection<T>, M>.uniqueBy(
    selector: Expr<T, MayBeMissing>.() -> Expr<K, out MissingPolicy>,
): Expr<Boolean, MayBeMissing> = let(this) { items -> items.groupBy(selector).size eq items.size }

/** The items of every list [transform] returns, in order. Ids nest the source item and the inner item. */
fun <T, R, M : MissingPolicy> Expr<out Collection<T>, M>.flatMap(
    transform: Expr<T, MayBeMissing>.() -> Expr<List<R>, out MissingPolicy>,
): Expr<List<R>, MayBeMissing> = map(transform).flatten()

/** Folds the items left to right starting from the first; fails with collection_key_absent when empty. */
fun <T, M : MissingPolicy> Expr<out List<T>, M>.reduce(
    operation: (Expr<T, MayBeMissing>, Expr<T, MayBeMissing>) -> Expr<T, out MissingPolicy>,
): Expr<T, MayBeMissing> = let(this) { items -> items.drop(1).fold(items[0], operation) }

/** Folds the items left to right starting from the first, or null when the list is empty. */
fun <T, M : MissingPolicy> Expr<out List<T>, M>.reduceOrNull(
    operation: (Expr<T, MayBeMissing>, Expr<T, MayBeMissing>) -> Expr<T, out MissingPolicy>,
): Expr<T?, MayBeMissing> = let(this) { items -> choose(items.isEmpty(), nullLiteral(), items.reduce(operation).orNull()) }

/** The sum of the numbers; zero when empty. */
@JvmName("sumOfInt")
fun <M : MissingPolicy> Expr<out Collection<Int>, M>.sum(): Expr<Int, MayBeMissing> =
    fold(numericLiteral(0)) { total, item -> total + item }

/** The sum of the numbers; zero when empty. */
@JvmName("sumOfLong")
fun <M : MissingPolicy> Expr<out Collection<Long>, M>.sum(): Expr<Long, MayBeMissing> =
    fold(numericLiteral(0L)) { total, item -> total + item }

/** The sum of the numbers; zero when empty. */
@JvmName("sumOfDouble")
fun <M : MissingPolicy> Expr<out Collection<Double>, M>.sum(): Expr<Double, MayBeMissing> =
    fold(numericLiteral(0.0)) { total, item -> total + item }

/** The sum of the numbers; zero when empty. */
@JvmName("sumOfBigInteger")
fun <M : MissingPolicy> Expr<out Collection<BigInteger>, M>.sum(): Expr<BigInteger, MayBeMissing> =
    fold(numericLiteral(BigInteger.ZERO)) { total, item -> total + item }

/** The sum of the numbers; zero when empty. */
@JvmName("sumOfBigDecimal")
fun <M : MissingPolicy> Expr<out Collection<BigDecimal>, M>.sum(): Expr<BigDecimal, MayBeMissing> =
    fold(numericLiteral(BigDecimal.ZERO)) { total, item -> total + item }

/** The sum of [selector] over the items; zero when empty. */
@OverloadResolutionByLambdaReturnType
@JvmName("sumOfIntSelector")
fun <T, M : MissingPolicy> Expr<out Collection<T>, M>.sumOf(
    selector: Expr<T, MayBeMissing>.() -> Expr<Int, out MissingPolicy>,
): Expr<Int, MayBeMissing> = map(selector).sum()

/** The sum of [selector] over the items; zero when empty. */
@OverloadResolutionByLambdaReturnType
@JvmName("sumOfLongSelector")
fun <T, M : MissingPolicy> Expr<out Collection<T>, M>.sumOf(
    selector: Expr<T, MayBeMissing>.() -> Expr<Long, out MissingPolicy>,
): Expr<Long, MayBeMissing> = map(selector).sum()

/** The sum of [selector] over the items; zero when empty. */
@OverloadResolutionByLambdaReturnType
@JvmName("sumOfDoubleSelector")
fun <T, M : MissingPolicy> Expr<out Collection<T>, M>.sumOf(
    selector: Expr<T, MayBeMissing>.() -> Expr<Double, out MissingPolicy>,
): Expr<Double, MayBeMissing> = map(selector).sum()

/** The sum of [selector] over the items; zero when empty. */
@OverloadResolutionByLambdaReturnType
@JvmName("sumOfBigIntegerSelector")
fun <T, M : MissingPolicy> Expr<out Collection<T>, M>.sumOf(
    selector: Expr<T, MayBeMissing>.() -> Expr<BigInteger, out MissingPolicy>,
): Expr<BigInteger, MayBeMissing> = map(selector).sum()

/** The sum of [selector] over the items; zero when empty. */
@OverloadResolutionByLambdaReturnType
@JvmName("sumOfBigDecimalSelector")
fun <T, M : MissingPolicy> Expr<out Collection<T>, M>.sumOf(
    selector: Expr<T, MayBeMissing>.() -> Expr<BigDecimal, out MissingPolicy>,
): Expr<BigDecimal, MayBeMissing> = map(selector).sum()

/** The arithmetic mean; fails with non_finite_number when empty. */
@JvmName("averageOfDouble")
fun <M : MissingPolicy> Expr<out Collection<Double>, M>.average(): Expr<Double, MayBeMissing> =
    let(this) { items -> items.sum() / items.size.toDouble() }

/**
 * The canonical text (value.to_text) of every item, or [transform]'s text, joined with [separator] between them and
 * wrapped in [prefix] and [postfix].
 */
fun <T, M : MissingPolicy> Expr<out Collection<T>, M>.joinToString(
    separator: String = ", ",
    prefix: String = "",
    postfix: String = "",
    transform: (Expr<T, MayBeMissing>.() -> Expr<String, out MissingPolicy>)? = null,
): Expr<String, MayBeMissing> {
    val joined = map(transform ?: { toText() }).join(separator)
    return concat(literal(prefix), joined, literal(postfix))
}

/** The items in lists of [size], the last one possibly shorter. Ids are positional. */
fun <T, M : MissingPolicy> Expr<out List<T>, M>.chunked(size: Int): Expr<List<List<T>>, MayBeMissing> {
    require(size > 0) { "A chunk holds at least one item." }
    return let(this) { items ->
        rangeExpr(literal(0), items.size, literal(size)).map { items.slice(this, min(this + size, items.size)) }
    }
}

/**
 * The windows of [size] items starting every [step] items. Without [partialWindows] only full windows appear; with it
 * the windows near the end may be shorter. Ids are positional.
 */
fun <T, M : MissingPolicy> Expr<out List<T>, M>.windowed(
    size: Int,
    step: Int = 1,
    partialWindows: Boolean = false,
): Expr<List<List<T>>, MayBeMissing> {
    require(size > 0 && step > 0) { "A window and its step hold at least one item." }
    return let(this) { items ->
        if (partialWindows) {
            rangeExpr(literal(0), items.size, literal(step)).map { items.slice(this, min(this + size, items.size)) }
        } else {
            rangeExpr(literal(0), items.size - (size - 1), literal(step)).map { items.slice(this, this + size) }
        }
    }
}

/** Entries of every item (key) and its index (value), with the item identities. */
fun <T, M : MissingPolicy> Expr<out List<T>, M>.withIndex(): Expr<List<Map.Entry<T, Int>>, M> =
    shared(this) { items -> items zip rangeExpr(literal(0).lift(), items.size, literal(1).lift()) }

/** An entry of the items for which [predicate] holds (key) and the others (value). */
fun <T, M : MissingPolicy> Expr<out Collection<T>, M>.partition(
    predicate: Expr<T, MayBeMissing>.() -> Expr<Boolean, out MissingPolicy>,
): Expr<Map.Entry<List<T>, List<T>>, MayBeMissing> =
    let(this) { items -> entryOf(items.filter(predicate), items.filter { predicate().not() }) }

/** A map from the [keySelector] key of every item to the item; a later item replaces an equal key. */
fun <T, K, M : MissingPolicy> Expr<out Collection<T>, M>.associateBy(
    keySelector: Expr<T, MayBeMissing>.() -> Expr<K, out MissingPolicy>,
): Expr<Map<K, T>, MayBeMissing> = map { entryOf(keySelector(), this) }.toMap()

/** A map from every item to its [valueSelector] value; a later equal item replaces the value. */
fun <T, V, M : MissingPolicy> Expr<out Collection<T>, M>.associateWith(
    valueSelector: Expr<T, MayBeMissing>.() -> Expr<V, out MissingPolicy>,
): Expr<Map<T, V>, MayBeMissing> = map { entryOf(this, valueSelector()) }.toMap()

/** [transform] of the items at equal positions; the shorter list decides the length. Ids are this list's. */
fun <A, B, R, M : MissingPolicy> Expr<out List<A>, M>.zip(
    other: Expr<out List<B>, M>,
    transform: (Expr<A, MayBeMissing>, Expr<B, MayBeMissing>) -> Expr<R, out MissingPolicy>,
): Expr<List<R>, MayBeMissing> = (this zip other).map { transform(entryKey, entryValue) }

/** An entry of the keys (key) and the values (value) of these entries, in order. */
fun <A, B, M : MissingPolicy> Expr<out List<Map.Entry<A, B>>, M>.unzip(): Expr<Map.Entry<List<A>, List<B>>, MayBeMissing> =
    let(this) { entries -> entryOf(entries.map { entryKey }, entries.map { entryValue }) }

/** The first item with the smallest [selector] key; fails with collection_key_absent when empty. */
fun <T, O, M : MissingPolicy> Expr<out Collection<T>, M>.minBy(
    selector: Expr<T, MayBeMissing>.() -> Expr<O, out MissingPolicy>,
): Expr<T, MayBeMissing> = map { entryOf(selector(), this) }.firstExtremeBy(SMALLER).entryValue

/** The first item with the largest [selector] key; fails with collection_key_absent when empty. */
fun <T, O, M : MissingPolicy> Expr<out Collection<T>, M>.maxBy(
    selector: Expr<T, MayBeMissing>.() -> Expr<O, out MissingPolicy>,
): Expr<T, MayBeMissing> = map { entryOf(selector(), this) }.firstExtremeBy(LARGER).entryValue

/** The first item with the smallest [selector] key, or null when empty. */
fun <T, O, M : MissingPolicy> Expr<out Collection<T>, M>.minByOrNull(
    selector: Expr<T, MayBeMissing>.() -> Expr<O, out MissingPolicy>,
): Expr<T?, MayBeMissing> = let(this) { items -> choose(items.isEmpty(), nullLiteral(), items.minBy(selector).orNull()) }

/** The first item with the largest [selector] key, or null when empty. */
fun <T, O, M : MissingPolicy> Expr<out Collection<T>, M>.maxByOrNull(
    selector: Expr<T, MayBeMissing>.() -> Expr<O, out MissingPolicy>,
): Expr<T?, MayBeMissing> = let(this) { items -> choose(items.isEmpty(), nullLiteral(), items.maxBy(selector).orNull()) }

/** The smallest [selector] value; fails with collection_key_absent when empty. */
fun <T, O, M : MissingPolicy> Expr<out Collection<T>, M>.minOf(
    selector: Expr<T, MayBeMissing>.() -> Expr<O, out MissingPolicy>,
): Expr<O, MayBeMissing> = map(selector).firstExtreme(SMALLER)

/** The largest [selector] value; fails with collection_key_absent when empty. */
fun <T, O, M : MissingPolicy> Expr<out Collection<T>, M>.maxOf(
    selector: Expr<T, MayBeMissing>.() -> Expr<O, out MissingPolicy>,
): Expr<O, MayBeMissing> = map(selector).firstExtreme(LARGER)

/**
 * The first item that compares [direction] (value.compare: -1 smaller, 1 larger) to every earlier one, found in one
 * fold; fails with collection_key_absent when the list is empty.
 */
private fun <O> Expr<out List<O>, MayBeMissing>.firstExtreme(direction: Int): Expr<O, MayBeMissing> =
    reduce { best, next -> choose(next.compare(best) eq literal(direction).lift(), next, best) }

/** The first entry whose key compares [direction] to every earlier key, as [firstExtreme] does for items. */
private fun <K, V> Expr<out List<Map.Entry<K, V>>, MayBeMissing>.firstExtremeBy(direction: Int): Expr<Map.Entry<K, V>, MayBeMissing> =
    reduce { best, next -> choose(next.entryKey.compare(best.entryKey) eq literal(direction).lift(), next, best) }

private const val SMALLER = -1
private const val LARGER = 1

/** The items in ascending order; equal items keep their order. */
fun <T, M : MissingPolicy> Expr<out Collection<T>, M>.sorted(): Expr<List<T>, MayBeMissing> = sortedBy { this }

/** The items in descending order; equal items keep their order. */
fun <T, M : MissingPolicy> Expr<out Collection<T>, M>.sortedDescending(): Expr<List<T>, MayBeMissing> =
    sortedBy(SortDirection.Descending) { this }

/** This list followed by [element]. Ids are prefixed with the argument position. */
fun <T, M : MissingPolicy> Expr<out List<T>, M>.append(element: Expr<T, M>): Expr<List<T>, M> = this + listExpr(element)

/** [element] followed by this list. Ids are prefixed with the argument position. */
fun <T, M : MissingPolicy> Expr<out List<T>, M>.prepend(element: Expr<T, M>): Expr<List<T>, M> = listExpr(element) + this

/** The items that [elements] does not contain, in order; like Kotlin's minus, duplicates of kept items stay. */
@JvmName("collectionMinus")
operator fun <T, M : MissingPolicy> Expr<out Collection<T>, M>.minus(elements: Expr<out Collection<T>, M>): Expr<List<T>, MayBeMissing> =
    let(elements.toSet()) { removed -> filter { removed.contains(this).not() } }

/** The distinct items of this collection and then [other]. Ids are prefixed with the argument position. */
infix fun <T, M : MissingPolicy> Expr<out Collection<T>, M>.union(other: Expr<out Collection<T>, M>): Expr<Set<T>, M> =
    (toList() + other.toList()).toSet()

/** Whether this collection contains every item of [elements]. */
fun <T, M : MissingPolicy> Expr<out Collection<T>, M>.containsAll(elements: Expr<out Collection<T>, M>): Expr<Boolean, M> =
    (elements.toSet() subtract toSet()).isEmpty()

/** The index of the first item for which [predicate] holds, or -1. Every item evaluates. */
fun <T, M : MissingPolicy> Expr<out List<T>, M>.indexOfFirst(
    predicate: Expr<T, MayBeMissing>.() -> Expr<Boolean, out MissingPolicy>,
): Expr<Int, MayBeMissing> = map(predicate).indexOf(literal(true))

/** The index of the last item for which [predicate] holds, or -1. Every item evaluates. */
fun <T, M : MissingPolicy> Expr<out List<T>, M>.indexOfLast(
    predicate: Expr<T, MayBeMissing>.() -> Expr<Boolean, out MissingPolicy>,
): Expr<Int, MayBeMissing> = map(predicate).lastIndexOf(literal(true))

/** The distinct keys of this map, in order. */
@get:JvmName("mapKeySet")
val <K, V, M : MissingPolicy> Expr<out Map<K, V>, M>.keys: Expr<Set<K>, MayBeMissing> get() = map { entryKey }.toSet()

/** The values of this map, in order, with the entry identities. */
@get:JvmName("mapValueList")
val <K, V, M : MissingPolicy> Expr<out Map<K, V>, M>.values: Expr<List<V>, MayBeMissing> get() = map { entryValue }

/** The entries of this map, in order, with their identities. */
@get:JvmName("mapEntryList")
val <K, V, M : MissingPolicy> Expr<out Map<K, V>, M>.entries: Expr<List<Map.Entry<K, V>>, M> get() = toList()

/** This map with every key replaced by [transform] of its entry; a later equal key replaces the value. */
fun <K, V, R, M : MissingPolicy> Expr<out Map<K, V>, M>.mapKeys(
    transform: Expr<Map.Entry<K, V>, MayBeMissing>.() -> Expr<R, out MissingPolicy>,
): Expr<Map<R, V>, MayBeMissing> = map { entryOf(transform(), entryValue) }.toMap()

/** The entries whose key satisfies [predicate]. */
fun <K, V, M : MissingPolicy> Expr<out Map<K, V>, M>.filterKeys(
    predicate: Expr<K, MayBeMissing>.() -> Expr<Boolean, out MissingPolicy>,
): Expr<Map<K, V>, MayBeMissing> = filter { entryKey.predicate() }.toMap()

/** The entries whose value satisfies [predicate]. */
fun <K, V, M : MissingPolicy> Expr<out Map<K, V>, M>.filterValues(
    predicate: Expr<V, MayBeMissing>.() -> Expr<Boolean, out MissingPolicy>,
): Expr<Map<K, V>, MayBeMissing> = filter { entryValue.predicate() }.toMap()

/** The entries of this map and then [other]; an equal key of [other] replaces the value and keeps the position. */
@JvmName("mapPlus")
operator fun <K, V, M : MissingPolicy> Expr<out Map<K, V>, M>.plus(other: Expr<out Map<K, V>, M>): Expr<Map<K, V>, M> =
    (toList() + other.toList()).toMap()
