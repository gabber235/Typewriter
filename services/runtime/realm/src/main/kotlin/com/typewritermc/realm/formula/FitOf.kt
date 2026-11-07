package com.typewritermc.realm.formula

import com.typewritermc.realm.authoring.ProjectionAt
import com.typewritermc.realm.authoring.RealmQuery
import com.typewritermc.realm.authoring.RealmReads
import com.typewritermc.realm.authoring.tracked
import com.typewritermc.types.catalog.CONTENT_TYPE_PROBLEMS
import com.typewritermc.types.catalog.misfits
import skirout.editor.v1.diagnostic.ValueProblem
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId

/**
 * The one reporter of fit, for every record, code or content: a type that is gone or invalid, a value of the wrong
 * shape, a link at a slot its type lacks. It reads the same misfits the planner refuses new ones by, so the two never
 * disagree. It reads the whole record and the tracked catalog, so a declaration edit reruns it on every holder that
 * reached that declaration, and a holder fixing its own value reruns it too. Each finding blocks publish.
 */
internal data class FitOf(
    val resource: ResourceId,
) : RealmQuery<List<ContentFinding>> {
    context(reads: RealmReads)
    override fun compute(): List<ContentFinding> {
        val authored = tracked()
        val record = authored.record(resource) ?: return emptyList()
        val all = record.misfits(resource, authored.viewCatalog.checked) { reads.read(ProjectionAt(resource)).fit }
        // One finding per gone or invalid type, at its outermost use. What sits at or under a use of it is its
        // consequence and is not shown; a misfit elsewhere still is.
        val uses = all.filter { it.problem.code in CONTENT_TYPE_PROBLEMS }
        val causes = uses.groupBy { it.type }.values.map { group -> group.minBy { it.problem.location.path.segments.size } }
        val consequences = all.filter { misfit -> misfit !in uses && uses.any { misfit.problem.location.isWithin(it.problem.location) } }
        val shown = causes + (all - uses.toSet() - consequences.toSet())
        return shown.distinct().map { misfit ->
            val related =
                if (misfit in
                    causes
                ) {
                    uses.filter { it.type == misfit.type && it != misfit }.map { it.problem.location }
                } else {
                    emptyList()
                }
            misfit.problem.toFinding(related)
        }
    }
}

/** Whether this location is [other] or sits under it. */
private fun ValueLocation.isWithin(other: ValueLocation): Boolean =
    resource == other.resource && path.segments.size >= other.path.segments.size &&
        path.segments.subList(0, other.path.segments.size) == other.path.segments

/** The finding a creator sees at the use; a gone type has no name left to give. */
private fun ValueProblem.toFinding(related: List<ValueLocation>): ContentFinding =
    when (code) {
        "content_alias_loop" -> ContentFinding(code, "The custom type used here is defined by itself.", location, related)
        "content_type_missing" -> ContentFinding(code, "A custom type used here no longer exists.", location, related)
        in CONTENT_TYPE_PROBLEMS -> ContentFinding(code, "The custom type used here is not valid ($code).", location, related)
        else -> ContentFinding("value_mismatch", "This value does not fit its type ($code).", location)
    }
