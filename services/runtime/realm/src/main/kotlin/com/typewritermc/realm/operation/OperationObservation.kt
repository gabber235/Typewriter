package com.typewritermc.realm.operation

import com.typewritermc.realm.authoring.AuthoringLease
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.authoring.ResourceValueMapper
import com.typewritermc.realm.catalog.over
import com.typewritermc.realm.edit.AuthoringSnapshotValidator
import com.typewritermc.realm.edit.planned
import com.typewritermc.types.immutableMapCopy
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.kernel.v1.resource_id.ResourceId

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
    val resources = (root.resources + upserts - removals).immutableMapCopy()
    val links = ResourceValueMapper.discover(resources)
    // The code catalog plus what this draft declares, judged by the same rule as a commit with root as the saved side.
    val catalog = root.catalog.over(resources)
    val projected = ResourceValueMapper.project(links, resources, root.catalog.relations, catalog.checked)
    val problems =
        AuthoringSnapshotValidator(catalog.checked, root.catalog.checked, root.catalog.relations)
            .validate(root.resources, resources, upserts.keys + removals, projected.planned(links, upserts.keys + removals)) { id ->
                root.judged(id).fit
            }
    require(problems.isEmpty()) { "An overlay violates resource structure or relation policy: $problems" }
    return AuthoringView(
        catalog,
        resources,
        links.associateBy { it.id }.immutableMapCopy(),
        root.observationId,
    )
}
