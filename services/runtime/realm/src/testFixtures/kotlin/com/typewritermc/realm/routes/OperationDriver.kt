@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.routes

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.field
import com.typewritermc.authoring.requireValid
import com.typewritermc.authoring.root
import com.typewritermc.operations.candidateSearch
import com.typewritermc.operations.capability
import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.realm.operation.ResourceOperationRuntime
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.setup.SetupHandle
import com.typewritermc.types.requirePortable
import com.typewritermc.types.toSkir
import com.typewritermc.types.use
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.authoring.AuthoringObservationId
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.capability.InvocationId
import skirout.editor.v1.operation.ResourceOperationId
import skirout.editor.v1.resource_operations.AuthoringActionResult
import skirout.editor.v1.resource_operations.OperationInvocation
import skirout.editor.v1.resource_operations.OperationOrigin
import skirout.editor.v1.resource_operations.OperationSearchContext
import skirout.editor.v1.resource_operations.OperationWorkingContext
import skirout.editor.v1.resource_operations.OperationWorkingOverlay
import skirout.editor.v1.resource_operations.PrepareAuthoringActionRequest
import skirout.editor.v1.resource_operations.ResolveDropCandidatesRequest
import skirout.editor.v1.resource_operations.ResolveResourceOperationsRequest
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CapabilityId
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId

/** The panel's side of the resource operation routes, against the saved state of a [RealmFixture]. */
internal class OperationDriver(
    private val realm: RealmFixture,
) {
    val routes get() = ResourceOperationRoutes(ResourceOperationRuntime(realm.views), RealmRouteScope("organization", "realm"))

    /** The published identity of the operation object [declaration]. */
    fun operation(declaration: Any): ResourceOperationId = operation(declaration::class.qualifiedName!!)

    /** The published identity of the operation declared as [declaration]. */
    fun operation(declaration: String): ResourceOperationId =
        realm.views.read { root ->
            root.catalog.operations.operations
                .single { it.definition.id.declaration == declaration }
                .definition.id
        }

    /** The candidate search of [field] in the input of [operation]. */
    fun candidateSearch(
        operation: ResourceOperationId,
        field: String,
    ): CapabilityId = operation.candidateSearch(ValuePath.root.field(field))

    /** [value] as the operation input of [type]. */
    fun input(
        value: Any,
        type: TypeDefinitionId,
    ): DataValue = realm.encoder.encode(type.use(), value).requirePortable()

    fun resolve(vararg targets: ResourceId) = routes.resolve(resolveRequest(*targets))

    fun resolveRequest(vararg targets: ResourceId) =
        ResolveResourceOperationsRequest(invocation = invocation(*targets), context = workingContext())

    fun dropCandidates(vararg targets: ResourceId) =
        routes.resolveDropCandidates(ResolveDropCandidatesRequest(invocation = invocation(*targets), context = workingContext()))

    /** A preparation request of [operation] for [targets], without choices. */
    fun prepare(
        operation: ResourceOperationId,
        vararg targets: ResourceId,
        input: DataValue? = null,
    ) = PrepareAuthoringActionRequest(
        invocation = invocation(*targets),
        capability = CapabilityId(value = operation.capability.value),
        context = workingContext(),
        inputRevision = 0,
        input = input,
        choices = emptyList(),
    )

    fun searchContext(vararg targets: ResourceId) =
        OperationSearchContext(invocation = invocation(*targets), context = workingContext(), inputRevision = 0)

    /**
     * Prepares [request] through the route, checks the preview left saved state alone, commits the preview the way the
     * panel does, and returns the saved resources after the commit.
     */
    suspend fun commit(request: PrepareAuthoringActionRequest): Map<ResourceId, AuthoringRecord> {
        val before = realm.resources
        val preview = routes.prepare(request).shouldBeInstanceOf<AuthoringActionResult.PreviewWrapper>()
        realm.resources shouldBe before
        realm.commit(preview.value.edit.requireValid()) shouldBe CommitPreparedEditResponse.COMMITTED
        return realm.resources
    }

    private fun invocation(vararg targets: ResourceId) =
        OperationInvocation(
            invocationId = InvocationId(value = "operation-test"),
            catalog = realm.views.read { it.catalog.generation },
            targets = targets.toList(),
            origin = OperationOrigin(container = null, occurrences = emptyList()),
        )

    private fun workingContext() =
        realm.views.read { root ->
            OperationWorkingContext(
                confirmedObservation = AuthoringObservationId(value = root.observationId),
                overlay = OperationWorkingOverlay(upserts = emptyList(), removals = emptyList()),
            )
        }
}

internal val RealmFixture.operations get() = OperationDriver(this)

/** The saved resource id of a setup handle, as routes and saved records name it. */
internal val SetupHandle<*>.resource: ResourceId get() = id.toSkir()
