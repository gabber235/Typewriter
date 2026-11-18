package com.typewritermc.realm.formula

import com.typewritermc.formula.check.NameAnswer
import com.typewritermc.formula.check.NameMeaning
import com.typewritermc.formula.check.StoredFormula
import com.typewritermc.formula.check.StoredReference
import com.typewritermc.formula.check.check
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.authoring.RealmQuery
import com.typewritermc.realm.authoring.RealmReads
import com.typewritermc.realm.authoring.conflicts
import com.typewritermc.realm.authoring.factsRead
import com.typewritermc.types.toSkir
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId

/** The realm owned writes that follow an accepted edit: [candidate] is the view the edit leaves, [changed] what it changed. */
internal fun interface CommitRepairs {
    fun intents(
        saved: AuthoringView,
        candidate: AuthoringView,
        changed: Set<ResourceId>,
    ): List<EditIntent>
}

/** The binder over this store's graph. */
internal fun AuthoringViewStore.commitRepairs(): CommitRepairs =
    CommitRepairs {
        saved,
        candidate,
        changed,
        ->
        repairIntents(saved, candidate, changed)
    }

/** Whether a formula saved at [resource] left a name without a target, and whether one of those names has exactly one candidate. */
internal data class Unbound(
    val bindable: Boolean,
)

/**
 * The formulas of [resource] whose check on saved state left a name without a target. Bindable means a commit that
 * failed to bind left it, so the next commit binds it whatever it changes. On the live graph, so it stays warm.
 */
internal data class UnboundIn(
    val resource: ResourceId,
) : RealmQuery<Map<ValueLocation, Unbound>> {
    context(reads: RealmReads)
    override fun compute(): Map<ValueLocation, Unbound> =
        reads
            .read(FormulasOf(resource))
            .mapNotNull { site ->
                val names =
                    reads
                        .read(CheckFormula(site.at))
                        ?.names
                        .orEmpty()
                        .filter { it.meaning.isUnbound() }
                if (names.isEmpty()) null else site.at to Unbound(bindable = names.any { it.candidates.size == 1 })
            }.toMap()
}

private fun NameMeaning.isUnbound(): Boolean = this is NameMeaning.Unknown || this is NameMeaning.Deleted

/** Why a formula is being bound. A candidate has one reason; edited wins over emptied. */
private sealed interface BindingReason {
    /** The source changed, so every name binds afresh, and a container name beats a provider. */
    data object Edited : BindingReason

    /** A name had no target on saved state; only such names bind. */
    data object Broken : BindingReason

    /** A delete just emptied a reference: the formula is sealed to the text the creator last saw. */
    data class Emptied(
        val lastSeen: Displayed,
    ) : BindingReason
}

/**
 * Realm owned writes that follow a creator's edit; they never decide whether it is accepted. Candidates come from
 * what is already known: formulas the edit changed or emptied, and saved broken formulas whose check read something
 * the edit changed. So a commit that touches no formula and nothing a broken formula read forks nothing, parses
 * nothing and runs no hook on a warm memo. Binding is a plain function over a fork that is thrown away.
 */
internal fun AuthoringViewStore.repairIntents(
    saved: AuthoringView,
    proposed: AuthoringView,
    changed: Set<ResourceId>,
): List<EditIntent> {
    val (edited, emptied) = touchedFormulas(saved, proposed, changed)
    val (broken, lastSeen) =
        pin().use { pinned ->
            with(pinned.reads) { brokenFormulas(saved, proposed) to emptied.mapValues { (at, formula) -> formula.displayed(at) } }
        }
    val candidates = edited + emptied.keys + broken
    if (candidates.isEmpty()) return emptyList()
    val after = forkAt(proposed).pin()
    return candidates.mapNotNull { at ->
        val site = after.read(FormulasOf(at.resource)).firstOrNull { it.at == at }?.takeUnless { it.computedAtFunction }
        val reason =
            when (at) {
                in edited -> BindingReason.Edited
                in emptied -> BindingReason.Emptied(lastSeen.getValue(at))
                else -> BindingReason.Broken
            }
        site?.let { at.bound(it, reason, proposed, after) }?.takeIf { it != site.formula }?.let { wanted ->
            EditIntent.createSetValue(at = at, value = wanted.toDataValue(proposed, at.resource))
        }
    }
}

/** What an edit did to the formulas of [changed]: those whose text it set, and those a delete emptied, with their saved form. */
private data class TouchedFormulas(
    val edited: Set<ValueLocation>,
    val emptied: Map<ValueLocation, StoredFormula>,
)

private fun touchedFormulas(
    saved: AuthoringView,
    proposed: AuthoringView,
    changed: Set<ResourceId>,
): TouchedFormulas {
    val edited = linkedSetOf<ValueLocation>()
    val emptied = linkedMapOf<ValueLocation, StoredFormula>()
    changed.forEach { id ->
        val record = proposed.resources[id] ?: return@forEach
        val before = saved.resources[id]
        val savedFormulas = before?.formulaSites(id, saved.catalog.checked).orEmpty().associate { it.at to it.formula }
        record.formulaSites(id, proposed.catalog.checked).forEach { site ->
            val old = savedFormulas[site.at]
            when {
                before == null -> if (site.formula.references.isEmpty()) edited += site.at
                old == null || old.source != site.formula.source -> edited += site.at
                site.formula.emptiedFrom(old) -> emptied[site.at] = old
            }
        }
    }
    return TouchedFormulas(edited, emptied)
}

/** Whether this formula is [old] with a reference a delete just emptied. */
private fun StoredFormula.emptiedFrom(old: StoredFormula): Boolean =
    old.references.any { saved -> saved.target != null && references.any { it.at == saved.at && it.target == null } }

/** Saved formulas with an unbound name that this commit may bind: a bindable one, or one whose check read what [proposed] changed. */
context(reads: RealmReads)
private fun brokenFormulas(
    saved: AuthoringView,
    proposed: AuthoringView,
): List<ValueLocation> =
    saved.resources.keys
        .flatMap { reads.read(UnboundIn(it)).entries }
        .filter { (at, unbound) -> unbound.bindable || proposed.values.conflicts(CheckFormula(at).factsRead { false }).isNotEmpty() }
        .map { it.key }

/** The formula [site] should hold in [proposed], read through [reads] over that view. */
private fun ValueLocation.bound(
    site: FormulaSite,
    reason: BindingReason,
    proposed: AuthoringView,
    reads: RealmReads,
): StoredFormula {
    // One binding per round, earliest first, then a recheck: a name read before another can change what that one
    // means (a bound `when` subject turns `is Open` into a case), so later answers are only trusted after it binds.
    var current = reason.startingFrom(site.formula, proposed)
    repeat(current.source.length + 1) {
        val checked = with(RealmFormulaEnvironment(this, reads)) { current.check(site.expected) }
        val round = checked.names.sortedBy { it.span.start }.fold(BindingRound()) { round, answer -> round.after(answer, reason) }
        current = current.copy(references = round.references())
        if (round.next == null) return current
    }
    return current
}

/** The formula binding starts from: no references for edited text, the saved ones for a broken formula, and the text last seen for an emptied one. */
private fun BindingReason.startingFrom(
    formula: StoredFormula,
    proposed: AuthoringView,
): StoredFormula =
    when (this) {
        is BindingReason.Edited -> {
            formula.copy(references = emptyList())
        }

        is BindingReason.Broken -> {
            formula
        }

        is BindingReason.Emptied -> {
            val gone = { reference: StoredReference -> reference.target?.toSkir()?.let(proposed.resources::containsKey) == false }
            StoredFormula(lastSeen.text, lastSeen.references.map { if (gone(it)) it.copy(target = null) else it })
        }
    }

/** One binding round: the references kept as they are, and the one new binding it adds, if any. */
private data class BindingRound(
    val kept: List<StoredReference> = emptyList(),
    val next: StoredReference? = null,
) {
    fun after(
        answer: NameAnswer,
        reason: BindingReason,
    ): BindingRound {
        val only = answer.candidates.singleOrNull()?.let { StoredReference(answer.span, it) }
        val open = next == null && only != null
        return when (val meaning = answer.meaning) {
            is NameMeaning.Resource -> copy(kept = kept + StoredReference(answer.span, meaning.id))

            // An emptied reference with no single candidate stays stored, reported once by ContentFindings.
            is NameMeaning.Deleted -> if (open) copy(next = only) else copy(kept = kept + StoredReference(answer.span, null))

            is NameMeaning.Unknown -> if (open) copy(next = only) else this

            is NameMeaning.Provider, is NameMeaning.CatalogType -> if (open && reason is BindingReason.Edited) copy(next = only) else this

            is NameMeaning.Local, is NameMeaning.Parameter, is NameMeaning.Case -> this
        }
    }

    fun references(): List<StoredReference> = (kept + listOfNotNull(next)).distinctBy { it.at }.sortedBy { it.at.start }
}
