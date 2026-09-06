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
import skirout.editor.v1.capability.CommandResult
import skirout.editor.v1.capability.ComputationResult
import skirout.editor.v1.capability.InvokeRealmCommand
import skirout.editor.v1.capability.InvokeRealmComputation
import skirout.editor.v1.catalog.CatalogFetchResult
import skirout.editor.v1.catalog.CatalogWatchUpdate
import skirout.editor.v1.catalog.FetchEditorCatalog
import skirout.editor.v1.catalog.WatchEditorCatalog
import skirout.editor.v1.search.CancelRealmPresentationSearch
import skirout.editor.v1.search.CancelRealmPresentationSearchResult
import skirout.library.v1.authoring.ApplyAuthoringBatch
import skirout.library.v1.authoring.ApplyAuthoringBatchResponse
import skirout.library.v1.authoring.AuthoringChanged
import skirout.library.v1.authoring.GetAuthoringSnapshot
import skirout.library.v1.authoring.GetAuthoringSnapshotResponse
import skirout.library.v1.compiled_content.WatchCompiledContent
import skirout.library.v1.compiled_content.WatchCompiledContentResponse

typealias RealmAddress = RealmServiceAddress

/**
 * Centralizes typed Realm request, event, and watch contracts for authoring and editor operations.
 *
 * Addresses use logical Realm identity. Shared codecs, failure responses, and response classifiers keep client and
 * router semantics aligned without creating subscriptions at construction.
 */
internal class LibraryContracts(
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
    val getAuthoringSnapshot =
        unary(
            GetAuthoringSnapshot,
            "library.authoring.snapshot.get",
            GetAuthoringSnapshotResponse.createInternalError(message = "Authoring snapshot failed"),
        )
    val applyAuthoringBatch =
        unary(
            ApplyAuthoringBatch,
            "library.authoring.batch.apply",
            ApplyAuthoringBatchResponse.createInternalError(message = "Authoring batch failed"),
        )
    val authoringChanged =
        EventContract(
            OperationName.of("library.authoring.changed"),
            updateAddress("library.authoring.changed"),
            AuthoringChanged.serializer.asPayloadCodec(),
            ErrorSlug.of("library-authoring-changed-failed"),
        )
    val watchCompiledContent =
        watch(
            WatchCompiledContent,
            WatchCompiledContentResponse.serializer,
            "compiled.content.watch",
            WatchCompiledContentResponse.createInternalError(message = "Compiled content watch failed"),
        )
    val compiledContentChanged =
        EventContract(
            OperationName.of("compiled.content.changed"),
            updateAddress("compiled.content.watch"),
            WatchCompiledContentResponse.serializer.asPayloadCodec(),
            ErrorSlug.of("compiled-content-changed-failed"),
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

internal fun requestAddress(suffix: String): AddressTemplate<RealmAddress> = realmRequestAddress(suffix)

internal fun updateAddress(suffix: String): AddressTemplate<RealmAddress> = realmEventAddress(suffix)

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
