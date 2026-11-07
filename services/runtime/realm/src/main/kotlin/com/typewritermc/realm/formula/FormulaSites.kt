package com.typewritermc.realm.formula

import com.typewritermc.authoring.field
import com.typewritermc.authoring.item
import com.typewritermc.authoring.mapKey
import com.typewritermc.authoring.mapValue
import com.typewritermc.authoring.of
import com.typewritermc.authoring.payload
import com.typewritermc.formula.TextSpan
import com.typewritermc.formula.VarComputedDefinition
import com.typewritermc.formula.VarDefinition
import com.typewritermc.formula.check.StoredFormula
import com.typewritermc.formula.check.StoredReference
import com.typewritermc.types.bigInteger
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.field
import com.typewritermc.types.items
import com.typewritermc.types.named
import com.typewritermc.types.payload
import com.typewritermc.types.rows
import com.typewritermc.types.toResourceId
import com.typewritermc.types.unwrapNamed
import com.typewritermc.types.use
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FunctionTypeUse
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId

/**
 * One formula a resource stores. [expected] is the function type it is the body of. [computedAtFunction] marks a
 * `Var.Computed` at a function typed Var, whose text would see no parameters, so it is reported and not checked.
 */
data class FormulaSite(
    val at: ValueLocation,
    val formula: StoredFormula,
    val expected: FunctionTypeUse,
    val computedAtFunction: Boolean = false,
)

/**
 * Every formula [record] stores on [owner], found by walking its value along its schema. A value under a type that is
 * gone holds no fields in the error type, so a formula inside it is not found until the type returns.
 */
internal fun AuthoringRecord.formulaSites(
    owner: ResourceId,
    catalog: CheckedCatalog,
): List<FormulaSite> {
    val selection = configuration as? TypeSelection.CompleteWrapper ?: return emptyList()
    val sites = mutableListOf<FormulaSite>()
    FormulaWalk(catalog, sites).walkNamed(DataValue.named(selection.value, DataValue.RecordWrapper(payload)), ValueLocation.of(owner))
    return sites
}

private class FormulaWalk(
    private val catalog: CheckedCatalog,
    private val sites: MutableList<FormulaSite>,
) {
    fun walk(
        value: DataValue,
        use: TypeUse,
        at: ValueLocation,
    ) {
        if (value == DataValue.UNFILLED || value == DataValue.NULL) return
        when (use) {
            is TypeUse.NullableWrapper -> walk(value, use.value.value, at)
            is TypeUse.FunctionWrapper -> value.storedFormula()?.let { sites += FormulaSite(at, it, use.value) }
            is TypeUse.NamedWrapper -> walkNamed(value, at, use.value)
            else -> Unit
        }
    }

    /**
     * Walks a named value. A computed Var is checked against the Var type its field declares now, read from the current
     * schema, so a changed alias or declaration rechecks it; the stored type is the fallback where nothing declares one.
     */
    fun walkNamed(
        value: DataValue,
        at: ValueLocation,
        declared: NamedTypeUse? = null,
    ) {
        val named = value as? DataValue.NamedWrapper ?: return
        val actual = named.value.actualType
        if (actual.definition == VarComputedDefinition.id) {
            computed(named, at, declared?.takeIf { it.definition == VarDefinition.id }?.arguments ?: actual.arguments)
            return
        }
        val checked = (catalog.resolve(actual.use) as? Resolution.Ready)?.value ?: return
        walkPayload(named.payload, checked.schema.representation, at)
    }

    private fun computed(
        named: DataValue.NamedWrapper,
        at: ValueLocation,
        arguments: List<TypeUse>,
    ) {
        val context = arguments.getOrNull(1) as? TypeUse.FunctionWrapper ?: return
        val formula = (named.payload as? DataValue.RecordWrapper)?.field("formula")?.storedFormula() ?: return
        val result = arguments.first()
        sites += FormulaSite(at.field("formula"), formula, context.value, computedAtFunction = result is TypeUse.FunctionWrapper)
    }

    private fun walkPayload(
        payload: DataValue,
        representation: ResolvedRepresentation,
        at: ValueLocation,
    ) {
        when (representation) {
            is ResolvedRepresentation.RecordWrapper -> {
                val record = payload as? DataValue.RecordWrapper ?: return
                representation.value.fields.forEach { field ->
                    record.field(field.key)?.let { walk(it, field.type, at.field(field.key)) }
                }
            }

            is ResolvedRepresentation.SequenceWrapper -> {
                val items = (payload as? DataValue.ListValueWrapper)?.items ?: (payload as? DataValue.SetValueWrapper)?.items
                items.orEmpty().forEach { walk(it.value, representation.value.item, at.item(it.id)) }
            }

            is ResolvedRepresentation.MappingWrapper -> {
                (payload as? DataValue.MapValueWrapper)?.rows.orEmpty().forEach { row ->
                    walk(row.key, representation.value.key, at.item(row.id).mapKey())
                    walk(row.value, representation.value.value, at.item(row.id).mapValue())
                }
            }

            else -> {
                Unit
            }
        }
    }
}
