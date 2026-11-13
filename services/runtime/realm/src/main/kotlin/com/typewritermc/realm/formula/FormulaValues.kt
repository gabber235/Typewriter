package com.typewritermc.realm.formula

import com.typewritermc.authoring.TypedPosition
import com.typewritermc.authoring.ValueVisitor
import com.typewritermc.authoring.ValueWalk
import com.typewritermc.authoring.typedAt
import com.typewritermc.formula.Deferred
import com.typewritermc.formula.FormulaFailure
import com.typewritermc.formula.NamedValue
import com.typewritermc.formula.RecordValue
import com.typewritermc.formula.VarDefinition
import com.typewritermc.formula.eval.Evaluation
import com.typewritermc.formula.eval.FailedEvaluation
import com.typewritermc.formula.eval.refTo
import com.typewritermc.formula.formulaForm
import com.typewritermc.realm.authoring.RealmReads
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.completeTypeOf
import com.typewritermc.types.scalarValue
import com.typewritermc.types.toResourceId
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId
import java.math.BigDecimal

/**
 * Builds evaluation values over the one schema walk. A value that does not fit its type stops the walk with
 * Dependency, since FitOf reports it at its source; an unfilled value stops it with Unfilled. A Var or function typed
 * position stays a [Deferred] until a formula uses it.
 */
internal object FormulaValueVisitor : ValueVisitor<Any?> {
    override fun problem(
        at: ValueLocation,
        code: String,
        type: TypeDefinitionId?,
    ): Nothing = throw FailedEvaluation(FormulaFailure.Dependency(at.resource))

    override fun placeholder(at: ValueLocation): Nothing = throw FailedEvaluation(FormulaFailure.Dependency(at.resource))

    override fun unfinished(at: ValueLocation): Nothing = throw FailedEvaluation(FormulaFailure.Unfilled(at))

    override fun nullValue(at: ValueLocation): Any? = null

    override fun scalar(
        value: DataValue,
        kind: ScalarKind,
        at: ValueLocation,
    ): Any? = value.scalarValue(kind).let { if (it is BigDecimal) it.formulaForm() else it }

    override fun link(
        link: DataValue.LinkWrapper,
        at: ValueLocation,
    ): Any =
        refTo(
            link.value.target.resource
                .toResourceId(),
        )

    override fun sequence(
        kind: CollectionKind,
        items: List<Any?>,
        at: ValueLocation,
    ): Any = if (kind == CollectionKind.SET) items.toCollection(LinkedHashSet()) else items

    override fun mapping(
        rows: List<Pair<Any?, Any?>>,
        at: ValueLocation,
    ): Any = rows.toMap(LinkedHashMap())

    override fun record(
        actual: TypeUse,
        fields: Map<String, Any?>,
        at: ValueLocation,
    ): Any = RecordValue(actual, fields)

    override fun named(
        actual: TypeUse,
        payload: Any?,
        at: ValueLocation,
    ): Any = NamedValue(actual, payload)

    override fun defers(use: TypeUse): Boolean = use.isVar() || use is TypeUse.FunctionWrapper

    override fun deferred(
        value: DataValue,
        use: TypeUse,
        at: ValueLocation,
    ): Any = Deferred(at)
}

/** The evaluation value of a stored value at [at] of the declared [type], over [checked], the evaluation's one reader catalog. */
internal fun DataValue.toFormulaValue(
    type: TypeUse,
    at: ValueLocation,
    checked: CheckedCatalog,
): Any? = ValueWalk(checked, FormulaValueVisitor).walk(this, type, at)

/** A deferred value on first use, read by the evaluation at [reader]: Evaluate gives its problems, context and purity gate, for a Var and a function alike. */
context(reads: RealmReads)
internal fun Deferred.value(reader: ValueLocation?): Any? = reads.read(Evaluate(at)).orThrowDependency(at, reader)

/**
 * The value of an evaluation the formula at [reader] reads. A failure or a value that was not evaluated has its own
 * finding at its source, so the reader fails with Dependency, which reports nothing. A cycle the reader is a member of
 * stays that cycle, so each member reports it, whichever member the graph entered first.
 */
internal fun Evaluation<Any?>.orThrowDependency(
    at: ValueLocation,
    reader: ValueLocation?,
): Any? =
    when (this) {
        is Evaluation.Value -> {
            value
        }

        is Evaluation.Failed -> {
            val cycle = reason as? FormulaFailure.Cycle
            if (cycle != null && reader != null && reader.resource in cycle.through) throw FailedEvaluation(cycle)
            throw FailedEvaluation(FormulaFailure.Dependency(at.resource))
        }

        Evaluation.NotEvaluated -> {
            throw FailedEvaluation(FormulaFailure.Dependency(at.resource))
        }
    }

internal fun TypeUse.isVar(): Boolean = (this as? TypeUse.NamedWrapper)?.value?.definition == VarDefinition.id

/**
 * The type the schema declares at [path] of this record and the value stored there, or null when no schema reaches
 * it or the record's type is still pending. On the way, each stored named value's own type decides its fields, as the
 * walk decides them, so a field of a union case is found under the case its value names.
 */
internal fun AuthoringRecord.storedAt(
    owner: ResourceId,
    path: ValuePath,
    catalog: CheckedCatalog,
): Pair<TypeUse, DataValue>? {
    catalog.completeTypeOf(owner, configuration) ?: return null
    val position = typedAt(owner, path, catalog) as? TypedPosition.Value ?: return null
    return position.declared to position.value
}
