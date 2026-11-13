package com.typewritermc.realm.formula

import com.typewritermc.authoring.ValueVisitor
import com.typewritermc.authoring.ValueWalk
import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.authoring.payload
import com.typewritermc.formula.VarComputedDefinition
import com.typewritermc.formula.VarValueDefinition
import com.typewritermc.formula.check.StoredFormula
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.completeTypeOf
import com.typewritermc.types.field
import com.typewritermc.types.named
import com.typewritermc.types.use
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FunctionTypeUse
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId

/**
 * One formula a resource stores. [expected] is the function type it is the body of, and [holder] is where the value it
 * gives sits: the Var that stores it, or the function typed field it is the body of. A [body] is the stored function
 * itself, so evaluating its holder gives a function without running it. [computedAtFunction] marks a `Var.Computed`
 * at a function typed Var, whose text would see no parameters, so it is reported and not checked.
 */
data class FormulaSite(
    val at: ValueLocation,
    val formula: StoredFormula,
    val expected: FunctionTypeUse,
    val holder: ValueLocation,
    val body: Boolean,
    val computedAtFunction: Boolean = false,
)

/**
 * Every formula [record] stores on [owner], found by the one schema walk. A value under a type that is gone holds no
 * fields in the error type, so a formula inside it is not found until the type returns.
 */
internal fun AuthoringRecord.formulaSites(
    owner: ResourceId,
    catalog: CheckedCatalog,
): List<FormulaSite> {
    val type = catalog.completeTypeOf(owner, configuration) ?: return emptyList()
    val use = checkNotNull(type.use.named)
    val sites = mutableListOf<FormulaSite>()
    val visitor = FormulaSitesVisitor(sites)
    val walk = ValueWalk(catalog, visitor)
    visitor.walk = walk
    walk.walk(DataValue.named(use, DataValue.RecordWrapper(payload)), type.use, ValueLocation.of(owner))
    return sites
}

/**
 * Collects formula locations: a Var or function typed position is where a formula may sit. A computed Var is checked
 * against the Var type its field declares now, so a changed alias or declaration rechecks it; a plain Var is walked
 * on into its value, which may hold formulas of its own. A value that does not fit is FitOf's to report.
 */
private class FormulaSitesVisitor(
    private val sites: MutableList<FormulaSite>,
) : ValueVisitor<Unit> {
    lateinit var walk: ValueWalk<Unit>

    override fun defers(use: TypeUse): Boolean = use.isVar() || use is TypeUse.FunctionWrapper

    override fun deferred(
        value: DataValue,
        use: TypeUse,
        at: ValueLocation,
    ) {
        if (use is TypeUse.FunctionWrapper) {
            value.storedFormula()?.let { sites += FormulaSite(at, it, use.value, holder = at, body = true) }
            return
        }
        val named = value as? DataValue.NamedWrapper ?: return
        val arguments = (use as TypeUse.NamedWrapper).value.arguments
        val held = arguments.firstOrNull() ?: return
        val payload = named.value.payload as? DataValue.RecordWrapper ?: return
        when (named.value.actualType.definition) {
            VarComputedDefinition.id -> computed(payload, held, arguments.getOrNull(1), at)
            VarValueDefinition.id -> plain(payload, held, at)
        }
    }

    /** A Var.Computed: its formula, which reads the Var's context. */
    private fun computed(
        payload: DataValue.RecordWrapper,
        held: TypeUse,
        context: TypeUse?,
        at: ValueLocation,
    ) {
        val reads = context as? TypeUse.FunctionWrapper ?: return
        val formula = payload.field("formula")?.storedFormula() ?: return
        sites +=
            FormulaSite(
                at.field("formula"),
                formula,
                reads.value,
                holder = at,
                body = false,
                computedAtFunction = held is TypeUse.FunctionWrapper,
            )
    }

    /** A Var.Value: a function body when the Var holds a function, else a value whose own formulas are walked. */
    private fun plain(
        payload: DataValue.RecordWrapper,
        held: TypeUse,
        at: ValueLocation,
    ) {
        val inner = payload.field("value") ?: return
        if (held is TypeUse.FunctionWrapper) {
            inner.storedFormula()?.let { sites += FormulaSite(at.field("value"), it, held.value, holder = at, body = true) }
        } else {
            walk.walk(inner, held, at.field("value"))
        }
    }

    override fun problem(
        at: ValueLocation,
        code: String,
        type: TypeDefinitionId?,
    ) = Unit

    override fun placeholder(at: ValueLocation) = Unit

    override fun unfinished(at: ValueLocation) = Unit

    override fun nullValue(at: ValueLocation) = Unit

    override fun scalar(
        value: DataValue,
        kind: ScalarKind,
        at: ValueLocation,
    ) = Unit

    override fun link(
        link: DataValue.LinkWrapper,
        at: ValueLocation,
    ) = Unit

    override fun sequence(
        kind: CollectionKind,
        items: List<Unit>,
        at: ValueLocation,
    ) = Unit

    override fun mapping(
        rows: List<Pair<Unit, Unit>>,
        at: ValueLocation,
    ) = Unit

    override fun record(
        actual: TypeUse,
        fields: Map<String, Unit>,
        at: ValueLocation,
    ) = Unit

    override fun named(
        actual: TypeUse,
        payload: Unit,
        at: ValueLocation,
    ) = Unit
}
