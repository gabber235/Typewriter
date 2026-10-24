package com.typewritermc.protocol.transport.generated

import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.realmTemplate
import com.typewritermc.services.libs.communicator.contract.OperationName
import com.typewritermc.services.libs.communicator.contract.ResponseClassification
import com.typewritermc.services.libs.communicator.contract.ResponsePolicy
import com.typewritermc.services.libs.communicator.skir.skirEventContract
import com.typewritermc.services.libs.communicator.skir.skirScatterContract
import com.typewritermc.services.libs.communicator.skir.skirUnaryContract
import com.typewritermc.services.libs.communicator.skir.skirWatchContract
import skirout.editor.v1.authoring.CommitPreparedEdit
import skirout.editor.v1.authoring.PrepareTypeArgumentChange
import skirout.editor.v1.authoring.PreviewTypeArgumentChange
import skirout.editor.v1.authoring.QueryAuthoringState
import skirout.editor.v1.authoring.SearchAuthoring
import skirout.editor.v1.capability.InvokeRealmCommand
import skirout.editor.v1.capability.InvokeRealmComputation
import skirout.editor.v1.catalog.FetchEditorCatalog
import skirout.editor.v1.catalog.PrepareValue
import skirout.editor.v1.catalog.WatchEditorCatalog
import skirout.editor.v1.compiled_content.QueryCompiledResourceStatus
import skirout.editor.v1.compiled_content.QueryPublishedContent
import skirout.editor.v1.publication.PublishAuthoring
import skirout.editor.v1.publication.QueryPublicationView
import skirout.editor.v1.publication.WatchPublication
import skirout.editor.v1.resource_operations.PrepareAuthoringAction
import skirout.editor.v1.resource_operations.ResolveDropCandidates
import skirout.editor.v1.resource_operations.ResolveResourceOperations
import skirout.editor.v1.search.CancelRealmPresentationSearch
import skirout.editor.v1.search.WatchRealmPresentationSearch
import skirout.service.v1.artifact.BeginArtifactBlobWrite
import skirout.service.v1.artifact.CompleteArtifactBlobWrite
import skirout.service.v1.artifact.FetchArtifactBlobMetadata
import skirout.service.v1.artifact.FetchSharedArtifactCatalog
import skirout.service.v1.artifact.PublishSharedArtifact
import skirout.service.v1.artifact.ReadArtifactBlob
import skirout.service.v1.artifact.WriteArtifactBlobChunk
import skirout.service.v1.rollout.ApplyRolloutCommand
import skirout.service.v1.rollout.ProbeRealmHosts
import skirout.service.v1.rollout.QueryParticipantStatus

private val catalogFetchResultPolicy = ResponsePolicy<skirout.editor.v1.catalog.CatalogFetchResult>(
    skirout.editor.v1.catalog.CatalogFetchResult.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.editor.v1.catalog.CatalogFetchResult.Kind.CATALOG_WRAPPER -> ResponseClassification.success("catalog")
        skirout.editor.v1.catalog.CatalogFetchResult.Kind.GENERATION_CHANGED_ERROR_WRAPPER -> ResponseClassification.domainError("generation-changed-error")
        skirout.editor.v1.catalog.CatalogFetchResult.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val watchEditorCatalogResponsePolicy = ResponsePolicy<skirout.editor.v1.catalog.WatchEditorCatalogResponse>(
    skirout.editor.v1.catalog.WatchEditorCatalogResponse.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.editor.v1.catalog.WatchEditorCatalogResponse.Kind.INVALIDATED_WRAPPER -> ResponseClassification.success("invalidated")
        skirout.editor.v1.catalog.WatchEditorCatalogResponse.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val prepareValueResultPolicy = ResponsePolicy<skirout.editor.v1.catalog.PrepareValueResult>(
    skirout.editor.v1.catalog.PrepareValueResult.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.editor.v1.catalog.PrepareValueResult.Kind.READY_WRAPPER -> ResponseClassification.success("ready")
        skirout.editor.v1.catalog.PrepareValueResult.Kind.NEEDS_INPUT_WRAPPER -> ResponseClassification.success("needs-input")
        skirout.editor.v1.catalog.PrepareValueResult.Kind.UNAVAILABLE_ERROR_WRAPPER -> ResponseClassification.domainError("unavailable-error")
        skirout.editor.v1.catalog.PrepareValueResult.Kind.CATALOG_CHANGED_ERROR_WRAPPER -> ResponseClassification.domainError("catalog-changed-error")
        skirout.editor.v1.catalog.PrepareValueResult.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val realmPresentationSearchUpdatePolicy = ResponsePolicy<skirout.editor.v1.search.RealmPresentationSearchUpdate>(
    skirout.editor.v1.search.RealmPresentationSearchUpdate.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.editor.v1.search.RealmPresentationSearchUpdate.Kind.SNAPSHOT_WRAPPER -> ResponseClassification.success("snapshot")
        skirout.editor.v1.search.RealmPresentationSearchUpdate.Kind.UNAVAILABLE_ERROR_WRAPPER -> ResponseClassification.domainError("unavailable-error")
        skirout.editor.v1.search.RealmPresentationSearchUpdate.Kind.STALE_OBSERVATION_ERROR_WRAPPER -> ResponseClassification.domainError("stale-observation-error")
        skirout.editor.v1.search.RealmPresentationSearchUpdate.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val cancelRealmPresentationSearchResultPolicy = ResponsePolicy<skirout.editor.v1.search.CancelRealmPresentationSearchResult>(
    skirout.editor.v1.search.CancelRealmPresentationSearchResult.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.editor.v1.search.CancelRealmPresentationSearchResult.Kind.CANCELED_CONST -> ResponseClassification.success("canceled")
        skirout.editor.v1.search.CancelRealmPresentationSearchResult.Kind.NOT_FOUND_ERROR_CONST -> ResponseClassification.domainError("not-found-error")
        skirout.editor.v1.search.CancelRealmPresentationSearchResult.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val computationResultPolicy = ResponsePolicy<skirout.editor.v1.capability.ComputationResult>(
    skirout.editor.v1.capability.ComputationResult.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.editor.v1.capability.ComputationResult.Kind.SUCCESS_WRAPPER -> ResponseClassification.success("success")
        skirout.editor.v1.capability.ComputationResult.Kind.INVALID_ERROR_WRAPPER -> ResponseClassification.domainError("invalid-error")
        skirout.editor.v1.capability.ComputationResult.Kind.UNAVAILABLE_ERROR_WRAPPER -> ResponseClassification.domainError("unavailable-error")
        skirout.editor.v1.capability.ComputationResult.Kind.PERMISSION_DENIED_ERROR_WRAPPER -> ResponseClassification.domainError("permission-denied-error")
        skirout.editor.v1.capability.ComputationResult.Kind.STALE_GENERATION_ERROR_WRAPPER -> ResponseClassification.domainError("stale-generation-error")
        skirout.editor.v1.capability.ComputationResult.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val commandResultPolicy = ResponsePolicy<skirout.editor.v1.capability.CommandResult>(
    skirout.editor.v1.capability.CommandResult.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.editor.v1.capability.CommandResult.Kind.SUCCESS_WRAPPER -> ResponseClassification.success("success")
        skirout.editor.v1.capability.CommandResult.Kind.INVALID_ERROR_WRAPPER -> ResponseClassification.domainError("invalid-error")
        skirout.editor.v1.capability.CommandResult.Kind.UNAVAILABLE_ERROR_WRAPPER -> ResponseClassification.domainError("unavailable-error")
        skirout.editor.v1.capability.CommandResult.Kind.PERMISSION_DENIED_ERROR_WRAPPER -> ResponseClassification.domainError("permission-denied-error")
        skirout.editor.v1.capability.CommandResult.Kind.STALE_GENERATION_ERROR_WRAPPER -> ResponseClassification.domainError("stale-generation-error")
        skirout.editor.v1.capability.CommandResult.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val resolveResourceOperationsResultPolicy = ResponsePolicy<skirout.editor.v1.resource_operations.ResolveResourceOperationsResult>(
    skirout.editor.v1.resource_operations.ResolveResourceOperationsResult.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.editor.v1.resource_operations.ResolveResourceOperationsResult.Kind.RESOLVED_WRAPPER -> ResponseClassification.success("resolved")
        skirout.editor.v1.resource_operations.ResolveResourceOperationsResult.Kind.STALE_OBSERVATION_ERROR_WRAPPER -> ResponseClassification.domainError("stale-observation-error")
        skirout.editor.v1.resource_operations.ResolveResourceOperationsResult.Kind.INVALID_ERROR_WRAPPER -> ResponseClassification.domainError("invalid-error")
        skirout.editor.v1.resource_operations.ResolveResourceOperationsResult.Kind.CATALOG_CHANGED_ERROR_WRAPPER -> ResponseClassification.domainError("catalog-changed-error")
        skirout.editor.v1.resource_operations.ResolveResourceOperationsResult.Kind.PERMISSION_DENIED_ERROR_WRAPPER -> ResponseClassification.domainError("permission-denied-error")
        skirout.editor.v1.resource_operations.ResolveResourceOperationsResult.Kind.FAILED_ERROR_WRAPPER -> ResponseClassification.domainError("failed-error")
        skirout.editor.v1.resource_operations.ResolveResourceOperationsResult.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val resolveDropCandidatesResultPolicy = ResponsePolicy<skirout.editor.v1.resource_operations.ResolveDropCandidatesResult>(
    skirout.editor.v1.resource_operations.ResolveDropCandidatesResult.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.editor.v1.resource_operations.ResolveDropCandidatesResult.Kind.RESOLVED_WRAPPER -> ResponseClassification.success("resolved")
        skirout.editor.v1.resource_operations.ResolveDropCandidatesResult.Kind.STALE_OBSERVATION_ERROR_WRAPPER -> ResponseClassification.domainError("stale-observation-error")
        skirout.editor.v1.resource_operations.ResolveDropCandidatesResult.Kind.INVALID_ERROR_WRAPPER -> ResponseClassification.domainError("invalid-error")
        skirout.editor.v1.resource_operations.ResolveDropCandidatesResult.Kind.CATALOG_CHANGED_ERROR_WRAPPER -> ResponseClassification.domainError("catalog-changed-error")
        skirout.editor.v1.resource_operations.ResolveDropCandidatesResult.Kind.PERMISSION_DENIED_ERROR_WRAPPER -> ResponseClassification.domainError("permission-denied-error")
        skirout.editor.v1.resource_operations.ResolveDropCandidatesResult.Kind.FAILED_ERROR_WRAPPER -> ResponseClassification.domainError("failed-error")
        skirout.editor.v1.resource_operations.ResolveDropCandidatesResult.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val authoringActionResultPolicy = ResponsePolicy<skirout.editor.v1.resource_operations.AuthoringActionResult>(
    skirout.editor.v1.resource_operations.AuthoringActionResult.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.editor.v1.resource_operations.AuthoringActionResult.Kind.NEEDS_INPUT_WRAPPER -> ResponseClassification.success("needs-input")
        skirout.editor.v1.resource_operations.AuthoringActionResult.Kind.PREVIEW_WRAPPER -> ResponseClassification.success("preview")
        skirout.editor.v1.resource_operations.AuthoringActionResult.Kind.STALE_OBSERVATION_ERROR_WRAPPER -> ResponseClassification.domainError("stale-observation-error")
        skirout.editor.v1.resource_operations.AuthoringActionResult.Kind.INVALID_ERROR_WRAPPER -> ResponseClassification.domainError("invalid-error")
        skirout.editor.v1.resource_operations.AuthoringActionResult.Kind.UNAVAILABLE_ERROR_WRAPPER -> ResponseClassification.domainError("unavailable-error")
        skirout.editor.v1.resource_operations.AuthoringActionResult.Kind.CATALOG_CHANGED_ERROR_WRAPPER -> ResponseClassification.domainError("catalog-changed-error")
        skirout.editor.v1.resource_operations.AuthoringActionResult.Kind.PERMISSION_DENIED_ERROR_WRAPPER -> ResponseClassification.domainError("permission-denied-error")
        skirout.editor.v1.resource_operations.AuthoringActionResult.Kind.FAILED_ERROR_WRAPPER -> ResponseClassification.domainError("failed-error")
        skirout.editor.v1.resource_operations.AuthoringActionResult.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val queryAuthoringStateResponsePolicy = ResponsePolicy<skirout.editor.v1.authoring.QueryAuthoringStateResponse>(
    skirout.editor.v1.authoring.QueryAuthoringStateResponse.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.editor.v1.authoring.QueryAuthoringStateResponse.Kind.STATE_WRAPPER -> ResponseClassification.success("state")
        skirout.editor.v1.authoring.QueryAuthoringStateResponse.Kind.CATALOG_CHANGED_ERROR_WRAPPER -> ResponseClassification.domainError("catalog-changed-error")
        skirout.editor.v1.authoring.QueryAuthoringStateResponse.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val commitPreparedEditResponsePolicy = ResponsePolicy<skirout.editor.v1.authoring.CommitPreparedEditResponse>(
    skirout.editor.v1.authoring.CommitPreparedEditResponse.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.editor.v1.authoring.CommitPreparedEditResponse.Kind.COMMITTED_CONST -> ResponseClassification.success("committed")
        skirout.editor.v1.authoring.CommitPreparedEditResponse.Kind.CONFLICT_ERROR_WRAPPER -> ResponseClassification.domainError("conflict-error")
        skirout.editor.v1.authoring.CommitPreparedEditResponse.Kind.REJECTED_ERROR_WRAPPER -> ResponseClassification.domainError("rejected-error")
        skirout.editor.v1.authoring.CommitPreparedEditResponse.Kind.CATALOG_CHANGED_ERROR_WRAPPER -> ResponseClassification.domainError("catalog-changed-error")
        skirout.editor.v1.authoring.CommitPreparedEditResponse.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val previewTypeArgumentChangeResponsePolicy = ResponsePolicy<skirout.editor.v1.authoring.PreviewTypeArgumentChangeResponse>(
    skirout.editor.v1.authoring.PreviewTypeArgumentChangeResponse.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.editor.v1.authoring.PreviewTypeArgumentChangeResponse.Kind.READY_WRAPPER -> ResponseClassification.success("ready")
        skirout.editor.v1.authoring.PreviewTypeArgumentChangeResponse.Kind.INVALID_ARGUMENTS_ERROR_WRAPPER -> ResponseClassification.domainError("invalid-arguments-error")
        skirout.editor.v1.authoring.PreviewTypeArgumentChangeResponse.Kind.INCOMPLETE_WRAPPER -> ResponseClassification.success("incomplete")
        skirout.editor.v1.authoring.PreviewTypeArgumentChangeResponse.Kind.REJECTED_ERROR_WRAPPER -> ResponseClassification.domainError("rejected-error")
        skirout.editor.v1.authoring.PreviewTypeArgumentChangeResponse.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val prepareTypeArgumentChangeResponsePolicy = ResponsePolicy<skirout.editor.v1.authoring.PrepareTypeArgumentChangeResponse>(
    skirout.editor.v1.authoring.PrepareTypeArgumentChangeResponse.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.editor.v1.authoring.PrepareTypeArgumentChangeResponse.Kind.PREPARED_WRAPPER -> ResponseClassification.success("prepared")
        skirout.editor.v1.authoring.PrepareTypeArgumentChangeResponse.Kind.NEEDS_INPUT_WRAPPER -> ResponseClassification.success("needs-input")
        skirout.editor.v1.authoring.PrepareTypeArgumentChangeResponse.Kind.REJECTED_ERROR_WRAPPER -> ResponseClassification.domainError("rejected-error")
        skirout.editor.v1.authoring.PrepareTypeArgumentChangeResponse.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val searchAuthoringResponsePolicy = ResponsePolicy<skirout.editor.v1.authoring.SearchAuthoringResponse>(
    skirout.editor.v1.authoring.SearchAuthoringResponse.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.editor.v1.authoring.SearchAuthoringResponse.Kind.SUCCESS_WRAPPER -> ResponseClassification.success("success")
        skirout.editor.v1.authoring.SearchAuthoringResponse.Kind.INVALID_ERROR_WRAPPER -> ResponseClassification.domainError("invalid-error")
        skirout.editor.v1.authoring.SearchAuthoringResponse.Kind.CATALOG_CHANGED_ERROR_WRAPPER -> ResponseClassification.domainError("catalog-changed-error")
        skirout.editor.v1.authoring.SearchAuthoringResponse.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val queryPublishedContentResponsePolicy = ResponsePolicy<skirout.editor.v1.compiled_content.QueryPublishedContentResponse>(
    skirout.editor.v1.compiled_content.QueryPublishedContentResponse.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.editor.v1.compiled_content.QueryPublishedContentResponse.Kind.CONTENT_WRAPPER -> ResponseClassification.success("content")
        skirout.editor.v1.compiled_content.QueryPublishedContentResponse.Kind.ABSENT_WRAPPER -> ResponseClassification.success("absent")
        skirout.editor.v1.compiled_content.QueryPublishedContentResponse.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val queryCompiledResourceStatusResponsePolicy = ResponsePolicy<skirout.editor.v1.compiled_content.QueryCompiledResourceStatusResponse>(
    skirout.editor.v1.compiled_content.QueryCompiledResourceStatusResponse.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.editor.v1.compiled_content.QueryCompiledResourceStatusResponse.Kind.SUCCESS_WRAPPER -> ResponseClassification.success("success")
        skirout.editor.v1.compiled_content.QueryCompiledResourceStatusResponse.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val publishAuthoringResponsePolicy = ResponsePolicy<skirout.editor.v1.publication.PublishAuthoringResponse>(
    skirout.editor.v1.publication.PublishAuthoringResponse.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.editor.v1.publication.PublishAuthoringResponse.Kind.PUBLISHING_CONST -> ResponseClassification.success("publishing")
        skirout.editor.v1.publication.PublishAuthoringResponse.Kind.ACTIVATED_WRAPPER -> ResponseClassification.success("activated")
        skirout.editor.v1.publication.PublishAuthoringResponse.Kind.BLOCKED_ERROR_WRAPPER -> ResponseClassification.domainError("blocked-error")
        skirout.editor.v1.publication.PublishAuthoringResponse.Kind.INTERRUPTED_ERROR_WRAPPER -> ResponseClassification.domainError("interrupted-error")
        skirout.editor.v1.publication.PublishAuthoringResponse.Kind.NO_CHANGES_CONST -> ResponseClassification.success("no-changes")
        skirout.editor.v1.publication.PublishAuthoringResponse.Kind.CANDIDATE_CHANGED_ERROR_WRAPPER -> ResponseClassification.domainError("candidate-changed-error")
        skirout.editor.v1.publication.PublishAuthoringResponse.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val queryPublicationViewResponsePolicy = ResponsePolicy<skirout.editor.v1.publication.QueryPublicationViewResponse>(
    skirout.editor.v1.publication.QueryPublicationViewResponse.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.editor.v1.publication.QueryPublicationViewResponse.Kind.VIEW_WRAPPER -> ResponseClassification.success("view")
        skirout.editor.v1.publication.QueryPublicationViewResponse.Kind.VIEW_CHANGED_ERROR_WRAPPER -> ResponseClassification.domainError("view-changed-error")
        skirout.editor.v1.publication.QueryPublicationViewResponse.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val watchPublicationResponsePolicy = ResponsePolicy<skirout.editor.v1.publication.WatchPublicationResponse>(
    skirout.editor.v1.publication.WatchPublicationResponse.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.editor.v1.publication.WatchPublicationResponse.Kind.VIEW_CHANGED_WRAPPER -> ResponseClassification.success("view-changed")
        skirout.editor.v1.publication.WatchPublicationResponse.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val fetchSharedArtifactCatalogResponsePolicy = ResponsePolicy<skirout.service.v1.artifact.FetchSharedArtifactCatalogResponse>(
    skirout.service.v1.artifact.FetchSharedArtifactCatalogResponse.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.service.v1.artifact.FetchSharedArtifactCatalogResponse.Kind.SUCCESS_WRAPPER -> ResponseClassification.success("success")
        skirout.service.v1.artifact.FetchSharedArtifactCatalogResponse.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val publishSharedArtifactResponsePolicy = ResponsePolicy<skirout.service.v1.artifact.PublishSharedArtifactResponse>(
    skirout.service.v1.artifact.PublishSharedArtifactResponse.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.service.v1.artifact.PublishSharedArtifactResponse.Kind.PUBLISHED_WRAPPER -> ResponseClassification.success("published")
        skirout.service.v1.artifact.PublishSharedArtifactResponse.Kind.UNCHANGED_WRAPPER -> ResponseClassification.success("unchanged")
        skirout.service.v1.artifact.PublishSharedArtifactResponse.Kind.CONFLICT_ERROR_WRAPPER -> ResponseClassification.domainError("conflict-error")
        skirout.service.v1.artifact.PublishSharedArtifactResponse.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val fetchArtifactBlobMetadataResponsePolicy = ResponsePolicy<skirout.service.v1.artifact.FetchArtifactBlobMetadataResponse>(
    skirout.service.v1.artifact.FetchArtifactBlobMetadataResponse.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.service.v1.artifact.FetchArtifactBlobMetadataResponse.Kind.SUCCESS_WRAPPER -> ResponseClassification.success("success")
        skirout.service.v1.artifact.FetchArtifactBlobMetadataResponse.Kind.NOT_FOUND_ERROR_WRAPPER -> ResponseClassification.domainError("not-found-error")
        skirout.service.v1.artifact.FetchArtifactBlobMetadataResponse.Kind.INVALID_ERROR_WRAPPER -> ResponseClassification.domainError("invalid-error")
        skirout.service.v1.artifact.FetchArtifactBlobMetadataResponse.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val readArtifactBlobResponsePolicy = ResponsePolicy<skirout.service.v1.artifact.ReadArtifactBlobResponse>(
    skirout.service.v1.artifact.ReadArtifactBlobResponse.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.service.v1.artifact.ReadArtifactBlobResponse.Kind.SUCCESS_WRAPPER -> ResponseClassification.success("success")
        skirout.service.v1.artifact.ReadArtifactBlobResponse.Kind.NOT_FOUND_ERROR_WRAPPER -> ResponseClassification.domainError("not-found-error")
        skirout.service.v1.artifact.ReadArtifactBlobResponse.Kind.INVALID_ERROR_WRAPPER -> ResponseClassification.domainError("invalid-error")
        skirout.service.v1.artifact.ReadArtifactBlobResponse.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val beginArtifactBlobWriteResponsePolicy = ResponsePolicy<skirout.service.v1.artifact.BeginArtifactBlobWriteResponse>(
    skirout.service.v1.artifact.BeginArtifactBlobWriteResponse.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.service.v1.artifact.BeginArtifactBlobWriteResponse.Kind.ACCEPTED_WRAPPER -> ResponseClassification.success("accepted")
        skirout.service.v1.artifact.BeginArtifactBlobWriteResponse.Kind.INVALID_ERROR_WRAPPER -> ResponseClassification.domainError("invalid-error")
        skirout.service.v1.artifact.BeginArtifactBlobWriteResponse.Kind.CONFLICT_ERROR_WRAPPER -> ResponseClassification.domainError("conflict-error")
        skirout.service.v1.artifact.BeginArtifactBlobWriteResponse.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val writeArtifactBlobChunkResponsePolicy = ResponsePolicy<skirout.service.v1.artifact.WriteArtifactBlobChunkResponse>(
    skirout.service.v1.artifact.WriteArtifactBlobChunkResponse.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.service.v1.artifact.WriteArtifactBlobChunkResponse.Kind.ACCEPTED_WRAPPER -> ResponseClassification.success("accepted")
        skirout.service.v1.artifact.WriteArtifactBlobChunkResponse.Kind.NOT_FOUND_ERROR_WRAPPER -> ResponseClassification.domainError("not-found-error")
        skirout.service.v1.artifact.WriteArtifactBlobChunkResponse.Kind.INVALID_ERROR_WRAPPER -> ResponseClassification.domainError("invalid-error")
        skirout.service.v1.artifact.WriteArtifactBlobChunkResponse.Kind.CONFLICT_ERROR_WRAPPER -> ResponseClassification.domainError("conflict-error")
        skirout.service.v1.artifact.WriteArtifactBlobChunkResponse.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val completeArtifactBlobWriteResponsePolicy = ResponsePolicy<skirout.service.v1.artifact.CompleteArtifactBlobWriteResponse>(
    skirout.service.v1.artifact.CompleteArtifactBlobWriteResponse.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.service.v1.artifact.CompleteArtifactBlobWriteResponse.Kind.SUCCESS_WRAPPER -> ResponseClassification.success("success")
        skirout.service.v1.artifact.CompleteArtifactBlobWriteResponse.Kind.NOT_FOUND_ERROR_WRAPPER -> ResponseClassification.domainError("not-found-error")
        skirout.service.v1.artifact.CompleteArtifactBlobWriteResponse.Kind.INVALID_ERROR_WRAPPER -> ResponseClassification.domainError("invalid-error")
        skirout.service.v1.artifact.CompleteArtifactBlobWriteResponse.Kind.CONFLICT_ERROR_WRAPPER -> ResponseClassification.domainError("conflict-error")
        skirout.service.v1.artifact.CompleteArtifactBlobWriteResponse.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val probeRealmHostsResponsePolicy = ResponsePolicy<skirout.service.v1.rollout.ProbeRealmHostsResponse>(
    skirout.service.v1.rollout.ProbeRealmHostsResponse.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.service.v1.rollout.ProbeRealmHostsResponse.Kind.PRESENT_WRAPPER -> ResponseClassification.success("present")
        skirout.service.v1.rollout.ProbeRealmHostsResponse.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val applyRolloutCommandResponsePolicy = ResponsePolicy<skirout.service.v1.rollout.ApplyRolloutCommandResponse>(
    skirout.service.v1.rollout.ApplyRolloutCommandResponse.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.service.v1.rollout.ApplyRolloutCommandResponse.Kind.ACCEPTED_WRAPPER -> ResponseClassification.success("accepted")
        skirout.service.v1.rollout.ApplyRolloutCommandResponse.Kind.STALE_ATTEMPT_ERROR_WRAPPER -> ResponseClassification.domainError("stale-attempt-error")
        skirout.service.v1.rollout.ApplyRolloutCommandResponse.Kind.ATTEMPT_CONFLICT_ERROR_WRAPPER -> ResponseClassification.domainError("attempt-conflict-error")
        skirout.service.v1.rollout.ApplyRolloutCommandResponse.Kind.COMMAND_REJECTED_ERROR_WRAPPER -> ResponseClassification.domainError("command-rejected-error")
        skirout.service.v1.rollout.ApplyRolloutCommandResponse.Kind.COMMAND_FAILED_ERROR_WRAPPER -> ResponseClassification.domainError("command-failed-error")
        skirout.service.v1.rollout.ApplyRolloutCommandResponse.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val queryParticipantStatusResponsePolicy = ResponsePolicy<skirout.service.v1.rollout.QueryParticipantStatusResponse>(
    skirout.service.v1.rollout.QueryParticipantStatusResponse.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.service.v1.rollout.QueryParticipantStatusResponse.Kind.STATUS_WRAPPER -> ResponseClassification.success("status")
        skirout.service.v1.rollout.QueryParticipantStatusResponse.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val editorCatalogFetchRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.catalog.fetch".realmTemplate()
val RealmRouteScope.editorCatalogFetch get() = skirUnaryContract(
    method = FetchEditorCatalog, name = OperationName.of("editor.catalog.fetch"),
    address = editorCatalogFetchRequestAddress.subscribedAt(this), responsePolicy = catalogFetchResultPolicy,
)

private val editorCatalogWatchRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.catalog.invalidate".realmTemplate()
private val editorCatalogWatchUpdateAddress = "service.from.{realm}.organization.{organization}.realm.editor.catalog.invalidate".realmTemplate()
val RealmRouteScope.editorCatalogWatch get() = skirWatchContract(
    method = WatchEditorCatalog, updateSerializer = skirout.editor.v1.catalog.CatalogInvalidated.serializer,
    name = OperationName.of("editor.catalog.invalidate"), requestAddress = editorCatalogWatchRequestAddress.subscribedAt(this),
    updateAddress = editorCatalogWatchUpdateAddress, initialPolicy = watchEditorCatalogResponsePolicy,
)

private val editorValuePrepareRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.creation.prepare".realmTemplate()
val RealmRouteScope.editorValuePrepare get() = skirUnaryContract(
    method = PrepareValue, name = OperationName.of("editor.creation.prepare"),
    address = editorValuePrepareRequestAddress.subscribedAt(this), responsePolicy = prepareValueResultPolicy,
)

private val editorPresentationSearchRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.presentation.search".realmTemplate()
private val editorPresentationSearchUpdateAddress = "service.from.{realm}.organization.{organization}.realm.editor.presentation.search".realmTemplate()
val RealmRouteScope.editorPresentationSearch get() = skirWatchContract(
    method = WatchRealmPresentationSearch, updateSerializer = skirout.editor.v1.search.RealmPresentationSearchUpdate.serializer,
    name = OperationName.of("editor.presentation.search"), requestAddress = editorPresentationSearchRequestAddress.subscribedAt(this),
    updateAddress = editorPresentationSearchUpdateAddress, initialPolicy = realmPresentationSearchUpdatePolicy,
)

private val editorPresentationSearchCancelRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.presentation.search.cancel".realmTemplate()
val RealmRouteScope.editorPresentationSearchCancel get() = skirUnaryContract(
    method = CancelRealmPresentationSearch, name = OperationName.of("editor.presentation.search.cancel"),
    address = editorPresentationSearchCancelRequestAddress.subscribedAt(this), responsePolicy = cancelRealmPresentationSearchResultPolicy,
)

private val editorCapabilityComputationInvokeRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.capability.computation.invoke".realmTemplate()
val RealmRouteScope.editorCapabilityComputationInvoke get() = skirUnaryContract(
    method = InvokeRealmComputation, name = OperationName.of("editor.capability.computation.invoke"),
    address = editorCapabilityComputationInvokeRequestAddress.subscribedAt(this), responsePolicy = computationResultPolicy,
)

private val editorCapabilityCommandInvokeRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.capability.command.invoke".realmTemplate()
val RealmRouteScope.editorCapabilityCommandInvoke get() = skirUnaryContract(
    method = InvokeRealmCommand, name = OperationName.of("editor.capability.command.invoke"),
    address = editorCapabilityCommandInvokeRequestAddress.subscribedAt(this), responsePolicy = commandResultPolicy,
)

private val resourceOperationsResolveRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.resources.operations.resolve".realmTemplate()
val RealmRouteScope.resourceOperationsResolve get() = skirUnaryContract(
    method = ResolveResourceOperations, name = OperationName.of("editor.resources.operations.resolve"),
    address = resourceOperationsResolveRequestAddress.subscribedAt(this), responsePolicy = resolveResourceOperationsResultPolicy,
)

private val resourceDropCandidatesResolveRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.resources.drops.resolve".realmTemplate()
val RealmRouteScope.resourceDropCandidatesResolve get() = skirUnaryContract(
    method = ResolveDropCandidates, name = OperationName.of("editor.resources.drops.resolve"),
    address = resourceDropCandidatesResolveRequestAddress.subscribedAt(this), responsePolicy = resolveDropCandidatesResultPolicy,
)

private val authoringActionPrepareRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.resources.actions.prepare".realmTemplate()
val RealmRouteScope.authoringActionPrepare get() = skirUnaryContract(
    method = PrepareAuthoringAction, name = OperationName.of("editor.resources.actions.prepare"),
    address = authoringActionPrepareRequestAddress.subscribedAt(this), responsePolicy = authoringActionResultPolicy,
)

private val authoringStateQueryRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.authoring.state.query".realmTemplate()
val RealmRouteScope.authoringStateQuery get() = skirUnaryContract(
    method = QueryAuthoringState, name = OperationName.of("editor.authoring.state.query"),
    address = authoringStateQueryRequestAddress.subscribedAt(this), responsePolicy = queryAuthoringStateResponsePolicy,
)

private val authoringEditCommitRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.authoring.edit.commit".realmTemplate()
val RealmRouteScope.authoringEditCommit get() = skirUnaryContract(
    method = CommitPreparedEdit, name = OperationName.of("editor.authoring.edit.commit"),
    address = authoringEditCommitRequestAddress.subscribedAt(this), responsePolicy = commitPreparedEditResponsePolicy,
)

private val authoringTypePreviewRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.authoring.type.preview".realmTemplate()
val RealmRouteScope.authoringTypePreview get() = skirUnaryContract(
    method = PreviewTypeArgumentChange, name = OperationName.of("editor.authoring.type.preview"),
    address = authoringTypePreviewRequestAddress.subscribedAt(this), responsePolicy = previewTypeArgumentChangeResponsePolicy,
)

private val authoringTypeCommitRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.authoring.type.commit".realmTemplate()
val RealmRouteScope.authoringTypeCommit get() = skirUnaryContract(
    method = PrepareTypeArgumentChange, name = OperationName.of("editor.authoring.type.commit"),
    address = authoringTypeCommitRequestAddress.subscribedAt(this), responsePolicy = prepareTypeArgumentChangeResponsePolicy,
)

private val authoringSearchRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.authoring.search".realmTemplate()
val RealmRouteScope.authoringSearch get() = skirUnaryContract(
    method = SearchAuthoring, name = OperationName.of("editor.authoring.search"),
    address = authoringSearchRequestAddress.subscribedAt(this), responsePolicy = searchAuthoringResponsePolicy,
)

private val authoringChangedAddress = "service.from.{realm}.organization.{organization}.realm.editor.authoring.changed".realmTemplate()
val RealmRouteScope.authoringChanged get() = skirEventContract(
    serializer = skirout.editor.v1.authoring.AuthoringChanged.serializer, name = OperationName.of("editor.authoring.changed"), address = authoringChangedAddress,
)

private val authoringCompiledQueryRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.authoring.compiled.query".realmTemplate()
val RealmRouteScope.authoringCompiledQuery get() = skirUnaryContract(
    method = QueryPublishedContent, name = OperationName.of("editor.authoring.compiled.query"),
    address = authoringCompiledQueryRequestAddress.subscribedAt(this), responsePolicy = queryPublishedContentResponsePolicy,
)

private val authoringCompiledChangedAddress = "service.from.{realm}.organization.{organization}.realm.editor.authoring.compiled.changed".realmTemplate()
val RealmRouteScope.authoringCompiledChanged get() = skirEventContract(
    serializer = skirout.editor.v1.compiled_content.CompiledContentChanged.serializer, name = OperationName.of("editor.authoring.compiled.changed"), address = authoringCompiledChangedAddress,
)

private val authoringCompiledStatusQueryRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.authoring.compiled.status.query".realmTemplate()
val RealmRouteScope.authoringCompiledStatusQuery get() = skirUnaryContract(
    method = QueryCompiledResourceStatus, name = OperationName.of("editor.authoring.compiled.status.query"),
    address = authoringCompiledStatusQueryRequestAddress.subscribedAt(this), responsePolicy = queryCompiledResourceStatusResponsePolicy,
)

private val authoringPublishRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.authoring.publish".realmTemplate()
val RealmRouteScope.authoringPublish get() = skirUnaryContract(
    method = PublishAuthoring, name = OperationName.of("editor.authoring.publish"),
    address = authoringPublishRequestAddress.subscribedAt(this), responsePolicy = publishAuthoringResponsePolicy,
)

private val authoringPublicationQueryRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.authoring.publication.query".realmTemplate()
val RealmRouteScope.authoringPublicationQuery get() = skirUnaryContract(
    method = QueryPublicationView, name = OperationName.of("editor.authoring.publication.query"),
    address = authoringPublicationQueryRequestAddress.subscribedAt(this), responsePolicy = queryPublicationViewResponsePolicy,
)

private val authoringPublicationWatchRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.authoring.publication.watch".realmTemplate()
private val authoringPublicationWatchUpdateAddress = "service.from.{realm}.organization.{organization}.realm.editor.authoring.publication.watch".realmTemplate()
val RealmRouteScope.authoringPublicationWatch get() = skirWatchContract(
    method = WatchPublication, updateSerializer = skirout.editor.v1.publication.PublicationViewChanged.serializer,
    name = OperationName.of("editor.authoring.publication.watch"), requestAddress = authoringPublicationWatchRequestAddress.subscribedAt(this),
    updateAddress = authoringPublicationWatchUpdateAddress, initialPolicy = watchPublicationResponsePolicy,
)

private val sharedCatalogFetchRequestAddress = "service.to.{realm}.organization.{organization}.realm.shared.catalog.fetch".realmTemplate()
val RealmRouteScope.sharedCatalogFetch get() = skirUnaryContract(
    method = FetchSharedArtifactCatalog, name = OperationName.of("shared.catalog.fetch"),
    address = sharedCatalogFetchRequestAddress.subscribedAt(this), responsePolicy = fetchSharedArtifactCatalogResponsePolicy,
)

private val sharedPublishRequestAddress = "service.to.{realm}.organization.{organization}.realm.shared.publish".realmTemplate()
val RealmRouteScope.sharedPublish get() = skirUnaryContract(
    method = PublishSharedArtifact, name = OperationName.of("shared.publish"),
    address = sharedPublishRequestAddress.subscribedAt(this), responsePolicy = publishSharedArtifactResponsePolicy,
)

private val sharedBlobMetadataRequestAddress = "service.to.{realm}.organization.{organization}.realm.shared.blob.metadata".realmTemplate()
val RealmRouteScope.sharedBlobMetadata get() = skirUnaryContract(
    method = FetchArtifactBlobMetadata, name = OperationName.of("shared.blob.metadata"),
    address = sharedBlobMetadataRequestAddress.subscribedAt(this), responsePolicy = fetchArtifactBlobMetadataResponsePolicy,
)

private val sharedBlobReadRequestAddress = "service.to.{realm}.organization.{organization}.realm.shared.blob.read".realmTemplate()
val RealmRouteScope.sharedBlobRead get() = skirUnaryContract(
    method = ReadArtifactBlob, name = OperationName.of("shared.blob.read"),
    address = sharedBlobReadRequestAddress.subscribedAt(this), responsePolicy = readArtifactBlobResponsePolicy,
)

private val sharedBlobBeginRequestAddress = "service.to.{realm}.organization.{organization}.realm.shared.blob.begin".realmTemplate()
val RealmRouteScope.sharedBlobBegin get() = skirUnaryContract(
    method = BeginArtifactBlobWrite, name = OperationName.of("shared.blob.begin"),
    address = sharedBlobBeginRequestAddress.subscribedAt(this), responsePolicy = beginArtifactBlobWriteResponsePolicy,
)

private val sharedBlobWriteRequestAddress = "service.to.{realm}.organization.{organization}.realm.shared.blob.write".realmTemplate()
val RealmRouteScope.sharedBlobWrite get() = skirUnaryContract(
    method = WriteArtifactBlobChunk, name = OperationName.of("shared.blob.write"),
    address = sharedBlobWriteRequestAddress.subscribedAt(this), responsePolicy = writeArtifactBlobChunkResponsePolicy,
)

private val sharedBlobCompleteRequestAddress = "service.to.{realm}.organization.{organization}.realm.shared.blob.complete".realmTemplate()
val RealmRouteScope.sharedBlobComplete get() = skirUnaryContract(
    method = CompleteArtifactBlobWrite, name = OperationName.of("shared.blob.complete"),
    address = sharedBlobCompleteRequestAddress.subscribedAt(this), responsePolicy = completeArtifactBlobWriteResponsePolicy,
)

private val rolloutProbeRequestAddress = "service.from.{realm}.organization.{organization}.realm.rollout.probe".realmTemplate()
val RealmRouteScope.rolloutProbe get() = skirScatterContract(
    method = ProbeRealmHosts, name = OperationName.of("realm.rollout.probe"),
    address = rolloutProbeRequestAddress.subscribedAt(this), responsePolicy = probeRealmHostsResponsePolicy,
)

private val rolloutCommandRequestAddress = "service.from.{realm}.organization.{organization}.realm.rollout.command".realmTemplate()
val RealmRouteScope.rolloutCommand get() = skirScatterContract(
    method = ApplyRolloutCommand, name = OperationName.of("realm.rollout.command"),
    address = rolloutCommandRequestAddress.subscribedAt(this), responsePolicy = applyRolloutCommandResponsePolicy,
)

private val rolloutStatusRequestAddress = "service.from.{realm}.organization.{organization}.realm.rollout.status".realmTemplate()
val RealmRouteScope.rolloutStatus get() = skirScatterContract(
    method = QueryParticipantStatus, name = OperationName.of("realm.rollout.status"),
    address = rolloutStatusRequestAddress.subscribedAt(this), responsePolicy = queryParticipantStatusResponsePolicy,
)
