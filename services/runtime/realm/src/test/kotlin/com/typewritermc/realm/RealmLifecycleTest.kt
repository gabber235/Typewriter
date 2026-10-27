package com.typewritermc.realm

import build.skir.Serializer
import com.surrealdb.Surreal
import com.typewritermc.authoring.RealmRootDefinition
import com.typewritermc.authoring.definition
import com.typewritermc.authoring.of
import com.typewritermc.discovery.CatalogAssemblyContext
import com.typewritermc.discovery.CatalogContributions
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.GeneratedProviderLoader
import com.typewritermc.discovery.OwnedTypeDeclaration
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.discovery.assemble
import com.typewritermc.discovery.contributionKey
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.library.LibraryDefinition
import com.typewritermc.library.TaxonomyDefinition
import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.loader.api.HostedRuntimeHost
import com.typewritermc.loader.api.artifact.PublishResult
import com.typewritermc.loader.api.artifact.PublishSharedArtifact
import com.typewritermc.loader.api.artifact.SharedArtifactAccess
import com.typewritermc.loader.api.artifact.SharedArtifactCatalog
import com.typewritermc.loader.api.artifact.SharedArtifactId
import com.typewritermc.loader.api.artifact.SharedArtifactProvenance
import com.typewritermc.loader.api.artifact.SharedArtifactRevision
import com.typewritermc.loader.api.artifact.SharedCatalogRevision
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.catalog.RealmCatalogIncarnation
import com.typewritermc.realm.catalog.RealmCatalogStore
import com.typewritermc.realm.catalog.installTestCatalog
import com.typewritermc.realm.edit.AuthoringMutationPlan
import com.typewritermc.realm.edit.SurrealAuthoringStorage
import com.typewritermc.realm.operation.PreparationEvaluator
import com.typewritermc.realm.publication.StagedEngineImplementationSource
import com.typewritermc.realm.storage.RealmDatabaseProvider
import com.typewritermc.realm.storage.SchemaMigrator
import com.typewritermc.realm.testing.RealmCatalog
import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.transport.InboundMessage
import com.typewritermc.services.libs.communicator.transport.TransportDelivery
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobMetadata
import com.typewritermc.services.libs.filetransfer.blob.BlobResult
import com.typewritermc.services.libs.filetransfer.blob.StoreResult
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.MainSpanScope
import com.typewritermc.services.libs.telemetry.mainSpan
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import com.typewritermc.services.libs.utils.FakeDelayScheduler
import com.typewritermc.services.libs.utils.RetryPolicy
import com.typewritermc.types.namedUse
import com.typewritermc.types.payload
import com.typewritermc.types.qualified
import com.typewritermc.types.requireValid
import com.typewritermc.types.template
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.ints.shouldBeGreaterThan
import io.kotest.matchers.shouldBe
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.async
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.yield
import skirout.editor.v1.authoring.QueryAuthoringStateRequest
import skirout.editor.v1.authoring.QueryAuthoringStateResponse
import skirout.editor.v1.authoring.RelationProjectionDelta
import skirout.editor.v1.catalog.CatalogFetchRequest
import skirout.editor.v1.catalog.CatalogFetchResult
import skirout.editor.v1.publication.EngineImplementationInputs
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.DeclarationOwner
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.InputToken
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.kernel.v1.resource_id.ResourceId
import kotlin.time.Duration.Companion.seconds

@OptIn(ExperimentalCoroutinesApi::class)
val RealmLifecycleTest by testSuite {
    /** Every editor request subject a started Realm answers for the fixture organization and Realm. */
    val realmRoutes =
        listOf(
            "editor.catalog.fetch",
            "editor.catalog.invalidate",
            "editor.creation.prepare",
            "editor.presentation.search",
            "editor.presentation.search.cancel",
            "editor.capability.computation.invoke",
            "editor.capability.command.invoke",
            "editor.resources.operations.resolve",
            "editor.resources.drops.resolve",
            "editor.resources.actions.prepare",
            "editor.authoring.state.query",
            "editor.authoring.edit.commit",
            "editor.authoring.type.preview",
            "editor.authoring.type.commit",
            "editor.authoring.search",
            "editor.authoring.compiled.query",
            "editor.authoring.compiled.status.query",
            "editor.authoring.publish",
            "editor.authoring.publication.query",
            "editor.authoring.publication.watch",
        ).map { "service.to.realm.organization.organization.realm.$it" }.toSet()

    test("catalog activation completes before Realm routes are exposed") {
        runTest {
            val activationStarted = CompletableDeferred<Unit>()
            val finishActivation = CompletableDeferred<Unit>()
            val fixture =
                RealmLifecycleFixture(this) { _, _ ->
                    activationStarted.complete(Unit)
                    finishActivation.await()
                    error("catalog activation failed")
                }
            val session = fixture.session(1)
            fixture.messaging.value = session.session

            val startup = async { runCatching { fixture.start() } }
            activationStarted.await()

            fixture.databaseOpen shouldBe true
            startup.isCompleted shouldBe false
            session.transport.activeSubscriptionCount shouldBe 0

            finishActivation.complete(Unit)
            startup.await().exceptionOrNull()?.message shouldBe "catalog activation failed"
            fixture.databaseOpen shouldBe false
            session.transport.activeSubscriptionCount shouldBe 0
            fixture.close()
        }
    }

    test("startup waits until Realm responders are registered") {
        runTest {
            val fixture = RealmLifecycleFixture(this)
            try {
                val startup = async { fixture.start() }
                runCurrent()

                fixture.databaseOpen shouldBe true
                startup.isCompleted shouldBe false

                val session = fixture.session(1)
                fixture.messaging.value = session.session
                runCurrent()

                startup.await()
                session.transport.activeRealmRoutes() shouldBe realmRoutes
            } finally {
                fixture.close()
            }
        }
    }

    test("a stopped Realm stops its routes and serves them again when started on the same staging") {
        runTest {
            val fixture = RealmLifecycleFixture(this)
            try {
                val session = fixture.session(1)
                fixture.messaging.value = session.session
                fixture.start()

                fixture.stop()
                session.transport.activeRealmRoutes() shouldBe emptySet()
                fixture.databaseOpen shouldBe false

                fixture.start()
                session.transport.activeRealmRoutes() shouldBe realmRoutes
            } finally {
                fixture.close()
            }
        }
    }

    test("messaging replacement preserves the Realm runtime and swaps routers") {
        runTest {
            val fixture = RealmLifecycleFixture(this)
            try {
                val first = fixture.session(1)
                fixture.messaging.value = first.session
                fixture.start()
                runCurrent()
                val routeCount = first.transport.activeSubscriptionCount
                routeCount shouldBeGreaterThan 0

                val second = fixture.session(2)
                fixture.messaging.value = second.session
                runCurrent()

                fixture.databaseOpen shouldBe true
                first.transport.activeSubscriptionCount shouldBe 0
                second.transport.activeSubscriptionCount shouldBe routeCount
            } finally {
                fixture.close()
            }
        }
    }

    test("failed router replacement closes the old router before retry succeeds") {
        runTest {
            val fixture = RealmLifecycleFixture(this)
            try {
                val first = fixture.session(1)
                fixture.messaging.value = first.session
                fixture.start()
                runCurrent()
                val routeCount = first.transport.activeSubscriptionCount

                val second = fixture.session(2)
                second.transport.failNextSubscribe(TransportError.Unavailable(IllegalStateException("not ready")))
                fixture.messaging.value = second.session
                runCurrent()

                first.transport.activeSubscriptionCount shouldBe 0
                second.transport.activeSubscriptionCount shouldBe 0
                fixture.delayScheduler.awaitRequest() shouldBe 1.seconds
                fixture.delayScheduler.resume()
                runCurrent()

                first.transport.activeSubscriptionCount shouldBe 0
                second.transport.activeSubscriptionCount shouldBe routeCount
            } finally {
                fixture.close()
            }
        }
    }

    test("terminal route loss is retried within the active messaging session") {
        runTest {
            val fixture = RealmLifecycleFixture(this)
            try {
                val session = fixture.session(1)
                fixture.messaging.value = session.session
                fixture.start()
                val routeCount = session.transport.activeSubscriptionCount

                session.transport.deliver(
                    com.typewritermc.services.libs.communicator.transport.TransportDelivery.Failure(
                        TransportError.Unavailable(IllegalStateException("connection lost")),
                    ),
                )
                runCurrent()

                session.transport.activeSubscriptionCount shouldBe 0
                fixture.delayScheduler.awaitRequest() shouldBe 1.seconds
                fixture.delayScheduler.resume()
                runCurrent()

                session.transport.activeSubscriptionCount shouldBe routeCount
            } finally {
                fixture.close()
            }
        }
    }

    test("disconnect closes responders and reconnect installs one replacement") {
        runTest {
            val fixture = RealmLifecycleFixture(this)
            try {
                val first = fixture.session(1)
                fixture.messaging.value = first.session
                fixture.start()
                val routeCount = first.transport.activeSubscriptionCount

                fixture.messaging.value = null
                runCurrent()
                first.transport.activeSubscriptionCount shouldBe 0

                val second = fixture.session(2)
                fixture.messaging.value = second.session
                runCurrent()
                second.transport.activeSubscriptionCount shouldBe routeCount

                val third = fixture.session(3)
                fixture.messaging.value = third.session
                runCurrent()
                second.transport.activeSubscriptionCount shouldBe 0
                third.transport.activeSubscriptionCount shouldBe routeCount
            } finally {
                fixture.close()
            }
        }
    }

    test("replacement cancellation closes the superseded router without duplicates") {
        runTest {
            val fixture = RealmLifecycleFixture(this)
            try {
                val closeStarted = Channel<Unit>(Channel.UNLIMITED)
                val allowClose = Channel<Unit>(Channel.UNLIMITED)
                val first = fixture.session(1)
                first.transport.closeSubscriptionWith(1) {
                    closeStarted.send(Unit)
                    allowClose.receive()
                }
                fixture.messaging.value = first.session
                fixture.start()
                val routeCount = first.transport.activeSubscriptionCount

                val second = fixture.session(2)
                fixture.messaging.value = second.session
                closeStarted.receive()

                val third = fixture.session(3)
                fixture.messaging.value = third.session
                allowClose.send(Unit)
                runCurrent()

                first.transport.activeSubscriptionCount shouldBe 0
                second.transport.activeSubscriptionCount shouldBe 0
                third.transport.activeSubscriptionCount shouldBe routeCount
            } finally {
                fixture.close()
            }
        }
    }

    test("shutdown closes every Realm responder") {
        runTest {
            val fixture = RealmLifecycleFixture(this)
            val session = fixture.session(1)
            fixture.messaging.value = session.session
            fixture.start()

            fixture.close()

            session.transport.activeSubscriptionCount shouldBe 0
            fixture.databaseOpen shouldBe false
        }
    }

    test("Realm start provisions the realm root and one instance of every section") {
        runTest {
            val incarnation = RealmCatalog().incarnation("lifecycle-structure")
            val fixture = RealmLifecycleFixture(this, catalog = incarnation)
            try {
                val session = fixture.session(1)
                fixture.messaging.value = session.session
                fixture.start()

                val response =
                    fixture.request(
                        session,
                        "editor.authoring.state.query",
                        QueryAuthoringStateRequest(
                            generation = incarnation.assembly.checked.generation,
                        ),
                        QueryAuthoringStateRequest.serializer,
                        QueryAuthoringStateResponse.serializer,
                    ) as QueryAuthoringStateResponse.StateWrapper
                val state =
                    response.value
                state.resources
                    .map {
                        it.content
                            .requireValid()
                            .configuration.definition
                    }.sortedBy { it.toString() } shouldBe
                    listOf(RealmRootDefinition.id, LibraryDefinition.id, TaxonomyDefinition.id).sortedBy { it.toString() }
            } finally {
                fixture.close()
            }
        }
    }

    test("Realm startup preserves unavailable authored data while serving unrelated resources") {
        runTest {
            val valid = TypeDefinitionId.qualified("lifecycle", "valid")
            val unavailable = TypeDefinitionId.qualified("lifecycle", "unavailable")
            val availableResource = ResourceId(value = "available")
            val unavailableResource = ResourceId(value = "unavailable")
            val availableRecord =
                AuthoringRecord.of(
                    TypeSelection.CompleteWrapper(valid.namedUse()),
                    mapOf("name" to DataValue.StringValueWrapper("Book")),
                )
            val unavailableRecord =
                AuthoringRecord.of(
                    TypeSelection.CompleteWrapper(unavailable.namedUse()),
                    mapOf("legacy" to DataValue.StringValueWrapper("preserved")),
                )
            val resources = mapOf(availableResource to availableRecord, unavailableResource to unavailableRecord)
            val incarnation = lifecycleIsolationCatalog(valid, unavailable)
            val fixture =
                RealmLifecycleFixture(
                    this,
                    catalog = incarnation,
                    initialSeed = AuthoringSeed(resources),
                )
            try {
                val session = fixture.session(1)
                fixture.messaging.value = session.session
                fixture.start()

                val catalogResult =
                    fixture.request(
                        session,
                        "editor.catalog.fetch",
                        CatalogFetchRequest(expectedGeneration = null),
                        CatalogFetchRequest.serializer,
                        CatalogFetchResult.serializer,
                    ) as CatalogFetchResult.CatalogWrapper
                val catalog =
                    catalogResult.value
                catalog.generation.value shouldBe incarnation.assembly.checked.generation.value
                catalog.types.map { it.definition.requireValid().id }.containsAll(listOf(valid, unavailable)) shouldBe
                    true

                val snapshotResult =
                    fixture.request(
                        session,
                        "editor.authoring.state.query",
                        QueryAuthoringStateRequest(
                            generation = incarnation.assembly.checked.generation,
                        ),
                        QueryAuthoringStateRequest.serializer,
                        QueryAuthoringStateResponse.serializer,
                    ) as QueryAuthoringStateResponse.StateWrapper
                val snapshot =
                    snapshotResult.value
                snapshot.resources.associate { resource ->
                    resource.id.value to resource.content.requireValid()
                } shouldBe
                    mapOf(
                        availableResource.value to availableRecord,
                        unavailableResource.value to unavailableRecord,
                    )
            } finally {
                fixture.close()
            }
        }
    }
}
