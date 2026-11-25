package com.typewritermc.realm.testing

import com.typewritermc.formula.graph.GraphListener
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.GraphWorkRecorder
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.authoring.RealmServices
import com.typewritermc.realm.catalog.AuthoringCatalogLease
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.kernel.v1.resource_id.ResourceId

/**
 * A view store of [catalog] seeded with [resources], whose queries read [services]. What its operations' graph reads
 * did goes to [recorder], which records nothing unless a test reads it; what its live graph computes reaches no one.
 */
fun viewStore(
    catalog: AuthoringCatalogLease,
    resources: Map<ResourceId, AuthoringRecord>,
    services: RealmServices = RealmServices(),
    recorder: GraphWorkRecorder = UNOBSERVED_GRAPH_WORK,
): InMemoryAuthoringViewStore = InMemoryAuthoringViewStore(catalog, AuthoringSeed(resources), services, GraphListener.NONE, recorder)

private val UNOBSERVED_GRAPH_WORK = GraphWorkRecorder { _, _ -> }
