package com.typewritermc.realm.authoring

import com.typewritermc.formula.graph.GraphWork
import skirout.editor.v1.authoring.AuthoringObservationId
import skirout.editor.v1.authoring.AuthoringResource
import skirout.editor.v1.authoring.AuthoringState
import skirout.editor.v1.checking.FindingSet

/**
 * The saved state of this view as editors receive it, with the [findings] it reports judged against it alone; judging
 * counts its graph work on [work].
 */
internal fun AuthoringView.savedState(
    findings: List<FindingSet>,
    work: GraphWork,
): AuthoringState =
    AuthoringState(
        generation = catalog.generation,
        resources = resources.entries.sortedBy { it.key.value }.map { (id, record) -> AuthoringResource(id = id, content = record) },
        links = ResourceValueMapper.project(links.values, resources, catalog.relations).projections,
        findings = findings.forReply { it.judgedAgainst(this, work) },
        confirmedObservation = AuthoringObservationId(value = observationId),
    )
