package com.typewritermc.realm.authoring

import skirout.editor.v1.authoring.AuthoringObservationId
import skirout.editor.v1.authoring.AuthoringResource
import skirout.editor.v1.authoring.AuthoringState
import skirout.editor.v1.checking.FindingSet
import skirout.editor.v1.checking.FindingStatus

/** The saved state of this view as editors receive it, with [findings] marked current or outdated against it. */
internal fun AuthoringView.savedState(findings: List<FindingSet>): AuthoringState =
    AuthoringState(
        generation = catalog.generation,
        resources = resources.entries.sortedBy { it.key.value }.map { (id, record) -> AuthoringResource(id = id, content = record) },
        links = ResourceValueMapper.project(links.values, resources, catalog.relations).projections,
        findings = findings.map { set -> set.copy(status = if (judges(set)) FindingStatus.CURRENT else FindingStatus.OUTDATED) },
        confirmedObservation = AuthoringObservationId(value = observationId),
    )

/** Whether [set] was checked against this view's catalog and the values it read are still saved. */
private fun AuthoringView.judges(set: FindingSet): Boolean =
    set.ticket.catalog == catalog.generation && values.conflicts(set.expectations).isEmpty()
