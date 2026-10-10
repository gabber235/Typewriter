package com.typewritermc.realm.routes

import com.typewritermc.protocol.transport.generated.RealmRouteScope
import com.typewritermc.protocol.transport.generated.authoringChanged
import com.typewritermc.protocol.transport.generated.authoringCompiledChanged
import com.typewritermc.protocol.transport.generated.authoringCompiledQuery
import com.typewritermc.protocol.transport.generated.authoringCompiledStatusQuery
import com.typewritermc.protocol.transport.generated.authoringEditCommit
import com.typewritermc.protocol.transport.generated.authoringPublicationWatch
import com.typewritermc.protocol.transport.generated.authoringPublish
import com.typewritermc.protocol.transport.generated.authoringSearch
import com.typewritermc.protocol.transport.generated.authoringStateQuery
import com.typewritermc.protocol.transport.generated.authoringTypeCommit
import com.typewritermc.protocol.transport.generated.authoringTypePreview
import com.typewritermc.protocol.transport.generated.editorCapabilityCommandInvoke
import com.typewritermc.protocol.transport.generated.editorCapabilityComputationInvoke
import com.typewritermc.protocol.transport.generated.editorCatalogFetch
import com.typewritermc.protocol.transport.generated.editorCatalogWatch
import com.typewritermc.protocol.transport.generated.editorPresentationSearch
import com.typewritermc.protocol.transport.generated.editorPresentationSearchCancel
import com.typewritermc.protocol.transport.generated.editorValuePrepare
import com.typewritermc.services.libs.communicator.contract.ResponseClassification
import com.typewritermc.services.libs.communicator.contract.ResponseClassifier
import com.typewritermc.services.libs.communicator.contract.ResponseOutcome
import com.typewritermc.services.libs.communicator.contract.ResponsePolicy
import com.typewritermc.services.libs.communicator.contract.ResponseVariant
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.PrepareTypeArgumentChangeResponse
import skirout.editor.v1.authoring.PreviewTypeArgumentChangeResponse
import skirout.editor.v1.authoring.QueryAuthoringStateResponse
import skirout.editor.v1.authoring.SearchAuthoringResponse
import skirout.editor.v1.capability.CommandResult
import skirout.editor.v1.capability.ComputationResult
import skirout.editor.v1.catalog.CatalogFetchResult
import skirout.editor.v1.catalog.CatalogInvalidated
import skirout.editor.v1.catalog.PrepareValueResult
import skirout.editor.v1.compiled_content.QueryCompiledResourceStatusResponse
import skirout.editor.v1.compiled_content.QueryPublishedContentResponse
import skirout.editor.v1.publication.PublicationReport
import skirout.editor.v1.publication.PublishAuthoringResponse
import skirout.editor.v1.search.CancelRealmPresentationSearchResult
import skirout.editor.v1.search.RealmPresentationSearchStatus
import skirout.editor.v1.search.RealmPresentationSearchUpdate

/** Binds generated Realm route metadata to local response policy. */
internal class EditorContracts(
    private val address: RealmRouteScope,
) {
    val fetchEditorCatalog =
        address.editorCatalogFetch(
            policy(CatalogFetchResult.createInternalError(), catalogFetchResponseClassifier()),
            catalogFetchResponseClassifier(),
        )
    val watchEditorCatalog =
        address.editorCatalogWatch(
            policy(CatalogInvalidated.partial(), responseClassifier(ResponseOutcome.INTERNAL_ERROR)),
            responseClassifier(ResponseOutcome.SUCCESS),
        )
    val prepareValue = address.editorValuePrepare(policy(PrepareValueResult.createInternalError()))
    val watchRealmPresentationSearch =
        address.editorPresentationSearch(
            policy(
                unavailableRealmPresentationSearchUpdate("", "Realm presentation search failed"),
                realmPresentationSearchResponseClassifier(),
            ),
            realmPresentationSearchResponseClassifier(),
        )
    val cancelRealmPresentationSearch =
        address.editorPresentationSearchCancel(policy(CancelRealmPresentationSearchResult.UNAVAILABLE))
    val invokeRealmComputation =
        address.editorCapabilityComputationInvoke(
            policy(
                ComputationResult.createUnavailable(
                    invocationId =
                        skirout.editor.v1.capability
                            .InvocationId(value = ""),
                    diagnostics = emptyList(),
                ),
            ),
        )
    val invokeRealmCommand =
        address.editorCapabilityCommandInvoke(
            policy(
                CommandResult.createUnavailable(
                    invocationId =
                        skirout.editor.v1.capability
                            .InvocationId(value = ""),
                    diagnostics = emptyList(),
                ),
            ),
        )
    val queryAuthoringState =
        address.authoringStateQuery(policy(QueryAuthoringStateResponse.createInternalError()), responseClassifier())
    val commitPreparedEdit = address.authoringEditCommit(policy(CommitPreparedEditResponse.createInternalError()))
    val previewTypeArgumentChange = address.authoringTypePreview(policy(PreviewTypeArgumentChangeResponse.createInternalError()))
    val prepareTypeArgumentChange = address.authoringTypeCommit(policy(PrepareTypeArgumentChangeResponse.createInternalError()))
    val searchAuthoring = address.authoringSearch(policy(SearchAuthoringResponse.createInternalError()))
    val authoringChanged = address.authoringChanged
    val queryPublishedContent =
        address.authoringCompiledQuery(policy(QueryPublishedContentResponse.createInternalError()), responseClassifier())
    val compiledContentChanged = address.authoringCompiledChanged
    val queryCompiledResourceStatus =
        address.authoringCompiledStatusQuery(policy(QueryCompiledResourceStatusResponse.createInternalError()))
    val publishAuthoring = address.authoringPublish(policy(PublishAuthoringResponse.createInternalError()))
    val watchPublication =
        address.authoringPublicationWatch(
            policy(PublicationReport.partial(), responseClassifier(ResponseOutcome.INTERNAL_ERROR)),
            responseClassifier(ResponseOutcome.SUCCESS),
        )
}

private fun catalogFetchResponseClassifier(): ResponseClassifier<CatalogFetchResult> =
    ResponseClassifier { response ->
        val outcome =
            when (response) {
                is CatalogFetchResult.ChunkWrapper -> ResponseOutcome.SUCCESS
                is CatalogFetchResult.InternalErrorWrapper -> ResponseOutcome.INTERNAL_ERROR
                else -> ResponseOutcome.DOMAIN_ERROR
            }
        ResponseClassification(outcome, response.variant())
    }

private fun realmPresentationSearchResponseClassifier(): ResponseClassifier<RealmPresentationSearchUpdate> =
    ResponseClassifier { response ->
        val outcome =
            when (response) {
                is RealmPresentationSearchUpdate.SnapshotWrapper -> {
                    when (response.value.status) {
                        RealmPresentationSearchStatus.LOADING,
                        RealmPresentationSearchStatus.READY,
                        -> ResponseOutcome.SUCCESS

                        else -> ResponseOutcome.DOMAIN_ERROR
                    }
                }

                is RealmPresentationSearchUpdate.UnavailableWrapper -> {
                    ResponseOutcome.INTERNAL_ERROR
                }

                else -> {
                    ResponseOutcome.DOMAIN_ERROR
                }
            }
        ResponseClassification(outcome, response.variant())
    }

private fun <Response : Any> policy(
    internalFailureResponse: Response,
    classifier: ResponseClassifier<Response> = responseClassifier(),
) = ResponsePolicy(internalFailureResponse, classifier)

private fun <Response : Any> responseClassifier(): ResponseClassifier<Response> =
    ResponseClassifier { response ->
        val variant = response.variant()
        val outcome =
            when (variant.value) {
                "internal-error", "unavailable" -> {
                    ResponseOutcome.INTERNAL_ERROR
                }

                "success", "prepared", "committed", "result", "applied", "initial", "activated", "canceled" -> {
                    ResponseOutcome.SUCCESS
                }

                else -> {
                    ResponseOutcome.DOMAIN_ERROR
                }
            }
        ResponseClassification(outcome, variant)
    }

private fun <Response : Any> responseClassifier(outcome: ResponseOutcome): ResponseClassifier<Response> =
    ResponseClassifier { response -> ResponseClassification(outcome, response.variant()) }

private fun Any.variant(): ResponseVariant =
    ResponseVariant.of(
        requireNotNull(this::class.simpleName)
            .removeSuffix("Wrapper")
            .replace(Regex("([a-z0-9])([A-Z])"), "\$1-\$2")
            .replace('_', '-')
            .lowercase(),
    )
