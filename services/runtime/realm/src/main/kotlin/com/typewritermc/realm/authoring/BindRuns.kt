package com.typewritermc.realm.authoring

import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.checking.InputIdentity
import com.typewritermc.discovery.runExtension
import com.typewritermc.formula.BindBuilder
import com.typewritermc.formula.graph.GraphKey
import com.typewritermc.realm.catalog.code
import com.typewritermc.types.catalog.DerivedFailure
import com.typewritermc.types.catalog.DerivedOrigin
import com.typewritermc.types.catalog.DerivedTarget
import com.typewritermc.types.catalog.derived
import com.typewritermc.types.toTemplate
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeUse
import skirout.kernel.v1.resource_id.ResourceId
import java.util.concurrent.CancellationException

/**
 * What the bind registered for [owner]'s type parameter [key] computes from [owner]'s content, run on this reader. The
 * bind reads [owner] through the type its creator's choices give, so it never needs the type it computes; reading that
 * type anyway, here or through another resource, is a loop, which the caller answers: the query graph through
 * [DerivedTypeOf.onCycle], a reader outside it through [ViewBinds].
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

/** What one bind computed and every fact it read on the way, so a reader that takes the answer can take its evidence. */
internal data class BoundAnswer(
    val target: DerivedTarget,
    val inputs: Set<InputIdentity>,
)

/**
 * What binds compute over one view state, for readers outside the query graph: each bind runs once, whichever reader
 * asks, and its answer keeps the facts it read, so every reader that takes it records them as its own evidence.
 *
 * A bind runs on [reads], a reader of its own whose catalog asks these binds back, so its health never mixes with a
 * caller's. A bind that needs its own result answers a loop through every bind from its first entry up, and those binds
 * stop where they are, as the query graph unwinds a cycle to its head; a caller of the head carries on with the loop
 * answer. Callers on any thread share one instance; it runs one bind at a time, since its reader requires serialized use.
 */
internal class ViewBinds(
    view: AuthoredReadView,
) : ObservationRecorder {
    private val reads by lazy { CapturedAuthoringReads(view, this) }
    private val answers = mutableMapOf<Pair<ResourceId, String>, BoundAnswer>()
    private val running = mutableListOf<Pair<Pair<ResourceId, String>, MutableSet<InputIdentity>>>()

    /** What these binds compute, as a catalog asks it, with no reader to record the facts. */
    val origin = DerivedOrigin { owner, key -> answer(owner, key).target }

    @Synchronized
    fun answer(
        owner: ResourceId,
        key: String,
    ): BoundAnswer {
        val bind = owner to key
        answers[bind]?.let { known -> return known.also { it.inputs.forEach(::observe) } }
        val entered = running.indexOfFirst { it.first == bind }
        if (entered >= 0) {
            val cycle = running.subList(entered, running.size).toList()
            val loop = DerivedTarget.Missing(DerivedFailure.Loop(cycle.map { it.first.first }.distinct().sortedBy { it.value }))
            cycle.forEach { (member, inputs) -> answers[member] = BoundAnswer(loop, inputs.toSet()) }
            throw BindLoop(bind)
        }
        running += bind to linkedSetOf()
        return try {
            val target = reads.boundType(owner, key)
            BoundAnswer(target, running.last().second.toSet()).also { answers[bind] = it }
        } catch (loop: BindLoop) {
            if (loop.head != bind) throw loop
            answers.getValue(bind)
        } finally {
            running.removeLast()
        }
    }

    /** A fact a running bind read is evidence for that bind and for every bind waiting on it. */
    override fun observe(identity: InputIdentity) {
        running.forEach { it.second += identity }
    }

    override fun derivedTypes(reads: CapturedAuthoringReads): DerivedOrigin = origin

    /**
     * Unwinds every bind on a loop to its [head]. A cancellation, so extension code and the reads under it pass it on
     * instead of reporting it as their own failure.
     */
    private class BindLoop(
        val head: Pair<ResourceId, String>,
    ) : CancellationException("A bind needs its own result.")
}

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
