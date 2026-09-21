package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.AuthoringBatchResult
import com.typewritermc.realm.repository.AuthoringChanged
import com.typewritermc.realm.repository.AuthoringDiagnostic
import com.typewritermc.realm.repository.AuthoringPreviewResult
import com.typewritermc.realm.repository.GraphEdgeChange
import com.typewritermc.realm.repository.GraphResourceChange
import com.typewritermc.realm.repository.PropertyConflict
import com.typewritermc.types.skir.SkirDataValueCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.library.v1.authoring.ApplyAuthoringBatchResponse
import skirout.library.v1.authoring.AuthoringConflict
import skirout.library.v1.authoring.AuthoringEdgeChange
import skirout.library.v1.authoring.AuthoringInvalid
import skirout.library.v1.authoring.AuthoringPreview
import skirout.library.v1.authoring.AuthoringResourceChange
import skirout.library.v1.authoring.PreviewAuthoringBatchResponse
import skirout.library.v1.authoring.PropertyConflict as WireConflict

internal fun AuthoringBatchResult.toWireResponse(): ApplyAuthoringBatchResponse =
    when (this) {
        is AuthoringBatchResult.Applied -> {
            ApplyAuthoringBatchResponse.AppliedWrapper(change.toWire())
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
                            skirout.library.v1.authoring
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

internal fun AuthoringChanged.toWire(): skirout.library.v1.authoring.AuthoringChanged =
    skirout.library.v1.authoring.AuthoringChanged(
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
    )

private fun PropertyConflict.toWire(): WireConflict =
    WireConflict(
        resource = resource.toWire(),
        path = path.toWirePath(),
        expected = expected?.let { SkirDataValueCodec.encode(it).getOrThrow() },
        actual = actual?.let { SkirDataValueCodec.encode(it).getOrThrow() },
    )

internal fun AuthoringDiagnostic.toWire(): skirout.library.v1.authoring.AuthoringDiagnostic =
    skirout.library.v1.authoring.AuthoringDiagnostic(
        code = code,
        message = message,
        resource = resource?.toWire(),
        path = path?.toWirePath(),
    )
