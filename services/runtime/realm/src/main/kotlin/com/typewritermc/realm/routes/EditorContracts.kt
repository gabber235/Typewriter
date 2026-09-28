package com.typewritermc.realm.routes

import build.skir.Serializer
import build.skir.service.Method
import com.typewritermc.loader.api.RealmServiceAddress
import com.typewritermc.loader.api.realmEventAddress
import com.typewritermc.loader.api.realmRequestAddress
import com.typewritermc.services.libs.communicator.address.AddressTemplate
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
import skirout.editor.v1.authoring.ApplyAuthoringBatch
import skirout.editor.v1.authoring.ApplyAuthoringBatchResponse
import skirout.editor.v1.authoring.AuthoringChanged
import skirout.editor.v1.authoring.PreviewAuthoringBatch
import skirout.editor.v1.authoring.PreviewAuthoringBatchResponse
import skirout.editor.v1.authoring.QueryAuthoringGraph
import skirout.editor.v1.authoring.QueryAuthoringGraphResponse
import skirout.editor.v1.authoring.SearchAuthoringGraph
import skirout.editor.v1.authoring.SearchAuthoringGraphResponse
import skirout.editor.v1.capability.CommandResult
import skirout.editor.v1.capability.ComputationResult
import skirout.editor.v1.capability.InvokeRealmCommand
import skirout.editor.v1.capability.InvokeRealmComputation
import skirout.editor.v1.catalog.CatalogFetchResult
import skirout.editor.v1.catalog.CatalogWatchUpdate
import skirout.editor.v1.catalog.FetchEditorCatalog
import skirout.editor.v1.catalog.InitializeTypedValue
import skirout.editor.v1.catalog.InitializeTypedValueResult
import skirout.editor.v1.catalog.WatchEditorCatalog
import skirout.editor.v1.compiled_content.CompiledContentChanged
import skirout.editor.v1.compiled_content.QueryCompiledResourceStatus
import skirout.editor.v1.compiled_content.QueryCompiledResourceStatusResponse
import skirout.editor.v1.compiled_content.WatchCompiledContent
import skirout.editor.v1.compiled_content.WatchCompiledContentResponse
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
        unary(
            FetchEditorCatalog,
            "editor.catalog.fetch",
            unavailableCatalogFetchResult("Realm editor catalog fetch failed"),
            catalogFetchResponseClassifier(),
        )
    val watchEditorCatalog =
        watch(
            WatchEditorCatalog,
            CatalogWatchUpdate.serializer,
            "editor.catalog.invalidate",
            CatalogWatchUpdate.createInitial(value = "unavailable"),
            catalogWatchResponseClassifier(),
        )
    val initializeTypedValue =
        unary(
            InitializeTypedValue,
            "editor.typed.value.initialize",
            InitializeTypedValueResult.UnavailableWrapper(emptyList()),
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
    val queryAuthoringGraph =
        unary(
            QueryAuthoringGraph,
            "editor.authoring.graph.query",
            QueryAuthoringGraphResponse.createInternalError(),
        )
    val applyAuthoringBatch =
        unary(
            ApplyAuthoringBatch,
            "editor.authoring.batch.apply",
            ApplyAuthoringBatchResponse.createInternalError(),
        )
    val previewAuthoringBatch =
        unary(
            PreviewAuthoringBatch,
            "editor.authoring.batch.preview",
            PreviewAuthoringBatchResponse.createInternalError(),
        )
    val searchAuthoringGraph =
        unary(
            SearchAuthoringGraph,
            "editor.authoring.graph.search",
            SearchAuthoringGraphResponse.createInternalError(),
        )
    val authoringChanged =
        EventContract(
            OperationName.of("editor.authoring.changed"),
            updateAddress("editor.authoring.changed"),
            AuthoringChanged.serializer.asPayloadCodec(),
            ErrorSlug.of("editor-authoring-changed-failed"),
        )
    val watchCompiledContent =
        watch(
            WatchCompiledContent,
            WatchCompiledContentResponse.serializer,
            "editor.authoring.compiled.watch",
            WatchCompiledContentResponse.createInternalError(),
            responseClassifier(),
        )
    val compiledContentActivated =
        EventContract(
            OperationName.of("editor.authoring.compiled.activated"),
            updateAddress("editor.authoring.compiled.activated"),
            WatchCompiledContentResponse.serializer.asPayloadCodec(),
            ErrorSlug.of("editor-authoring-compiled-activated-failed"),
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
        classifier: ResponseClassifier<Response> = responseClassifier(),
        updateFilter: (Request, Response) -> Boolean = { _, _ -> true },
    ): WatchContract<RealmAddress, Request, Response, Response> =
        skirWatchContract(
            method = method,
            updateSerializer = updateSerializer,
            name = OperationName.of(suffix),
            requestAddress = requestAddress(suffix).subscribedAt(address),
            updateAddress = updateAddress(suffix),
            initialPolicy = ResponsePolicy(internalFailureResponse, classifier),
            updateClassifier = classifier,
            failureSlug = ErrorSlug.of(suffix.replace('.', '-') + "-failed"),
            updateFilter = updateFilter,
        )
}

/** Resolves a request subject while retaining the logical Realm address as its routing key. */
internal fun requestAddress(suffix: String): AddressTemplate<RealmAddress> = realmRequestAddress(suffix)

/** Resolves the event subject used for publications observed by clients of the logical Realm. */
internal fun updateAddress(suffix: String): AddressTemplate<RealmAddress> = realmEventAddress(suffix)

/** Encodes a watch update for direct publication outside the request handler. */
internal fun <Request : Any, Initial : Any, Update : Any> WatchContract<RealmAddress, Request, Initial, Update>.encodeUpdate(
    address: RealmAddress,
    update: Update,
): EncodedPublication = EncodedPublication(updateAddress.render(address), updateCodec.encode(update))

private fun catalogFetchResponseClassifier(): ResponseClassifier<CatalogFetchResult> =
    ResponseClassifier { response ->
        val outcome =
            when (response) {
                is CatalogFetchResult.SuccessWrapper -> ResponseOutcome.SUCCESS
                is CatalogFetchResult.UnavailableWrapper -> ResponseOutcome.INTERNAL_ERROR
                else -> ResponseOutcome.DOMAIN_ERROR
            }
        ResponseClassification(outcome, response.variant())
    }

private fun catalogWatchResponseClassifier(): ResponseClassifier<CatalogWatchUpdate> =
    ResponseClassifier { response ->
        val outcome =
            when (response) {
                is CatalogWatchUpdate.InitialWrapper -> {
                    if (response.value.value == "unavailable") ResponseOutcome.INTERNAL_ERROR else ResponseOutcome.SUCCESS
                }

                is CatalogWatchUpdate.InvalidatedWrapper -> {
                    ResponseOutcome.SUCCESS
                }

                else -> {
                    ResponseOutcome.DOMAIN_ERROR
                }
            }
        ResponseClassification(outcome, response.variant())
    }

private fun <Response : Any> responseClassifier(): ResponseClassifier<Response> =
    ResponseClassifier { response ->
        val variant = response.variant()
        val outcome =
            when (variant.value) {
                "internal-error", "unavailable" -> ResponseOutcome.INTERNAL_ERROR
                "success", "applied", "initial", "activated", "canceled" -> ResponseOutcome.SUCCESS
                else -> ResponseOutcome.DOMAIN_ERROR
            }
        ResponseClassification(outcome, variant)
    }

private fun Any.variant(): ResponseVariant =
    ResponseVariant.of(
        requireNotNull(this::class.simpleName)
            .removeSuffix("Wrapper")
            .replace(Regex("([a-z0-9])([A-Z])"), "\$1-\$2")
            .replace('_', '-')
            .lowercase(),
    )
