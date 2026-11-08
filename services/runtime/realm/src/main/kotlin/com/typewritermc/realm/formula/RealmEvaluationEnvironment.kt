package com.typewritermc.realm.formula

import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.DraftExpectation
import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.formula.Deferred
import com.typewritermc.formula.FormulaFailure
import com.typewritermc.formula.check.CatalogType
import com.typewritermc.formula.eval.CatalogEvaluationEnvironment
import com.typewritermc.formula.eval.FailedEvaluation
import com.typewritermc.formula.eval.refTo
import com.typewritermc.realm.authoring.CapturedAuthoringReads
import com.typewritermc.realm.authoring.RealmReads
import com.typewritermc.realm.authoring.formulaTypeNames
import com.typewritermc.realm.authoring.tracked
import com.typewritermc.types.ResourceId
import com.typewritermc.types.named
import com.typewritermc.types.toSkir
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation

/**
 * What evaluation asks the realm, built per query run, so every read lands on the running query: a field through its
 * stored value, a name through its export's evaluation, and a deferred value through Evaluate at its location.
 */
internal class RealmEvaluationEnvironment private constructor(
    private val reads: RealmReads,
    private val evaluating: ValueLocation?,
    private val reader: CapturedAuthoringReads,
) : CatalogEvaluationEnvironment(reader.viewCatalog.checked, reader.viewCatalog.nativeBindings) {
    /** The environment of the evaluation at [evaluating], or of a read outside any evaluation when it is null. */
    constructor(reads: RealmReads, evaluating: ValueLocation?) : this(reads, evaluating, with(reads) { tracked() })

    private val typeNames: Map<String, List<CatalogType>> by lazy { with(reads) { formulaTypeNames } }

    override fun evaluateDeferred(value: Deferred): Any? = with(reads) { value.value(evaluating) }

    /** The stored value of [field] on [resource] as the walk builds it: a Var or function typed field stays deferred. */
    override fun fieldOf(
        resource: ResourceId,
        field: String,
    ): Any? {
        val id = resource.toSkir()
        val at = ValueLocation.of(id).field(field)
        val binding = (reader.resourceBinding(id) as? Availability.Available)?.value ?: throw dependency(at)
        val type = (binding.expected as? DraftExpectation.Complete)?.type ?: throw dependency(at)
        val declared =
            type.schema.fields
                .singleOrNull { it.key == field }
                ?.type ?: throw dependency(at)
        val value =
            when (val stored = reader.authoredValue(at)) {
                is Availability.Available -> stored.value
                is Availability.Unavailable -> throw FailedEvaluation(FormulaFailure.Unfilled(at))
                is Availability.Failed -> throw dependency(at)
            }
        return value.toFormulaValue(declared, at, catalog)
    }

    override fun exported(resource: ResourceId): Any? {
        val at = reads.read(DynamicOf(resource.toSkir())).exports ?: return refTo(resource)
        return reads.read(Evaluate(at)).orThrowDependency(at, evaluating)
    }

    override fun typeName(id: TypeDefinitionId): String? =
        typeNames.entries
            .firstOrNull { (_, types) -> types.any { it.type.named?.definition == id } }
            ?.key

    /** The name a creator gave [id], or its id when it has none. */
    override fun resourceName(id: ResourceId): String {
        val at = ValueLocation.of(id.toSkir()).field("name")
        val stored = (reader.authoredValue(at) as? Availability.Available)?.value
        return (stored as? DataValue.StringValueWrapper)?.value ?: id.value
    }

    override fun ensureCurrent() = reads.ensureCurrent()

    private fun dependency(at: ValueLocation) = FailedEvaluation(FormulaFailure.Dependency(at.resource))
}
