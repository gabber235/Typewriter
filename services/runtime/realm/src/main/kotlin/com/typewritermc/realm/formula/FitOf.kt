package com.typewritermc.realm.formula

import com.typewritermc.authoring.Misfit
import com.typewritermc.authoring.MisfitCause
import com.typewritermc.authoring.of
import com.typewritermc.authoring.unavailableType
import com.typewritermc.realm.authoring.ProjectionAt
import com.typewritermc.realm.authoring.RealmQuery
import com.typewritermc.realm.authoring.RealmReads
import com.typewritermc.realm.authoring.tracked
import com.typewritermc.types.catalog.DerivedFailure
import com.typewritermc.types.catalog.Unavailability
import com.typewritermc.types.catalog.contentOwner
import com.typewritermc.types.catalog.misfits
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
        val catalog = authored.viewCatalog.checked
        val all = record.misfits(resource, catalog) { reads.read(ProjectionAt(resource)).fit }
        // One finding per gone or invalid type, at its outermost use. What sits at or under a use of it is its
        // consequence and is not shown; a misfit elsewhere still is.
        val uses = all.filter { it.cause is MisfitCause.TypeUnavailable }
        val causes = uses.groupBy { it.unavailableType }.values.map { group -> group.minBy { it.problem.location.path.segments.size } }
        val consequences = all.filter { misfit -> misfit !in uses && uses.any { misfit.problem.location.isWithin(it.problem.location) } }
        val shown = causes + (all - uses.toSet() - consequences.toSet())
        return shown.distinct().map { misfit ->
            val related = uses.filter { misfit in causes && it.unavailableType == misfit.unavailableType && it != misfit }
            misfit.toFinding(related.map { it.problem.location })
        }
    }
}

/** Whether this location is [other] or sits under it. */
internal fun ValueLocation.isWithin(other: ValueLocation): Boolean =
    resource == other.resource && path.segments.size >= other.path.segments.size &&
        path.segments.subList(0, other.path.segments.size) == other.path.segments

/** The finding a creator sees at the misfit; a use of an unavailable type says why that type is unavailable. */
private fun Misfit.toFinding(related: List<ValueLocation>): ContentFinding {
    val code = problem.code
    val location = problem.location
    val cause =
        cause as? MisfitCause.TypeUnavailable
            ?: return ContentFinding("value_mismatch", "This value does not fit its type ($code).", location)
    return when (val why = cause.why) {
        Unavailability.Missing -> {
            ContentFinding(code, "A custom type used here no longer exists.", location, related)
        }

        Unavailability.AliasLoop -> {
            ContentFinding(code, "The custom type used here is defined by itself.", location, related)
        }

        is Unavailability.Invalid -> {
            ContentFinding(code, "The custom type used here is not valid ($code).", location, related)
        }

        // A computed type that aliases another resource's names that resource, whose bind is the one to fix.
        is Unavailability.Computed -> {
            if (why.at.owner == cause.type.contentOwner()) {
                ContentFinding(code, why.at.failure.message(), location, related)
            } else {
                ContentFinding(code, why.at.failure.aliasedMessage(), location, related + ValueLocation.of(why.at.owner))
            }
        }
    }
}

/** What a creator reads about a computed type that leads nowhere; a failed bind gives its own words. */
private fun DerivedFailure.message(): String =
    when (this) {
        DerivedFailure.NoBlock -> "No bind computes the type used here."
        is DerivedFailure.Conflict -> "More than one bind computes the type used here, so none decides it."
        is DerivedFailure.Loop -> "The type used here is computed from itself."
        is DerivedFailure.Failed -> "The type used here could not be computed: $message"
    }

/** What a creator reads about a computed type that follows another resource's computed type, which leads nowhere. */
private fun DerivedFailure.aliasedMessage(): String =
    "The type used here follows another resource's computed type, which " +
        when (this) {
            DerivedFailure.NoBlock -> "no bind computes."
            is DerivedFailure.Conflict -> "more than one bind computes, so none decides it."
            is DerivedFailure.Loop -> "is computed from itself."
            is DerivedFailure.Failed -> "could not be computed: $message"
        }
