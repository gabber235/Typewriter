package com.typewritermc.realm.routes

import com.typewritermc.authoring.AuthoringChangeSummary
import com.typewritermc.realm.repository.AuthoringPresentationChange
import com.typewritermc.realm.repository.AuthoringPresentationMaterializer
import com.typewritermc.realm.repository.AuthoringWorkingGraph
import com.typewritermc.realm.repository.ResourceValueMapper
import com.typewritermc.types.RelationDefinition
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypePrototypeRegistry

/** Materializes changed subjects through the same registered projector used by graph snapshots. */
internal fun registeredAuthoringPresentationMaterializer(
    prototypes: TypePrototypeRegistry,
    relations: () -> List<RelationDefinition>,
    projector: AuthoringPresentationProjector,
): AuthoringPresentationMaterializer =
    AuthoringPresentationMaterializer { before, proposed, change ->
        val mapper = ResourceValueMapper(prototypes, relations())
        val affected = projector.affectedResources(before = before, proposed = proposed, change = change)
        affected
            .sortedBy(ResourceId::value)
            .map { id ->
                val stored = proposed.resources[id]
                if (stored == null) {
                    AuthoringPresentationChange.Remove(id)
                } else {
                    val resource =
                        com.typewritermc.realm.repository.AuthoringGraphResource(
                            id = stored.id,
                            definition = stored.definition,
                            content = mapper.hydrate(stored, proposed.relations.values),
                        )
                    val subject = projector.project(resource, graph = proposed)
                    AuthoringPresentationChange.Upsert(
                        resource = id,
                        subject = subject,
                    )
                }
            }
    }
