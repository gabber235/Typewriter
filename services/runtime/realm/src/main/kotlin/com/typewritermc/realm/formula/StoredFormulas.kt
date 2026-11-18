package com.typewritermc.realm.formula

import com.typewritermc.authoring.field
import com.typewritermc.authoring.item
import com.typewritermc.authoring.mapKey
import com.typewritermc.authoring.mapValue
import com.typewritermc.authoring.payload
import com.typewritermc.authoring.root
import com.typewritermc.formula.Formula
import com.typewritermc.formula.FormulaReference
import com.typewritermc.formula.TextSpan
import com.typewritermc.formula.check.StoredFormula
import com.typewritermc.formula.check.StoredReference
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.authoring.valueAt
import com.typewritermc.types.FORMULA_USE
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.Ref
import com.typewritermc.types.actualType
import com.typewritermc.types.bigInteger
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.field
import com.typewritermc.types.fields
import com.typewritermc.types.items
import com.typewritermc.types.named
import com.typewritermc.types.payload
import com.typewritermc.types.record
import com.typewritermc.types.rows
import com.typewritermc.types.toResourceId
import com.typewritermc.types.toSkir
import com.typewritermc.types.unwrapNamed
import com.typewritermc.types.use
import com.typewritermc.types.with
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldValue
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.MapRow
import skirout.editor.v1.type_catalog.RecordPayload
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId

/*
 * Formula values as the realm stores them. A formula is found by its stored type, not by the schema, so a formula
 * under a type that is gone is still under the realm's reference rules. An emptied reference stores its target
 * unfilled, as the clear policy of a delete leaves it.
 */

/** The formula a stored Formula value holds, or null when it is not one. */
internal fun DataValue.storedFormula(): StoredFormula? {
    val record = unwrapNamed() as? DataValue.RecordWrapper ?: return null
    val source = (record.field("source") as? DataValue.StringValueWrapper)?.value ?: return null
    return StoredFormula(source, referenceItems(record).mapNotNull { it.value.storedReference() })
}

private fun DataValue.storedReference(): StoredReference? {
    val reference = unwrapNamed() as? DataValue.RecordWrapper ?: return null
    val span = reference.field("at")?.unwrapNamed() as? DataValue.RecordWrapper ?: return null
    val start = (span.field("start") as? DataValue.IntegerWrapper)?.bigInteger?.toInt() ?: return null
    val end = (span.field("end") as? DataValue.IntegerWrapper)?.bigInteger?.toInt() ?: return null
    return StoredReference(TextSpan(start, end), reference.target()?.toResourceId())
}

private fun DataValue.RecordWrapper.target(): ResourceId? =
    (field("target")?.unwrapNamed() as? DataValue.LinkWrapper)?.value?.target?.resource

private fun referenceItems(formula: DataValue.RecordWrapper): List<ListItem> =
    (formula.field("references")?.unwrapNamed() as? DataValue.ListValueWrapper)?.items.orEmpty()

/** Whether this value is a stored Formula. */
private fun DataValue.isFormula(): Boolean = this is DataValue.NamedWrapper && actualType.definition == FORMULA_USE.definition

/** This formula value with its reference items replaced by what [change] gives for them. */
private fun DataValue.NamedWrapper.withReferenceItems(change: (List<ListItem>) -> List<ListItem>): DataValue {
    val record = payload as? DataValue.RecordWrapper ?: return this
    val references = record.field("references") ?: return this
    val list = references.unwrapNamed() as? DataValue.ListValueWrapper ?: return this
    val items = change(list.items)
    if (items == list.items) return this
    val changedList = DataValue.createListValue(items = items)
    val rewrapped = if (references is DataValue.NamedWrapper) DataValue.named(references.actualType, changedList) else changedList
    return DataValue.named(actualType, DataValue.RecordWrapper(record.value.with("references", rewrapped)))
}

/** This reference item with its target emptied. */
private fun ListItem.emptied(): ListItem {
    val named = value as? DataValue.NamedWrapper
    val record = (named?.payload ?: value) as? DataValue.RecordWrapper ?: return this
    val cleared = DataValue.RecordWrapper(record.value.with("target", DataValue.UNFILLED))
    return ListItem(id = id, value = named?.let { DataValue.named(it.actualType, cleared) } ?: cleared)
}

private fun ListItem.target(): ResourceId? = (value.unwrapNamed() as? DataValue.RecordWrapper)?.target()

/**
 * This record with the references the realm owns, after an edit that [saved] was the stored form of, or a new record
 * when [saved] is null. A formula whose source stayed keeps its saved references, with each whose target is in
 * [removed] emptied; one whose source changed loses them, for the commit to bind again. A new record keeps a
 * reference whose span lies in its text and whose target [exists], or that is already emptied. So whatever a client
 * sent for references never reaches storage unchecked.
 */
internal fun AuthoringRecord.withRealmReferences(
    saved: AuthoringRecord?,
    removed: Set<ResourceId>,
    exists: (ResourceId) -> Boolean,
): AuthoringRecord {
    val next =
        payload.mapFormulas(ValuePath.root) { at, formula ->
            val source = formula.storedFormula()?.source ?: return@mapFormulas formula
            if (saved == null) {
                return@mapFormulas formula.withReferenceItems { items ->
                    items.filter { item ->
                        val reference = item.value.storedReference() ?: return@filter false
                        val inText = reference.at.start >= 0 && reference.at.start < reference.at.end && reference.at.end <= source.length
                        val target = item.target()
                        inText && (target == null || exists(target))
                    }
                }
            }
            val before = saved.valueAt(at)?.takeIf { it.isFormula() } as? DataValue.NamedWrapper
            if (before != null && before.storedFormula()?.source == source) {
                before.withReferenceItems { items -> items.map { if (it.target() in removed) it.emptied() else it } }
            } else {
                formula.withReferenceItems { emptyList() }
            }
        }
    return if (next === payload) this else copy(fields = next.fields)
}

private fun RecordPayload.mapFormulas(
    at: ValuePath,
    replace: (ValuePath, DataValue.NamedWrapper) -> DataValue,
): RecordPayload {
    var changed = false
    val fields =
        fields.map { field ->
            val value = field.value.mapFormulas(at.field(field.name), replace)
            if (value !== field.value) changed = true
            FieldValue(name = field.name, value = value)
        }
    return if (changed) RecordPayload(fields = fields) else this
}

private fun DataValue.mapFormulas(
    at: ValuePath,
    replace: (ValuePath, DataValue.NamedWrapper) -> DataValue,
): DataValue =
    when (this) {
        is DataValue.NamedWrapper -> mapNamed(at, replace)
        is DataValue.RecordWrapper -> rebuilt(value.mapFormulas(at, replace).takeIf { it !== value }, DataValue::RecordWrapper)
        is DataValue.ListValueWrapper -> rebuilt(mapItems(items, at, replace)) { DataValue.createListValue(items = it) }
        is DataValue.SetValueWrapper -> rebuilt(mapItems(items, at, replace)) { DataValue.createSetValue(items = it) }
        is DataValue.MapValueWrapper -> rebuilt(mapRows(rows, at, replace)) { DataValue.createMapValue(rows = it) }
        else -> this
    }

/** This value, or what [build] makes of [changed] when there is a change. */
private inline fun <T : Any> DataValue.rebuilt(
    changed: T?,
    build: (T) -> DataValue,
): DataValue = if (changed == null) this else build(changed)

private fun DataValue.NamedWrapper.mapNamed(
    at: ValuePath,
    replace: (ValuePath, DataValue.NamedWrapper) -> DataValue,
): DataValue {
    if (isFormula()) return replace(at, this).let { if (it == this) this else it }
    val inner = payload.mapFormulas(at, replace)
    return if (inner === payload) this else DataValue.named(actualType, inner)
}

private fun mapRows(
    rows: List<MapRow>,
    at: ValuePath,
    replace: (ValuePath, DataValue.NamedWrapper) -> DataValue,
): List<MapRow>? {
    var changed = false
    val next =
        rows.map { row ->
            val key = row.key.mapFormulas(at.item(row.id).mapKey(), replace)
            val value = row.value.mapFormulas(at.item(row.id).mapValue(), replace)
            if (key !== row.key || value !== row.value) changed = true
            MapRow(id = row.id, key = key, value = value)
        }
    return if (changed) next else null
}

private fun mapItems(
    items: List<ListItem>,
    at: ValuePath,
    replace: (ValuePath, DataValue.NamedWrapper) -> DataValue,
): List<ListItem>? {
    var changed = false
    val next =
        items.map { item ->
            val value = item.value.mapFormulas(at.item(item.id), replace)
            if (value !== item.value) changed = true
            ListItem(id = item.id, value = value)
        }
    return if (changed) next else null
}

/**
 * This formula as [view] stores it. A filled reference is a link of the content references contract; an emptied one
 * keeps its span and stores its target unfilled. [holder] is any resource of [view], used only while encoding.
 */
internal fun StoredFormula.toDataValue(
    view: AuthoringView,
    holder: ResourceId,
): DataValue {
    val checked = (view.catalog.checked.resolve(FORMULA_USE.use) as Resolution.Ready).value

    @Suppress("UNCHECKED_CAST")
    val binding = view.catalog.nativeBindings.bind(checked) as NativeBinding<Formula>
    val encoded = binding.encode(Formula(source, references.map { FormulaReference(it.at, Ref(it.target ?: holder.toResourceId())) }))
    val emptied = references.mapIndexedNotNull { index, reference -> index.takeIf { reference.target == null } }.toSet()
    if (emptied.isEmpty()) return encoded
    return (encoded as DataValue.NamedWrapper).withReferenceItems { items ->
        items.mapIndexed { index, item -> if (index in emptied) item.emptied() else item }
    }
}
