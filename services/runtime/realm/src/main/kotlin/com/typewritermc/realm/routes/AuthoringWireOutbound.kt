package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.AuthoringBatchResult
import com.typewritermc.realm.repository.AuthoringChanged
import com.typewritermc.realm.repository.AuthoringDiagnostic
import com.typewritermc.realm.repository.AuthoringPreviewResult
import com.typewritermc.realm.repository.GraphEdgeChange
import com.typewritermc.realm.repository.GraphResourceChange
import com.typewritermc.realm.repository.PropertyConflict
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypePrototypeRegistry
import com.typewritermc.types.skir.SkirDataValueCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.authoring.ApplyAuthoringBatchResponse
import skirout.editor.v1.authoring.AuthoringConflict
import skirout.editor.v1.authoring.AuthoringEdgeChange
import skirout.editor.v1.authoring.AuthoringInvalid
import skirout.editor.v1.authoring.AuthoringPreview
import skirout.editor.v1.authoring.AuthoringResourceChange
import skirout.editor.v1.authoring.PresentationSubjectChange
import skirout.editor.v1.authoring.PreviewAuthoringBatchResponse
import skirout.editor.v1.authoring.PropertyConflict as WireConflict

internal fun AuthoringBatchResult.toWireResponse(prototypes: TypePrototypeRegistry): ApplyAuthoringBatchResponse =
    when (this) {
        is AuthoringBatchResult.Applied -> {
            ApplyAuthoringBatchResponse.AppliedWrapper(change.toWire(prototypes))
        }

        is AuthoringBatchResult.Conflict -> {
            ApplyAuthoringBatchResponse.ConflictWrapper(
                AuthoringConflict(conflicts = conflicts.map(PropertyConflict::toWire)),
            )
        }

        is AuthoringBatchResult.Invalid -> {
            ApplyAuthoringBatchResponse.InvalidWrapper(
                AuthoringInvalid(diagnostics = diagnostics.map(AuthoringDiagnostic::toWire)),
            )
        }

        is AuthoringBatchResult.CatalogChanged -> {
            ApplyAuthoringBatchResponse.createCatalogChanged(
                actualGeneration =
                    skirout.editor.v1.type_catalog
                        .CatalogGeneration(value = actualGeneration),
            )
        }
    }

internal fun AuthoringPreviewResult.toWireResponse(): PreviewAuthoringBatchResponse =
    when (this) {
        is AuthoringPreviewResult.Valid -> {
            PreviewAuthoringBatchResponse.ValidWrapper(
                AuthoringPreview(
                    affectedResources = affectedResources.map { it.toWire() },
                    affectedEdges =
                        affectedEdges.map {
                            skirout.editor.v1.authoring
                                .AuthoringEdgeId(value = it)
                        },
                ),
            )
        }

        is AuthoringPreviewResult.Conflict -> {
            PreviewAuthoringBatchResponse.ConflictWrapper(
                AuthoringConflict(conflicts = conflicts.map(PropertyConflict::toWire)),
            )
        }

        is AuthoringPreviewResult.Invalid -> {
            PreviewAuthoringBatchResponse.InvalidWrapper(
                AuthoringInvalid(diagnostics = diagnostics.map(AuthoringDiagnostic::toWire)),
            )
        }

        is AuthoringPreviewResult.CatalogChanged -> {
            PreviewAuthoringBatchResponse.createCatalogChanged(
                actualGeneration =
                    skirout.editor.v1.type_catalog
                        .CatalogGeneration(value = actualGeneration),
            )
        }
    }

internal fun AuthoringChanged.toWire(prototypes: TypePrototypeRegistry): skirout.editor.v1.authoring.AuthoringChanged =
    skirout.editor.v1.authoring.AuthoringChanged(
        generation =
            skirout.editor.v1.type_catalog
                .CatalogGeneration(value = generation),
        sequence = sequence,
        batchId = batchId.value,
        resources =
            resources.map { change ->
                when (change) {
                    is GraphResourceChange.Upsert -> AuthoringResourceChange.UpsertWrapper(change.resource.toWire())
                    is GraphResourceChange.Remove -> AuthoringResourceChange.RemoveWrapper(change.id.toWire())
                }
            },
        edges =
            edges.map { change ->
                when (change) {
                    is GraphEdgeChange.Upsert -> {
                        AuthoringEdgeChange.UpsertWrapper(change.edge.toWire())
                    }

                    is GraphEdgeChange.Remove -> {
                        AuthoringEdgeChange.createRemove(value = change.id)
                    }
                }
            },
        presentations =
            presentations.map { change ->
                when (change) {
                    is com.typewritermc.realm.repository.AuthoringPresentationChange.Upsert -> {
                        PresentationSubjectChange.createUpsert(
                            resource = change.resource.toWire(),
                            subject = change.subject.toWire(prototypes),
                        )
                    }

                    is com.typewritermc.realm.repository.AuthoringPresentationChange.Remove -> {
                        PresentationSubjectChange.createRemove(value = change.resource.value)
                    }
                }
            },
        compilationImpact = compilationImpact.map { it.toWire() },
    )

private fun com.typewritermc.authoring.AuthoringPresentationSubject.toWire(prototypes: TypePrototypeRegistry) =
    skirout.editor.v1.authoring.PresentationSubject(
        content = content.toWire(),
        descriptor = prototypes.encode(descriptor).toWire(),
        identity = prototypes.encode(identity).toWire(),
        resource = resource.toWire(),
        definition = definition.toWire(),
        ownerPath = ownerPath.map(ResourceId::toWire),
    )

private fun com.typewritermc.engine.CompilationRoot.toWire() =
    skirout.editor.v1.compiled_content.CompilationRoot(
        projection =
            skirout.editor.v1.compiled_content
                .CompilationProjectionId(value = projection.value),
        resource =
            skirout.editor.v1.type_catalog
                .ResourceId(value = resource.value),
    )

private fun PropertyConflict.toWire(): WireConflict =
    WireConflict(
        resource = resource.toWire(),
        path = path.toWirePath(),
        expected = expected?.let { SkirDataValueCodec.encode(it).getOrThrow() },
        actual = actual?.let { SkirDataValueCodec.encode(it).getOrThrow() },
    )

internal fun AuthoringDiagnostic.toWire(): skirout.editor.v1.authoring.AuthoringDiagnostic =
    skirout.editor.v1.authoring.AuthoringDiagnostic(
        code = code,
        message = message,
        resource = resource?.toWire(),
        path = path?.toWirePath(),
    )
