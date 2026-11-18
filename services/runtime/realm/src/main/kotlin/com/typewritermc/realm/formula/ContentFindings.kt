package com.typewritermc.realm.formula

import com.typewritermc.formula.FormulaFailure
import com.typewritermc.formula.eval.Evaluation
import com.typewritermc.realm.authoring.RealmQuery
import com.typewritermc.realm.authoring.RealmReads
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId

/** One problem a creator sees on a resource's content, at the field it is about. [related] points at other uses. */
data class ContentFinding(
    val code: String,
    val message: String,
    val at: ValueLocation,
    val related: List<ValueLocation> = emptyList(),
)

/**
 * What a creator sees of one resource's content. One reporter per fact: a hook that failed on it, an owner chain that
 * loops, each value that does not fit its schema, each emptied reference once per distinct name at a formula, and
 * each problem the checker found, and each formula whose evaluation failed by itself. The checker stays silent on an
 * emptied reference, so it is reported once, here; a value that needed something missing or broken elsewhere is silent,
 * since that source has its own finding.
 */
internal data class ContentFindings(
    val resource: ResourceId,
) : RealmQuery<List<ContentFinding>> {
    context(reads: RealmReads)
    override fun compute(): List<ContentFinding> =
        buildList {
            val root =
                ValueLocation(
                    resource = resource,
                    path =
                        skirout.editor.v1.type_catalog.ValuePath
                            .partial(),
                )
            reads.read(DynamicOf(resource)).failures.forEach { add(ContentFinding("dynamic_failed", it.message, root)) }
            if (reads.read(OwnerChain(resource)).loops) {
                add(ContentFinding("scope_loop", "This resource is inside its own owner chain.", root))
            }
            addAll(reads.read(FitOf(resource)))
            reads.read(FormulasOf(resource)).forEach { site ->
                if (site.computedAtFunction) {
                    add(ContentFinding("formula_computed_function", "A function's body is stored as its value, not computed.", site.at))
                    return@forEach
                }
                site.formula.references
                    .filter { it.target == null }
                    .map { site.formula.textAt(it.at) }
                    .distinct()
                    .forEach { name -> add(ContentFinding("formula_deleted_reference", "`$name` was deleted.", site.at)) }
                reads.read(CheckFormula(site.at))?.problems?.forEach { add(ContentFinding(it.code, it.message, site.at)) }
                failureOf(reads.read(Evaluate(site.holder)))?.let { add(ContentFinding("formula_failed", it, site.at)) }
            }
        }
}

/** What a creator reads about a failed evaluation, or null when it did not fail by itself. */
private fun failureOf(evaluation: Evaluation<Any?>): String? =
    when (val reason = (evaluation as? Evaluation.Failed)?.reason) {
        null, is FormulaFailure.Unfilled, is FormulaFailure.Dependency -> null
        is FormulaFailure.ProviderThrew -> "This formula failed: ${reason.message}"
        FormulaFailure.Overflow -> "This formula failed: a number got too large."
        FormulaFailure.DivisionByZero -> "This formula failed: it divides by zero."
        FormulaFailure.NotFinite -> "This formula failed: a number is not finite."
        FormulaFailure.RecursionLimit -> "This formula failed: its functions call each other too deeply."
        FormulaFailure.StepLimit -> "This formula failed: it takes too many steps."
        is FormulaFailure.Cycle -> "These values read each other: ${reason.through.joinToString { it.value }}."
    }
