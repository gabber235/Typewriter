package com.typewritermc.formula.eval

import com.typewritermc.formula.NamedValue
import com.typewritermc.formula.RecordValue
import com.typewritermc.types.StandardTypes
import skirout.editor.v1.type_catalog.TypeUse
import java.math.BigDecimal

/*
 * Formula equality, as Kotlin's `==` sees the values a formula holds. It is structural, as RecordValue's own equality
 * is, except where Kotlin's types differ from their structure: every empty range equals every other, as Kotlin's
 * IntRange does, and two Decimals are equal when their values are, whatever their scale (`1.10 == 1.1`), at any
 * depth. RecordValue stays plainly structural, since the graph and stored values must tell
 * `1..0` from `5..2`: their `first`, `last` and text differ.
 */

/**
 * `==`: formula equality, except that two floating point numbers compare as Kotlin compares Float and Double values,
 * by IEEE 754, so -0.0 equals 0.0. Inside a record or a collection a number compares structurally, as in Kotlin.
 */
internal fun formulaEquals(
    left: Any?,
    right: Any?,
): Boolean =
    when {
        left is Double && right is Double -> left == right
        left is Float && right is Float -> left == right
        else -> same(left, right)
    }

/**
 * A map key or set item under formula equality, so a map a formula builds keeps one entry for keys Kotlin calls equal:
 * the first key, with the last value, as Kotlin's map literal does.
 */
internal class FormulaKey(
    val value: Any?,
) {
    override fun equals(other: Any?): Boolean = other is FormulaKey && same(value, other.value)

    override fun hashCode(): Int = formulaHash(value)
}

private fun same(
    left: Any?,
    right: Any?,
): Boolean =
    when {
        left is RecordValue && right is RecordValue -> sameRecord(left, right)
        left is NamedValue && right is NamedValue -> left.type == right.type && same(left.value, right.value)
        left is Collection<*> && right is Collection<*> -> sameCollection(left, right)
        left is Map<*, *> && right is Map<*, *> -> sameMap(left, right)
        else -> sameScalar(left, right)
    }

private fun sameScalar(
    left: Any?,
    right: Any?,
): Boolean = if (left is BigDecimal && right is BigDecimal) left.compareTo(right) == 0 else left == right

private fun sameCollection(
    left: Collection<*>,
    right: Collection<*>,
): Boolean =
    when {
        left is List<*> && right is List<*> -> left.size == right.size && left.indices.all { same(left[it], right[it]) }
        left is Set<*> && right is Set<*> -> left.mapTo(HashSet(), ::FormulaKey) == right.mapTo(HashSet(), ::FormulaKey)
        else -> left == right
    }

private fun sameRecord(
    left: RecordValue,
    right: RecordValue,
): Boolean =
    left.type == right.type &&
        (
            (left.isEmptyRange() && right.isEmptyRange()) ||
                (left.fields.keys == right.fields.keys && left.fields.all { (name, field) -> same(field, right.fields[name]) })
        )

private fun sameMap(
    left: Map<*, *>,
    right: Map<*, *>,
): Boolean {
    val mine = left.keyed()
    val theirs = right.keyed()
    return mine.size == theirs.size && mine.all { (key, item) -> key in theirs && same(item, theirs[key]) }
}

private fun Map<*, *>.keyed(): Map<FormulaKey, Any?> = entries.associate { (key, item) -> FormulaKey(key) to item }

private fun formulaHash(value: Any?): Int =
    when (value) {
        is RecordValue -> {
            if (value.isEmptyRange()) {
                IntRange.EMPTY.hashCode()
            } else {
                31 * value.type.hashCode() + value.fields.entries.sumOf { (name, field) -> name.hashCode() xor formulaHash(field) }
            }
        }

        is NamedValue -> {
            31 * value.type.hashCode() + formulaHash(value.value)
        }

        is List<*> -> {
            value.fold(1) { hash, item -> 31 * hash + formulaHash(item) }
        }

        is Set<*> -> {
            value.mapTo(HashSet(), ::FormulaKey).sumOf(FormulaKey::hashCode)
        }

        is Map<*, *> -> {
            value.keyed().entries.sumOf { (key, item) -> key.hashCode() xor formulaHash(item) }
        }

        is BigDecimal -> {
            value.stripTrailingZeros().hashCode()
        }

        else -> {
            value.hashCode()
        }
    }

private fun RecordValue.isEmptyRange(): Boolean =
    (type as? TypeUse.NamedWrapper)?.value?.definition == StandardTypes.intRange &&
        (fields["first"] as Int) > (fields["last"] as Int)
