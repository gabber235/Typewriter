package com.typewritermc.realm.edit

import com.typewritermc.authoring.RealmRootDefinition
import com.typewritermc.authoring.RealmSectionDefinition
import com.typewritermc.authoring.definition
import com.typewritermc.authoring.id
import com.typewritermc.authoring.record
import com.typewritermc.authoring.root
import com.typewritermc.authoring.validateStructure
import com.typewritermc.realm.authoring.ProjectionResult
import com.typewritermc.realm.authoring.ResourceValueMapper
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.isAcyclic
import com.typewritermc.types.ownsResources
import com.typewritermc.types.record
import com.typewritermc.types.unknownVariant
import skirout.editor.v1.authoring_facts.LinkProjection
import skirout.editor.v1.catalog.EndpointCardinality
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.diagnostic.StructuralResult
import skirout.editor.v1.diagnostic.ValueProblem
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.ResourceId
import skirout.editor.v1.type_catalog.TypeDefinitionId

/** Validates an authored snapshot against structure, relation and realm structure rules. */
internal class AuthoringSnapshotValidator(
    private val catalog: CheckedCatalog,
    private val contracts: List<RelationContract>,
) {
    /**
     * Validates the same affected graph boundary for replay and caller supplied working overlays. [before] holds the
     * resources the change started from, so removing the realm root or a realm section is detected.
     */
    fun validate(
        before: Map<ResourceId, AuthoringRecord>,
        resources: Map<ResourceId, AuthoringRecord>,
        affected: Set<ResourceId>,
        projection: ProjectionResult = ResourceValueMapper.project(ResourceValueMapper.discover(resources), resources, contracts, catalog),
    ): List<ValueProblem> {
        val problems = mutableListOf<ValueProblem>()
        resources.filterKeys { it in affected }.forEach { (id, record) ->
            when (val structural = record.validateStructure(catalog)) {
                StructuralResult.VALID -> Unit
                is StructuralResult.InvalidWrapper -> problems += structural.value.map { it.on(id) }
                else -> unknownVariant(structural)
            }
        }
        val affectedLocations =
            ResourceValueMapper
                .discover(resources)
                .filter { it.source in affected || it.target.resource in affected }
                .mapTo(hashSetOf()) { it.id.location }
        problems += projection.problems.filter { it.location in affectedLocations }
        validateOwnership(projection.projections, contracts, affected, problems)
        validateRealmStructure(before, resources, affected, projection.projections, contracts, catalog, problems)
        validateCardinality(projection.projections, contracts, affected, problems)
        validateAcyclic(projection.projections, contracts, affected, problems)
        return problems
    }
}

private fun validateOwnership(
    projections: List<LinkProjection>,
    contracts: List<RelationContract>,
    affected: Set<ResourceId>,
    problems: MutableList<ValueProblem>,
) {
    val ownership =
        contracts.filter { it.ownsResources }.mapTo(hashSetOf(), RelationContract::id)
    val owned = projections.filter { it.contract in ownership }.groupBy { it.second }
    owned
        .filterValues { links -> links.size > 1 && links.any { it.first in affected || it.second in affected } }
        .forEach { (resource, _) -> problems += problem(resource, "multiple_immediate_owners") }
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
    projections: List<LinkProjection>,
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
    val owned = projections.filter { projection -> ownership.any { it.id == projection.contract } }.mapTo(hashSetOf()) { it.second }

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
        .filter { id -> resources[id]?.let { !it.isRealmRoot() && it.isOwnable() } == true && id !in owned }
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

private fun validateCardinality(
    projections: List<LinkProjection>,
    contracts: List<RelationContract>,
    affected: Set<ResourceId>,
    problems: MutableList<ValueProblem>,
) {
    val byContract = projections.groupBy { it.contract }
    contracts.forEach { contract ->
        val links = byContract[contract.id].orEmpty()
        if (contract.first.cardinality == EndpointCardinality.ONE) {
            links
                .groupBy { it.second }
                .filterValues { grouped -> grouped.size > 1 && grouped.any { it.first in affected || it.second in affected } }
                .forEach { (resource, _) ->
                    problems += problem(resource, "first_endpoint_cardinality_exceeded")
                }
        }
        if (contract.second.cardinality == EndpointCardinality.ONE) {
            links
                .groupBy { it.first }
                .filterValues { grouped -> grouped.size > 1 && grouped.any { it.first in affected || it.second in affected } }
                .forEach { (resource, _) ->
                    problems += problem(resource, "second_endpoint_cardinality_exceeded")
                }
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
    projections: List<LinkProjection>,
    contracts: List<RelationContract>,
    affected: Set<ResourceId>,
    problems: MutableList<ValueProblem>,
) {
    val byContract = projections.groupBy { it.contract }
    contracts.filter { it.isAcyclic }.forEach { contract ->
        val next = byContract[contract.id].orEmpty().groupBy({ it.first }, { it.second })
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
                next[id].orEmpty().forEach { stack.addLast(it to false) }
            }
        }
    }
}
