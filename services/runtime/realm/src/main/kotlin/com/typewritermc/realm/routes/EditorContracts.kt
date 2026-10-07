package com.typewritermc.realm.routes

import build.skir.Serializer
import build.skir.service.Method
import com.typewritermc.loader.api.RealmServiceAddress
import com.typewritermc.loader.api.realmEventAddress
import com.typewritermc.loader.api.realmRequestAddress
import com.typewritermc.services.libs.communicator.address.AddressTemplate
import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.client.EncodedPublication
import com.typewritermc.services.libs.communicator.contract.EventContract
import com.typewritermc.services.libs.communicator.contract.OperationName
import com.typewritermc.services.libs.communicator.contract.ResponseClassification
import com.typewritermc.services.libs.communicator.contract.ResponseClassifier
import com.typewritermc.services.libs.communicator.contract.ResponseOutcome
import com.typewritermc.services.libs.communicator.contract.ResponsePolicy
import com.typewritermc.services.libs.communicator.contract.ResponseVariant
import com.typewritermc.services.libs.communicator.contract.UnaryContract
import com.typewritermc.services.libs.communicator.contract.WatchContract
import com.typewritermc.services.libs.communicator.skir.asPayloadCodec
import com.typewritermc.services.libs.communicator.skir.skirUnaryContract
import com.typewritermc.services.libs.communicator.skir.skirWatchContract
import com.typewritermc.services.libs.telemetry.ErrorSlug
import skirout.editor.v1.authoring.AuthoringChanged
import skirout.editor.v1.authoring.CommitPreparedEdit
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.CommitTypeArgumentChange
import skirout.editor.v1.authoring.CommitTypeArgumentChangeResponse
import skirout.editor.v1.authoring.PreviewTypeArgumentChange
import skirout.editor.v1.authoring.PreviewTypeArgumentChangeResponse
import skirout.editor.v1.authoring.QueryAuthoringState
import skirout.editor.v1.authoring.QueryAuthoringStateResponse
import skirout.editor.v1.authoring.SearchAuthoring
import skirout.editor.v1.authoring.SearchAuthoringResponse
import skirout.editor.v1.capability.CommandResult
import skirout.editor.v1.capability.ComputationResult
import skirout.editor.v1.capability.InvokeRealmCommand
import skirout.editor.v1.capability.InvokeRealmComputation
import skirout.editor.v1.catalog.CatalogFetchResult
import skirout.editor.v1.catalog.CatalogInvalidated
import skirout.editor.v1.catalog.FetchEditorCatalog
import skirout.editor.v1.catalog.PrepareCreation
import skirout.editor.v1.catalog.PrepareCreationResult
import skirout.editor.v1.catalog.WatchEditorCatalog
import skirout.editor.v1.compiled_content.CompiledContentChanged
import skirout.editor.v1.compiled_content.QueryCompiledResourceStatus
import skirout.editor.v1.compiled_content.QueryCompiledResourceStatusResponse
import skirout.editor.v1.compiled_content.QueryPublishedContent
import skirout.editor.v1.compiled_content.QueryPublishedContentResponse
import skirout.editor.v1.publication.PublicationReport
import skirout.editor.v1.publication.PublishAuthoring
import skirout.editor.v1.publication.PublishAuthoringResponse
import skirout.editor.v1.publication.WatchPublication
import skirout.editor.v1.search.CancelRealmPresentationSearch
import skirout.editor.v1.search.CancelRealmPresentationSearchResult

typealias RealmAddress = RealmServiceAddress

/**
 * Centralizes typed Realm request, event, and watch contracts for authoring and editor operations.
 *
 * Addresses use logical Realm identity. Shared codecs, failure responses, and response classifiers keep client and
 * router semantics aligned without creating subscriptions at construction.
 */
internal class EditorContracts(
    private val address: RealmAddress,
) {
    val fetchEditorCatalog =
        watch(
            FetchEditorCatalog,
            CatalogFetchResult.serializer,
            "editor.catalog.fetch",
            CatalogFetchResult.createInternalError(),
            catalogFetchResponseClassifier(),
            catalogFetchResponseClassifier(),
            updateAddressResolver = { realm, request ->
                scopedUpdateAddress("editor.catalog.fetch", realm, request.transferId)
            },
        )
    val watchEditorCatalog =
        watch(
            WatchEditorCatalog,
            CatalogInvalidated.serializer,
            "editor.catalog.invalidate",
            CatalogInvalidated.partial(),
            responseClassifier(ResponseOutcome.INTERNAL_ERROR),
            responseClassifier(ResponseOutcome.SUCCESS),
        )
    val prepareCreation =
        unary(
            PrepareCreation,
            "editor.creation.prepare",
            PrepareCreationResult.createInternalError(),
        )
    val watchRealmPresentationSearch = realmPresentationSearchContract(address)
    val cancelRealmPresentationSearch =
        unary(
            CancelRealmPresentationSearch,
            "editor.presentation.search.cancel",
            CancelRealmPresentationSearchResult.UNAVAILABLE,
        )
    val invokeRealmComputation =
        unary(
            InvokeRealmComputation,
            "editor.capability.computation.invoke",
            ComputationResult.createUnavailable(
                invocationId =
                    skirout.editor.v1.capability
                        .InvocationId(value = ""),
                diagnostics = emptyList(),
            ),
        )
    val invokeRealmCommand =
        unary(
            InvokeRealmCommand,
            "editor.capability.command.invoke",
            CommandResult.createUnavailable(
                invocationId =
                    skirout.editor.v1.capability
                        .InvocationId(value = ""),
                diagnostics = emptyList(),
            ),
        )
    val queryAuthoringState =
        watch(
            QueryAuthoringState,
            QueryAuthoringStateResponse.serializer,
            "editor.authoring.state.query",
            QueryAuthoringStateResponse.createInternalError(),
            updateAddressResolver = { realm, request ->
                scopedUpdateAddress("editor.authoring.state.query", realm, request.transferId)
            },
        )
    val commitPreparedEdit =
        unary(
            CommitPreparedEdit,
            "editor.authoring.edit.commit",
            CommitPreparedEditResponse.createInternalError(),
        )
    val previewTypeArgumentChange =
        unary(
            PreviewTypeArgumentChange,
            "editor.authoring.type.preview",
            PreviewTypeArgumentChangeResponse.createInternalError(),
        )
    val commitTypeArgumentChange =
        unary(
            CommitTypeArgumentChange,
            "editor.authoring.type.commit",
            CommitTypeArgumentChangeResponse.createInternalError(),
        )
    val searchAuthoring =
        unary(
            SearchAuthoring,
            "editor.authoring.search",
            SearchAuthoringResponse.createInternalError(),
        )
    val authoringChanged =
        EventContract(
            OperationName.of("editor.authoring.changed"),
            updateAddress("editor.authoring.changed"),
            AuthoringChanged.serializer.asPayloadCodec(),
            ErrorSlug.of("editor-authoring-changed-failed"),
        )
    val queryPublishedContent =
        watch(
            QueryPublishedContent,
            QueryPublishedContentResponse.serializer,
            "editor.authoring.compiled.query",
            QueryPublishedContentResponse.createInternalError(),
            responseClassifier(),
            updateAddressResolver = { realm, request -> scopedUpdateAddress("editor.authoring.compiled.query", realm, request.transferId) },
        )
    val compiledContentChanged =
        EventContract(
            OperationName.of("editor.authoring.compiled.changed"),
            updateAddress("editor.authoring.compiled.changed"),
            CompiledContentChanged.serializer.asPayloadCodec(),
            ErrorSlug.of("editor-authoring-compiled-changed-failed"),
        )
    val queryCompiledResourceStatus =
        unary(
            QueryCompiledResourceStatus,
            "editor.authoring.compiled.status.query",
            QueryCompiledResourceStatusResponse.createInternalError(),
        )
    val publishAuthoring =
        unary(
            PublishAuthoring,
            "editor.authoring.publish",
            PublishAuthoringResponse.createInternalError(),
        )
    val watchPublication =
        watch(
            WatchPublication,
            PublicationReport.serializer,
            "editor.authoring.publication.watch",
            PublicationReport
                .partial(),
            responseClassifier(ResponseOutcome.INTERNAL_ERROR),
            responseClassifier(ResponseOutcome.SUCCESS),
        )

    private fun <Request : Any, Response : Any> unary(
        method: Method<Request, Response>,
        suffix: String,
        internalFailureResponse: Response,
        classifier: ResponseClassifier<Response> = responseClassifier(),
    ): UnaryContract<RealmAddress, Request, Response> =
        skirUnaryContract(
            method = method,
            name = OperationName.of(suffix),
            address = requestAddress(suffix).subscribedAt(address),
            responsePolicy = ResponsePolicy(internalFailureResponse, classifier),
            failureSlug = ErrorSlug.of(suffix.replace('.', '-') + "-failed"),
        )

    private fun <Request : Any, Response : Any> watch(
        method: Method<Request, Response>,
        updateSerializer: Serializer<Response>,
        suffix: String,
        internalFailureResponse: Response,
        initialClassifier: ResponseClassifier<Response> = responseClassifier(),
        updateClassifier: ResponseClassifier<Response> = initialClassifier,
        updateFilter: (Request, Response) -> Boolean = { _, _ -> true },
        updateAddressResolver: ((RealmAddress, Request) -> MessageAddress)? = null,
    ): WatchContract<RealmAddress, Request, Response, Response> =
        skirWatchContract(
            method = method,
            updateSerializer = updateSerializer,
            name = OperationName.of(suffix),
            requestAddress = requestAddress(suffix).subscribedAt(address),
            updateAddress = updateAddress(suffix),
            initialPolicy = ResponsePolicy(internalFailureResponse, initialClassifier),
            updateClassifier = updateClassifier,
            failureSlug = ErrorSlug.of(suffix.replace('.', '-') + "-failed"),
            updateFilter = updateFilter,
            updateAddressResolver = updateAddressResolver,
        )
}

/** Resolves a request subject while retaining the logical Realm address as its routing key. */
internal fun requestAddress(suffix: String): AddressTemplate<RealmAddress> = realmRequestAddress(suffix)

/** Resolves the event subject used for publications observed by clients of the logical Realm. */
internal fun updateAddress(suffix: String): AddressTemplate<RealmAddress> = realmEventAddress(suffix)

private fun scopedUpdateAddress(
    suffix: String,
    address: RealmAddress,
    token: String,
): MessageAddress {
    require(token.matches(Regex("[A-Za-z0-9_-]{1,64}"))) {
        "Transfer token must be one safe subject segment"
    }
    return MessageAddress.of("${updateAddress(suffix).render(address).value}.$token")
}

/** Encodes a watch update for direct publication outside the request handler. */
internal fun <Request : Any, Initial : Any, Update : Any> WatchContract<RealmAddress, Request, Initial, Update>.encodeUpdate(
    address: RealmAddress,
    update: Update,
): EncodedPublication = EncodedPublication(updateAddress.render(address), updateCodec.encode(update))

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

private fun <Response : Any> responseClassifier(): ResponseClassifier<Response> =
    ResponseClassifier { response ->
        val variant = response.variant()
        val outcome =
            when (variant.value) {
                "internal-error", "unavailable" -> ResponseOutcome.INTERNAL_ERROR
                "success", "prepared", "committed", "result", "applied", "initial", "activated", "canceled" -> ResponseOutcome.SUCCESS
                else -> ResponseOutcome.DOMAIN_ERROR
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
