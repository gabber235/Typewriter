package com.typewritermc.realm.authoring

import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.discovery.runExtension
import com.typewritermc.formula.BindBuilder
import com.typewritermc.formula.graph.GraphKey
import com.typewritermc.realm.catalog.code
import com.typewritermc.types.catalog.DerivedFailure
import com.typewritermc.types.catalog.DerivedOrigin
import com.typewritermc.types.catalog.DerivedTarget
import com.typewritermc.types.catalog.derived
import com.typewritermc.types.toTemplate
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeUse
import skirout.kernel.v1.resource_id.ResourceId

/**
 * What the bind registered for [owner]'s type parameter [key] computes from [owner]'s content, run on this reader. The
 * bind reads [owner] through the type its creator's choices give, so it never needs the type it computes; reading that
 * type anyway, here or through another resource, is a loop, which the caller answers: the query graph through
 * [DerivedTypeOf.onCycle], a reader outside it through [BindRunner].
 */
internal fun CapturedAuthoringReads.boundType(
    owner: ResourceId,
    key: String,
): DerivedTarget {
    val definition = record(owner)?.configuration?.definition ?: return DerivedTarget.Missing(DerivedFailure.NoBlock)
    val binds =
        view.original.catalog.code.extensions.binds
            .filter { it.key.owner == definition && it.key.name == key }
    val bind =
        when (binds.size) {
            0 -> return DerivedTarget.Missing(DerivedFailure.NoBlock)
            1 -> binds.single()
            else -> return DerivedTarget.Missing(DerivedFailure.Conflict(binds.map { it.origin }))
        }
    val binding =
        authoredBinding(owner)
            ?: return DerivedTarget.Missing(DerivedFailure.Failed(bind.origin, "The resource's own type does not resolve."))
    val record = BoundRecord(this, TypeDefinitionId.derived(owner, key))
    return runExtension({
        bind.run(record, binding)
        DerivedTarget.Declared(record.definition())
    }) { failure -> DerivedTarget.Missing(DerivedFailure.Failed(bind.origin, failure.message ?: failure::class.simpleName.orEmpty())) }
}

/**
 * What a bind computes, kept in the query graph: an edit reruns only the binds whose reads it changed. A bind that needs
 * its own result, through any chain of binds, answers a loop through every owner on it.
 */
internal data class DerivedTypeOf(
    val owner: ResourceId,
    val key: String,
) : RealmQuery<DerivedTarget> {
    context(reads: RealmReads)
    override fun compute(): DerivedTarget = tracked().boundType(owner, key)

    /** Sorted, so the answer is equal whichever member a pass entered first, and readers keep early cutoff. */
    override fun onCycle(members: List<GraphKey<*>>): DerivedTarget =
        DerivedTarget.Missing(
            DerivedFailure.Loop(
                members
                    .filterIsInstance<DerivedTypeOf>()
                    .map { it.owner }
                    .distinct()
                    .sortedBy { it.value },
            ),
        )
}

/**
 * What binds compute over one view, for readers outside the query graph. Each bind runs once, on [reads], a reader of its
 * own whose catalog asks this runner back, so its health never mixes with a caller's. A bind that needs its own result
 * through any chain of binds answers a loop through every owner on that chain, as [DerivedTypeOf.onCycle] does. Callers
 * on any thread share one runner; it runs one bind at a time, since its reader requires serialized use.
 */
internal class BindRunner(
    private val reads: CapturedAuthoringReads,
) : DerivedOrigin {
    private val answers = mutableMapOf<Pair<ResourceId, String>, DerivedTarget>()
    private val running = mutableListOf<Pair<ResourceId, String>>()
    private val loops = mutableMapOf<Pair<ResourceId, String>, Set<ResourceId>>()

    @Synchronized
    override fun derived(
        owner: ResourceId,
        key: String,
    ): DerivedTarget {
        val bind = owner to key
        answers[bind]?.let { return it }
        val entered = running.indexOf(bind)
        if (entered >= 0) {
            // Every bind from the first entry of this one upward waits on this answer, so each is on the loop.
            val cycle = running.subList(entered, running.size).toList()
            val owners = cycle.flatMapTo(mutableSetOf()) { loops[it].orEmpty() + it.first }
            cycle.forEach { loops[it] = owners }
            return loop(owners)
        }
        running += bind
        val computed =
            try {
                reads.boundType(owner, key)
            } finally {
                running.removeLast()
            }
        return (loops.remove(bind)?.let(::loop) ?: computed).also { answers[bind] = it }
    }

    /** Sorted, so the answer is equal whichever member a caller asked first. */
    private fun loop(owners: Set<ResourceId>): DerivedTarget = DerivedTarget.Missing(DerivedFailure.Loop(owners.sortedBy { it.value }))
}

/**
 * What binds compute over the view [view] gives, for a view that may not exist yet when its catalog is built: the runner
 * and its reader are made on the first answer.
 */
internal fun bindsOver(view: () -> AuthoredReadView): DerivedOrigin {
    val runner by lazy { CapturedAuthoringReads(view()).derivedTypes }
    return DerivedOrigin { owner, key -> runner.derived(owner, key) }
}

/** What binds compute over [resources], read against this view. The links of [resources] are found on the first answer. */
internal fun AuthoringView.boundTypesOver(resources: Map<ResourceId, AuthoringRecord>): DerivedOrigin =
    bindsOver { AuthoredReadView.Staged(this, resources, ResourceValueMapper.discover(resources).associateBy { it.id }) }

/** The record one bind computes, kept apart until the bind finishes, so a bind that fails adds nothing. */
private class BoundRecord(
    reads: AuthoredReads,
    private val id: TypeDefinitionId,
) : BindBuilder,
    AuthoredReads by reads {
    private val fields = mutableListOf<FieldDeclaration>()

    override fun field(
        name: String,
        type: TypeUse,
        hasDefault: Boolean,
    ) {
        fields +=
            FieldDeclaration.partial(
                owner = FieldOwner(definition = id, name = name),
                type = type.toTemplate(),
                hasConstructorDefault = hasDefault,
            )
    }

    fun definition(): TypeDefinition =
        TypeDefinition.partial(
            id = id,
            representation = RepresentationTemplate.createRecord(fields = fields.toList(), form = RecordForm.CONCRETE),
        )
}
