package com.typewritermc.realm.edit

import com.typewritermc.authoring.Misfit
import com.typewritermc.authoring.RealmRootDefinition
import com.typewritermc.authoring.RealmSectionDefinition
import com.typewritermc.authoring.id
import com.typewritermc.authoring.record
import com.typewritermc.authoring.root
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.authoring.ProjectionResult
import com.typewritermc.realm.authoring.ResourceValueMapper
import com.typewritermc.realm.formula.isWithin
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.contentOwner
import com.typewritermc.types.catalog.misfiledDeclarations
import com.typewritermc.types.catalog.misfits
import com.typewritermc.types.catalog.namesDerivedKey
import com.typewritermc.types.isAcyclic
import com.typewritermc.types.ownsResources
import com.typewritermc.types.record
import skirout.editor.v1.authoring.LinkOccurrence
import skirout.editor.v1.authoring_facts.LinkProjection
import skirout.editor.v1.catalog.EndpointCardinality
import skirout.editor.v1.catalog.EndpointSlot
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.diagnostic.ValueProblem
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.kernel.v1.resource_id.ResourceId

/**
 * Validates an authored snapshot against structure, relation and realm structure rules. [catalog] reads the proposed
 * state and [savedCatalog] the saved one.
 */
internal class AuthoringSnapshotValidator(
    private val catalog: CheckedCatalog,
    private val savedCatalog: CheckedCatalog,
    private val contracts: List<RelationContract>,
    /** The view the change started from: what binds compute over a set of resources is read against it. */
    private val saved: AuthoringView,
) {
    /**
     * Validates the same affected graph boundary for replay and caller supplied working overlays. [before] holds the
     * resources the change started from, so removing the realm root or a realm section is detected.
     *
     * A value can stop fitting its schema through an edit on another resource or a new generation, so a record is
     * refused only for what this change made worse: its misfits now, less the ones it already had. The old record is
     * judged twice, under the saved catalog and under the proposed one with its own declarations as they were, so a
     * delete or retype elsewhere is tolerated however the change groups it, while a change whose own declarations make
     * its own value misfit is refused.
     */
    fun validate(
        before: Map<ResourceId, AuthoringRecord>,
        resources: Map<ResourceId, AuthoringRecord>,
        affected: Set<ResourceId>,
        links: PlannedLinks,
        savedFit: (ResourceId) -> List<ValueProblem>,
    ): List<ValueProblem> {
        val problems = mutableListOf<ValueProblem>()
        val touching = links.touching
        resources.filterKeys { it in affected }.forEach { (id, record) ->
            problems += record.misfiledDeclarations(id)
            val old = before[id]
            val baseline =
                old
                    ?.let { previous ->
                        val ownAsBefore =
                            if (previous.types == record.types) {
                                catalog
                            } else {
                                val asBefore = resources + (id to record.copy(types = previous.types))
                                catalog.withContent(saved.staged(asBefore).content)
                            }
                        val alone = projectAlone(id, previous, resources, ownAsBefore)
                        previous.misfits(id, savedCatalog) { savedFit(id) } +
                            previous.misfits(id, ownAsBefore) { alone.fit.on(id) }
                    }.orEmpty()
                    .toSet()
            problems +=
                record
                    .misfits(id, catalog) { touching.fit.on(id) }
                    .withoutOwnBinds(id)
                    .filter { it.isNewAgainst(baseline) }
                    .map { it.problem }
        }
        problems += touching.problems
        validateOwnership(links, contracts, problems)
        validateRealmStructure(before, resources, affected, links, contracts, catalog, problems)
        validateCardinality(links, contracts, problems)
        validateAcyclic(links, contracts, affected, problems)
        return problems.distinct()
    }

    /** One record's own links judged over [resources] with that record put back as [record]. */
    private fun projectAlone(
        id: ResourceId,
        record: AuthoringRecord,
        resources: Map<ResourceId, AuthoringRecord>,
        catalog: CheckedCatalog,
    ): ProjectionResult {
        val state = resources + (id to record)
        return ResourceValueMapper.project(ResourceValueMapper.discover(mapOf(id to record)), state, contracts, catalog)
    }
}

/** The problems located on [resource]. */
private fun List<ValueProblem>.on(resource: ResourceId): List<ValueProblem> = filter { it.location.resource == resource }

/**
 * These misfits without the ones a type [owner]'s own binds compute causes: each misfit naming such a type, and whatever
 * sits under a value of it. That type is extension output, not a choice the write made, so its failure shows as a
 * finding on [owner] and blocks publish but never refuses the write. A misfit naming another resource's computed type
 * stays, so a new use of it is refused like a use of any missing type, and one [owner] already had is not.
 */
private fun List<Misfit>.withoutOwnBinds(owner: ResourceId): List<Misfit> {
    val own = filter { misfit -> misfit.type?.let { it.namesDerivedKey() && it.contentOwner() == owner } == true }.toSet()
    // A use at the root names the type from the configuration, not a value, so nothing sits under it.
    val values = own.map { it.problem.location }.filter { it.path.segments.isNotEmpty() }
    return filterNot { misfit -> misfit in own || values.any { misfit.problem.location.isWithin(it) } }
}

/** A resource with more than one owner, where one of its ownership links has an affected end. */
private fun validateOwnership(
    links: PlannedLinks,
    contracts: List<RelationContract>,
    problems: MutableList<ValueProblem>,
) {
    val ownership = contracts.filter { it.ownsResources }
    links.touching.projections
        .filter { link -> ownership.any { it.id == link.contract } }
        .mapTo(linkedSetOf()) { it.second }
        .filter { owned -> ownership.sumOf { links.at(owned, it.id, EndpointSlot.SECOND).size } > 1 }
        .forEach { resource -> problems += problem(resource, "multiple_immediate_owners") }
}

/**
 * Keeps every resource reachable from the single realm root. An affected resource whose type is the member of an
 * ownership relation needs an owner (owner_required); catalog assembly makes every concrete resource type except the
 * realm root such a member, so this is every resource but the root. The root and each concrete realm section type
 * have exactly one instance, so a second one is rejected (singleton_exists) and so is removing or retyping the last
 * one (singleton_required).
 */
private fun validateRealmStructure(
    before: Map<ResourceId, AuthoringRecord>,
    resources: Map<ResourceId, AuthoringRecord>,
    affected: Set<ResourceId>,
    links: PlannedLinks,
    contracts: List<RelationContract>,
    catalog: CheckedCatalog,
    problems: MutableList<ValueProblem>,
) {
    fun AuthoringRecord.isRealmRoot() =
        configuration.definition.let {
            it == RealmRootDefinition.id ||
                catalog.isNominalSubtype(it, RealmRootDefinition.id)
        }

    fun AuthoringRecord.singletonKey(): TypeDefinitionId? =
        when {
            isRealmRoot() -> RealmRootDefinition.id
            catalog.isNominalSubtype(configuration.definition, RealmSectionDefinition.id) -> configuration.definition
            else -> null
        }

    val ownership = contracts.filter { it.ownsResources }
    val members = ownership.map { it.second.resource.definition }

    fun ResourceId.isOwned() = ownership.any { links.at(this, it.id, EndpointSlot.SECOND).isNotEmpty() }

    fun AuthoringRecord.isOwnable() =
        configuration.definition.let { type -> members.any { it == type || catalog.isNominalSubtype(type, it) } }

    // A member without a back reference loses its owner when only the owner's record changes, so the resources an
    // affected resource owned before the change are checked too.
    val formerlyOwned =
        ResourceValueMapper
            .project(ResourceValueMapper.discover(before.filterKeys { it in affected }), before, contracts, catalog)
            .projections
            .filter { projection -> projection.first in affected && ownership.any { it.id == projection.contract } }
            .map { it.second }
    (affected + formerlyOwned)
        .distinct()
        .filter { id -> resources[id]?.let { !it.isRealmRoot() && it.isOwnable() } == true && !id.isOwned() }
        .forEach { id -> problems += problem(id, "owner_required") }
    val singletons = resources.entries.groupBy({ it.value.singletonKey() }, { it.key })
    singletons
        .filterKeys { it != null }
        .filterValues { ids -> ids.size > 1 && ids.any { it in affected } }
        .values
        .forEach { ids -> ids.filter { it in affected }.forEach { id -> problems += problem(id, "singleton_exists") } }
    before
        .filterKeys { it in affected }
        .forEach { (id, record) ->
            val key = record.singletonKey() ?: return@forEach
            if (resources[id]?.singletonKey() != key && singletons[key].isNullOrEmpty()) problems += problem(id, "singleton_required")
        }
}

/** An end of a link with an affected end that holds more links of its relation than its endpoint allows. */
private fun validateCardinality(
    links: PlannedLinks,
    contracts: List<RelationContract>,
    problems: MutableList<ValueProblem>,
) {
    val touching = links.touching.projections.groupBy { it.contract }
    contracts.forEach { contract ->
        val touched = touching[contract.id].orEmpty()
        if (contract.first.cardinality == EndpointCardinality.ONE) {
            touched
                .mapTo(linkedSetOf()) { it.second }
                .filter { links.at(it, contract.id, EndpointSlot.SECOND).size > 1 }
                .forEach { resource -> problems += problem(resource, "first_endpoint_cardinality_exceeded") }
        }
        if (contract.second.cardinality == EndpointCardinality.ONE) {
            touched
                .mapTo(linkedSetOf()) { it.first }
                .filter { links.at(it, contract.id, EndpointSlot.FIRST).size > 1 }
                .forEach { resource -> problems += problem(resource, "second_endpoint_cardinality_exceeded") }
        }
    }
}

/**
 * Rejects a cycle through any acyclic relation reachable from an affected resource.
 *
 * Walks first to second endpoints iteratively so long chains cannot exhaust the stack, and finishes every resource
 * once per contract.
 */
private fun validateAcyclic(
    links: PlannedLinks,
    contracts: List<RelationContract>,
    affected: Set<ResourceId>,
    problems: MutableList<ValueProblem>,
) {
    contracts.filter { it.isAcyclic }.forEach { contract ->
        val next = { id: ResourceId -> links.at(id, contract.id, EndpointSlot.FIRST).map { it.second } }
        val finished = hashSetOf<ResourceId>()
        affected.forEach root@{ root ->
            val active = hashSetOf<ResourceId>()
            val stack = ArrayDeque(listOf(root to false))
            while (stack.isNotEmpty()) {
                val (id, leaving) = stack.removeLast()
                if (leaving) {
                    active -= id
                    finished += id
                    continue
                }
                if (id in finished) continue
                if (!active.add(id)) {
                    problems += problem(root, "relation_cycle")
                    return@root
                }
                stack.addLast(id to true)
                next(id).forEach { stack.addLast(it to false) }
            }
        }
    }
}

/**
 * The links of the state a change proposes, as the rules read them: every link with an affected end, judged with its
 * problems and misfits, and any resource's links of one relation at one end, which a rule asks for by name.
 */
internal interface PlannedLinks {
    /** The judged links with an affected end: only these can change, so only their problems refuse a change. */
    val touching: ProjectionResult

    /** The links of [contract] in which [resource] is the [slot] end. */
    fun at(
        resource: ResourceId,
        contract: RelationId,
        slot: EndpointSlot,
    ): List<LinkProjection>
}

/** The links of a whole judged state, for a change to [affected] read from its [occurrences]. */
internal fun ProjectionResult.planned(
    occurrences: Collection<LinkOccurrence>,
    affected: Set<ResourceId>,
): PlannedLinks {
    val locations = occurrences.filter { it.source in affected || it.target.resource in affected }.mapTo(hashSetOf()) { it.id.location }
    val touching =
        ProjectionResult(
            projections = projections.filter { it.first in affected || it.second in affected },
            problems = problems.filter { it.location in locations },
            fit = fit,
        )
    val byEnd =
        projections.groupBy { Triple(it.contract, EndpointSlot.FIRST, it.first) } +
            projections.groupBy { Triple(it.contract, EndpointSlot.SECOND, it.second) }
    return object : PlannedLinks {
        override val touching = touching

        override fun at(
            resource: ResourceId,
            contract: RelationId,
            slot: EndpointSlot,
        ) = byEnd[Triple(contract, slot, resource)].orEmpty()
    }
}
