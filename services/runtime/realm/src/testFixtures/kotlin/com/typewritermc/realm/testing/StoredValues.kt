package com.typewritermc.realm.testing

import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.complete
import com.typewritermc.authoring.payload
import com.typewritermc.authoring.with
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.completeTypeOf
import com.typewritermc.types.integer
import com.typewritermc.types.named
import com.typewritermc.types.use
import io.kotest.property.Arb
import io.kotest.property.PropTestConfig
import io.kotest.property.arbitrary.arbitrary
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeUse
import skirout.kernel.v1.resource_id.ResourceId
import kotlin.random.Random

/** A value stored by hand under a declared type it may or may not fit, as an older catalog or a hand edit leaves it. */
data class StoredCase(
    val declared: TypeUse,
    val value: DataValue,
)

/** Fixed seed and count, so every run replays the same stored values; change them only on purpose. */
val storedCaseConfig = PropTestConfig(seed = 5_310_872_204L, iterations = 60)

/**
 * Stored values over scalars, lists, sets and maps up to two levels deep. Scalars come from a domain of two or three,
 * so collections often repeat a value or key; a third of the values are built for a different type than declared.
 */
val storedCase: Arb<StoredCase> =
    arbitrary { source ->
        val random = source.random
        val declared = random.typeUse(depth = 2)
        val builtFor = if (random.nextInt(3) == 0) random.typeUse(depth = 2) else declared
        StoredCase(declared, random.valueOf(builtFor))
    }

private val keyUses = listOf(intUse, textUse)

/** The Boolean type, as a field or a Definition declares it. */
val booleanUse: TypeUse = ScalarKind.BOOLEAN.use
private val scalarUses = keyUses + booleanUse

private fun Random.typeUse(depth: Int): TypeUse =
    if (depth == 0 || nextInt(3) == 0) {
        scalarUses[nextInt(scalarUses.size)]
    } else {
        when (nextInt(3)) {
            0 -> listType(typeUse(depth - 1))
            1 -> setType(typeUse(depth - 1))
            else -> mapType(keyUses[nextInt(keyUses.size)], typeUse(depth - 1))
        }
    }

private fun Random.valueOf(type: TypeUse): DataValue {
    val named = type.named
    val items = { item: TypeUse -> List(nextInt(4)) { valueOf(item) } }
    return when {
        type == intUse -> {
            DataValue.integer(nextInt(3).toLong())
        }

        type == textUse -> {
            DataValue.StringValueWrapper(listOf("a", "b")[nextInt(2)])
        }

        type == booleanUse -> {
            DataValue.BooleanWrapper(nextBoolean())
        }

        named == null -> {
            error("No stored values for $type.")
        }

        named.definition == StandardTypes.list -> {
            named.arguments.single().let { listValue(it, *items(it).toTypedArray()) }
        }

        named.definition == StandardTypes.set -> {
            named.arguments.single().let { setValue(it, *items(it).toTypedArray()) }
        }

        else -> {
            val (key, value) = named.arguments
            mapValue(key, value, *List(nextInt(4)) { valueOf(key) to valueOf(value) }.toTypedArray())
        }
    }
}

/**
 * Saves [case] by hand as the value of a new Definition of its declared type and returns the Definition and what
 * complete() says of the stored record, read as publication reads it.
 */
suspend fun RealmFixture.storeByHand(
    name: String,
    case: StoredCase,
): Pair<ResourceId, CompletenessResult> {
    val held = commitDefinition(name, plainType(case.declared)).created()
    saveByHand(mapOf(held to record(held).with("value", plainVar(case.declared, case.value))))
    val record = record(held)
    val checked = checkNotNull(viewCatalog.completeTypeOf(held, record.configuration))
    return held to checked.complete(DataValue.named(checkNotNull(checked.use.named), DataValue.RecordWrapper(record.payload)))
}
