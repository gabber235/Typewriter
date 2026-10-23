package com.typewritermc.realm.operation

import com.typewritermc.authoring.validateStructure
import com.typewritermc.realm.authoring.AuthoringLease
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.authoring.ResourceValueMapper
import com.typewritermc.realm.edit.AuthoringMutationPlanner
import com.typewritermc.types.immutableMapCopy
import skirout.editor.v1.diagnostic.StructuralResult
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.ResourceId

/** Signals that a caller must refresh saved state before inspecting its proposed overlay. */
internal class StaleOperationObservation(
    val actual: String,
) : IllegalStateException("The saved authoring observation changed")

/** Materializes one caller owned working baseline while the saved view's catalog remains leased. */
internal fun AuthoringLease.operationObservation(
    confirmedObservation: String,
    upserts: Map<ResourceId, AuthoringRecord>,
    removals: Set<ResourceId>,
): AuthoringView {
    if (confirmedObservation != root.observationId) throw StaleOperationObservation(root.observationId)
    require(upserts.size + removals.size <= 100_000) { "The operation overlay is too large" }
    require(upserts.keys.intersect(removals).isEmpty()) { "An overlay cannot replace and remove the same resource" }
    require((upserts.keys + removals).all { it.value.isNotBlank() }) { "An overlay resource identity is empty" }
    require(removals.all { it in root.resources }) { "An overlay removes an unknown resource" }
    upserts.forEach { (_, record) ->
        val structural = record.validateStructure(root.catalog.checked)
        require(structural is StructuralResult.VALID) { "An overlay resource has invalid authored structure: $structural" }
    }
    val resources = (root.resources + upserts - removals).immutableMapCopy()
    val links = ResourceValueMapper.discover(resources)
    val projected = ResourceValueMapper.project(links, resources, root.catalog.relations, root.catalog.checked)
    val problems =
        AuthoringMutationPlanner(root.catalog.checked, root.catalog.relations)
            .validateSnapshot(root.resources, resources, upserts.keys + removals, projected)
    require(problems.isEmpty()) { "An overlay violates resource structure or relation policy: $problems" }
    return AuthoringView(
        root.catalog,
        resources,
        links.associateBy { it.id }.immutableMapCopy(),
        root.observationId,
    )
}
