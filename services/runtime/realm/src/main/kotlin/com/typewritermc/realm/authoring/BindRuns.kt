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
 * type anyway, here or through another resource, is a loop.
 */
internal fun CapturedAuthoringReads.boundType(
    owner: ResourceId,
    key: String,
): DerivedTarget {
    val definition = record(owner)?.configuration?.definition ?: return DerivedTarget.Missing(DerivedFailure.NoBlock)
    val binds = view.original.catalog.code.extensions.binds.filter { it.key.owner == definition && it.key.name == key }
    val bind =
        when (binds.size) {
            0 -> return DerivedTarget.Missing(DerivedFailure.NoBlock)
            1 -> binds.single()
            else -> return DerivedTarget.Missing(DerivedFailure.Conflict(binds.map { it.origin }))
        }
    val id = TypeDefinitionId.derived(owner, key)
    return running(id, onLoop = { DerivedTarget.Missing(DerivedFailure.Loop(listOf(owner))) }) {
        val binding =
            authoredBinding(owner)
                ?: return@running DerivedTarget.Missing(DerivedFailure.Failed(bind.origin, "The resource's own type does not resolve."))
        val record = BoundRecord(this, id)
        runExtension({
            bind.run(record, binding)
            DerivedTarget.Declared(record.definition())
        }) { failure -> DerivedTarget.Missing(DerivedFailure.Failed(bind.origin, failure.message ?: failure::class.simpleName.orEmpty())) }
    }
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

/** What [owner]'s bind under [key] computes in this view, run on a fresh reader, so callers on any thread share it. */
internal fun AuthoringView.boundType(
    owner: ResourceId,
    key: String,
): DerivedTarget = CapturedAuthoringReads(AuthoredReadView.Original(this)).boundType(owner, key)

/**
 * What binds compute over [resources], read against this view: each answer runs on a fresh reader of a staged view of
 * [resources], so callers on any thread share it. The links of [resources] are found once, on the first answer.
 */
internal fun AuthoringView.boundTypesOver(resources: Map<ResourceId, AuthoringRecord>): DerivedOrigin {
    val links by lazy { ResourceValueMapper.discover(resources).associateBy { it.id } }
    return DerivedOrigin { owner, key -> CapturedAuthoringReads(AuthoredReadView.Staged(this, resources, links)).boundType(owner, key) }
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
        TypeDefinition.partial(id = id, representation = RepresentationTemplate.createRecord(fields = fields.toList(), form = RecordForm.CONCRETE))
}
