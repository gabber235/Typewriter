package com.typewritermc.realm.formula

import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.DraftExpectation
import com.typewritermc.formula.ContentReferences
import com.typewritermc.formula.FormulaFunction
import com.typewritermc.formula.VarDefinition
import com.typewritermc.formula.VarValueDefinition
import com.typewritermc.formula.check.FormulaEnvironment
import com.typewritermc.realm.authoring.RealmQuery
import com.typewritermc.realm.authoring.RealmReads
import com.typewritermc.realm.authoring.extensions
import com.typewritermc.realm.authoring.formulaTypeNames
import com.typewritermc.realm.authoring.tracked
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.resolve
import com.typewritermc.types.field
import com.typewritermc.types.named
import com.typewritermc.types.toResourceId
import com.typewritermc.types.toSkir
import com.typewritermc.types.unwrapNamed
import com.typewritermc.types.use
import skirout.editor.v1.catalog.DeclarationStatus
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId
import com.typewritermc.types.ResourceId as AuthorResourceId

/**
 * What the checker asks the realm about the formula at [at]. Built per query run, so every read lands on that query:
 * types through the reader's own view catalog, names through [NameAt], and what a name gives through [NamedAs].
 */
internal class RealmFormulaEnvironment(
    private val at: ValueLocation,
    private val reads: RealmReads,
) : FormulaEnvironment {
    private val checked: CheckedCatalog = with(reads) { tracked().viewCatalog.checked }
    private val functions: Map<String, List<FormulaFunction>> = with(reads) { extensions.functions }
    private val typeNames: Map<String, List<TypeUse>> = with(reads) { formulaTypeNames }

    override fun resolve(use: TypeUse): Resolution<CheckedType> = checked.resolve(use)

    override fun expand(use: TypeUse): TypeUse = checked.expand(use)

    override fun inScope(name: String): List<AuthorResourceId> = reads.read(NameAt(at, name)).map { it.toResourceId() }

    override fun functions(name: String): List<FormulaFunction> = functions[name].orEmpty()

    override fun reference(target: AuthorResourceId): TypeUse? = reads.read(NamedAs(target.toSkir()))

    override fun catalogTypeNamed(name: String): List<TypeUse> = typeNames[name].orEmpty()

    override fun typeValue(target: AuthorResourceId): TypeUse? = reads.read(TypeValueOf(target.toSkir()))

    override fun isMissing(id: TypeDefinitionId): Boolean = checked.definition(id) is DeclarationStatus.UnavailableWrapper
}

/** What naming [target] gives: the type of its exported field, a `Var<T, _>` reading as `T`, or a Ref to its type. Null when it is gone. */
internal data class NamedAs(
    val target: ResourceId,
) : RealmQuery<TypeUse?> {
    context(reads: RealmReads)
    override fun compute(): TypeUse? {
        val binding = (tracked().resourceBinding(target) as? Availability.Available)?.value ?: return null
        val actual = (binding.actual as? TypeSelection.CompleteWrapper)?.value ?: return null
        val export = reads.read(DynamicOf(target)).exports ?: return CONTENT_REFERENCE.use(listOf(actual.use))
        val resource = (binding.expected as? DraftExpectation.Complete)?.type ?: return null
        val held = resource.fieldType(export.path.segments) ?: return null
        val named = held.named
        return if (named?.definition == VarDefinition.id) named.arguments.firstOrNull() else held
    }
}

/** The type a resource's exported field holds plainly, or null when it holds a formula or no type. */
internal data class TypeValueOf(
    val target: ResourceId,
) : RealmQuery<TypeUse?> {
    context(reads: RealmReads)
    override fun compute(): TypeUse? {
        val export = reads.read(DynamicOf(target)).exports ?: return null
        val stored = (tracked().authoredValue(export) as? Availability.Available)?.value ?: return null
        val plain = (stored as? DataValue.NamedWrapper)?.takeIf { it.value.actualType.definition == VAR_VALUE }
        val value = plain?.let { (it.value.payload as? DataValue.RecordWrapper)?.field("value") } ?: stored
        return (value.unwrapNamed() as? DataValue.TypeUseWrapper)?.value
    }
}

private val VAR_VALUE: TypeDefinitionId = VarValueDefinition.id

/** The definition of `Ref<T>` as content writes it. */
private val CONTENT_REFERENCE: TypeDefinitionId = ContentReferences.Source.Definition.id

/** The declared type of the field at [segments] inside this record type, following record fields only. */
private fun CheckedType.fieldType(segments: List<PathSegment>): TypeUse? {
    var current: CheckedType = this
    var type: TypeUse? = null
    segments.forEachIndexed { index, segment ->
        val name = (segment as? PathSegment.FieldWrapper)?.value?.name ?: return null
        val record = current.schema.representation as? ResolvedRepresentation.RecordWrapper ?: return null
        type = record.value.fields
            .firstOrNull { it.key == name }
            ?.type ?: return null
        if (index < segments.lastIndex) current = (current.resolve(type!!) as? Resolution.Ready)?.value ?: return null
    }
    return type
}
