package com.typewritermc.realm.routes

import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.complete
import com.typewritermc.operations.OperationResourceOption
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.testkit.ready
import com.typewritermc.types.requirePortable
import com.typewritermc.types.use
import skirout.editor.v1.search.RealmPresentationSearchRequest
import skirout.editor.v1.search.RealmSearchQuery
import skirout.editor.v1.type_catalog.CapabilityId
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeTemplate

/** A presentation search request for a text capability over the subscription "search", valid for every source. */
internal fun validSearchRequest() =
    RealmPresentationSearchRequest(
        subscriptionId = "search",
        generation = CatalogGeneration(value = "generation"),
        capabilityId = CapabilityId(value = "capability"),
        payload = DataValue.StringValueWrapper("server"),
        resultType = TypeTemplate.ScalarWrapper(ScalarKind.TEXT),
        operationContext = null,
        query =
            RealmSearchQuery(
                normalizedQuery = "alex",
                terms = listOf("alex"),
                selectors = emptyList(),
                selectorExpression = null,
            ),
    )

/** Decodes one search result value of the saved Realm as an operation resource option. */
internal fun RealmFixture.option(value: DataValue): OperationResourceOption =
    views.read { root ->
        val checked =
            root.catalog.checked.ready(com.typewritermc.operations.OperationResourceOptionDefinition.use.use)
        val complete =
            checked.complete(
                value.requirePortable(),
            ) as CompletenessResult.Complete
        root.catalog.nativeBindings
            .bind(checked)
            .decode(complete.value) as OperationResourceOption
    }
