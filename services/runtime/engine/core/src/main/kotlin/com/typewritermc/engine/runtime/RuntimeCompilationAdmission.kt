package com.typewritermc.engine.runtime

import com.typewritermc.authoring.descendants
import com.typewritermc.engine.dataValue
import com.typewritermc.engine.relation
import com.typewritermc.types.RelationContract
import com.typewritermc.types.actualType
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.runtimeDefinitions
import com.typewritermc.types.ownsResources
import com.typewritermc.types.use
import skirout.editor.v1.compiled_content.RuntimeCompilationFacts
import skirout.editor.v1.type_catalog.DataValue

internal fun RuntimeCompilationFacts.requireAccepted(
    checked: CheckedCatalog,
    relations: Collection<RelationContract>,
) {
    val seeds =
        resources.flatMap { resource ->
            sequenceOf(resource.actualType) +
                resource.dataValue.descendants().mapNotNull { located ->
                    (located.value as? DataValue.NamedWrapper)?.actualType
                }
        }
    val expectedTypes = checked.runtimeDefinitions(seeds.map { it.use }).associateBy { type -> type.id }
    require(types.size == types.map { type -> type.id }.toSet().size) {
        "Compiled runtime facts contain duplicate type declarations."
    }
    require(types.associateBy { type -> type.id } == expectedTypes) {
        "Compiled runtime type facts do not equal the accepted declaration closure."
    }

    val expectedRelations =
        edges.mapTo(linkedSetOf()) { edge -> edge.relation }
    val relationIds =
        this.relations
            .map { fact -> fact.relation }
    require(this.relations.size == relationIds.toSet().size) {
        "Compiled runtime facts contain duplicate relations."
    }
    require(relationIds.toSet() == expectedRelations) {
        "Compiled relation facts do not cover the incident runtime relations."
    }

    types.forEach { compiled ->
        val accepted = checked.declaration(compiled.id)
        require(accepted is Resolution.Ready && accepted.value == compiled) {
            "Compiled type meaning differs from the accepted runtime catalog: ${compiled.id}."
        }
    }
    val acceptedRelations = relations.associateBy(RelationContract::id)
    this.relations.forEach { fact ->
        val accepted =
            requireNotNull(acceptedRelations[fact.relation]) {
                "Compiled relation is unavailable in the runtime catalog: ${fact.relation.value}."
            }
        require(fact.ownsResources == accepted.ownsResources) {
            "Compiled relation ownership differs from the accepted runtime catalog."
        }
    }
    resources.forEach { resource ->
        require(checked.resolve(resource.actualType.use) is Resolution.Ready) {
            "Compiled resource type is unavailable in the accepted runtime catalog."
        }
    }
}
