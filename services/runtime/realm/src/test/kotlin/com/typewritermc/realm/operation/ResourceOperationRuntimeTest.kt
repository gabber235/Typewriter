@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.operation

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.ResourceDraft
import com.typewritermc.authoring.boundPath
import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.authoring.with
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.discovery.contributionKey
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.library.TagDefinition
import com.typewritermc.library.tag
import com.typewritermc.library.taxonomy
import com.typewritermc.operations.AnyResourceSubjects
import com.typewritermc.operations.OperationInput
import com.typewritermc.operations.OperationInvocation
import com.typewritermc.operations.PreparationChoices
import com.typewritermc.operations.authored
import com.typewritermc.operations.capability
import com.typewritermc.operations.collectOperation
import com.typewritermc.operations.requireAuthored
import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.realm.routes.ResourceOperationRoutes
import com.typewritermc.realm.testing.RealmCatalog
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.realm.testing.text
import com.typewritermc.realm.testing.withSetup
import com.typewritermc.setup.setup
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.toResourceIds
import com.typewritermc.types.toSkir
import com.typewritermc.types.type
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.authoring.AuthoringObservationId
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.capability.InvocationId
import skirout.editor.v1.operation.OperationAvailability
import skirout.editor.v1.resource_operations.OperationOrigin
import skirout.editor.v1.resource_operations.OperationResourceUpsert
import skirout.editor.v1.resource_operations.OperationWorkingContext
import skirout.editor.v1.resource_operations.OperationWorkingOverlay
import skirout.editor.v1.resource_operations.ResolveResourceOperationsRequest
import skirout.editor.v1.resource_operations.ResolveResourceOperationsResult
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ResourceTarget
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId
import skirout.editor.v1.resource_operations.OperationInvocation as WireInvocation

private const val DECLARATION = "fixture.InlineOperations"

private val questTag = setup("quest-tag") { taxonomy { tags.tag("quest") { name = "Quest" } } }

/** The origin the suffix operation is declared under, so failures can name it. */
private val origin =
    ProviderOrigin(
        skirout.editor.v1.type_catalog.DeclarationOwner(
            source = contributionKey(ContributionSourceId("operation-test"), "main", ProducerId("test"), ContributionName("inline")),
            localIdentity = DECLARATION,
        ),
        ArtifactId("fixture:operations"),
        "main",
    )

private fun nameOf(tag: ResourceId) = ValueLocation.of(tag, ValuePath.root.field("name"))

/**
 * Appends "!" to the name of every selected tag. It is unavailable while a name is unfilled, fails availability for
 * the name "availability-failure", and refuses to prepare for the name "reject".
 */
private val suffix =
    collectOperation<ResourceDraft, Unit>(
        origin,
        DECLARATION,
        ResourceTarget.type(TagDefinition.id.namedTemplate()),
        AnyResourceSubjects,
        OperationInput.None,
        "Inline operations",
    ) { spec ->
        with(spec) {
            appearance { label("Add suffix") }
            availableWhen {
                val names = drafts.map { read(boundPath<String>(nameOf(it.id.toSkir()), ScalarKind.TEXT.use)) }
                val state = authored(names)
                if (state != OperationAvailability.ENABLED) return@availableWhen state
                require(names.map { requireAuthored(it) }.none { it == "availability-failure" }) { "Availability provider failed" }
                OperationAvailability.ENABLED
            }
            prepare {
                for (subject in subjects) {
                    val previous = requireAuthored(read(boundPath<String>(nameOf(subject.toSkir()), ScalarKind.TEXT.use)))
                    require(previous != "reject") { "The complete selection cannot be changed" }
                    checkedSet(nameOf(subject.toSkir()), DataValue.StringValueWrapper("$previous!"))
                }
            }
        }
    }

private val withSuffix = RealmCatalog(operations = { listOf(suffix) })

/** The suffix operation run through the runtime for [tag], against the saved state plus [named] as a working name. */
private class SuffixRun(
    private val realm: RealmFixture,
    private val tag: ResourceId,
) {
    val runtime = ResourceOperationRuntime(realm.views)
    val invocation = OperationInvocation("suffix", listOf(tag).toResourceIds())
    val observation = realm.views.read { it.observationId }
    val capability =
        realm.views.read { root ->
            root.catalog.operations.operations
                .single { it.definition.id.declaration == DECLARATION }
                .definition.id.capability
        }

    /** The saved tag with its name replaced by [name], as the panel's working overlay sends it. */
    fun named(name: DataValue) = mapOf(tag to realm.resources.getValue(tag).with("name", name))

    fun resolve(name: DataValue) = runtime.resolve(invocation, realm.generation, observation, named(name), emptySet())

    suspend fun prepare(name: String): OperationPreparationResult =
        runtime.prepare(
            invocation,
            realm.generation,
            capability,
            observation,
            named(DataValue.StringValueWrapper(name)),
            emptySet(),
            null,
            PreparationChoices(),
        )

    fun availability(name: DataValue) = resolve(name).operations.single { it.definition.id.declaration == DECLARATION }.availability
}

val ResourceOperationRuntimeTest by testSuite {
    test("an operation's availability is evaluated on the working values") {
        withSetup(questTag, catalog = withSuffix) { tag ->
            val run = SuffixRun(this, tag.id.toSkir())

            run.availability(DataValue.StringValueWrapper("Draft")) shouldBe OperationAvailability.ENABLED
            run.availability(DataValue.UNFILLED).shouldBeInstanceOf<OperationAvailability.DisabledWrapper>()
        }
    }

    test("a preview prepared on a working value commits only once that value is saved") {
        withSetup(questTag, catalog = withSuffix) { handle ->
            val tag = handle.id.toSkir()
            val preview = SuffixRun(this, tag).prepare("Draft").shouldBeInstanceOf<OperationPreparationResult.Preview>()
            resources.getValue(tag).text("name") shouldBe "Quest"

            commit(preview.edit).shouldBeInstanceOf<CommitPreparedEditResponse.ConflictErrorWrapper>()
            commit(EditIntent.createSetValue(at = nameOf(tag), value = DataValue.StringValueWrapper("Draft"))).shouldBeCommitted()
            commit(preview.edit).shouldBeCommitted()

            resources.getValue(tag).text("name") shouldBe "Draft!"
        }
    }

    test("a prepare callback that refuses fails with its reason and saves nothing") {
        withSetup(questTag, catalog = withSuffix) { tag ->
            val before = resources

            val failed = SuffixRun(this, tag.id.toSkir()).prepare("reject").shouldBeInstanceOf<OperationPreparationResult.Failed>()

            failed.cause.message shouldBe "The complete selection cannot be changed"
            resources shouldBe before
        }
    }

    test("a failing availability callback fails resolution with the declaration that failed") {
        withSetup(questTag, catalog = withSuffix) { tag ->
            val failure =
                shouldThrow<OperationResolutionFailure> {
                    SuffixRun(this, tag.id.toSkir()).resolve(DataValue.StringValueWrapper("availability-failure"))
                }

            failure.origin shouldBe origin
            failure.cause?.message shouldBe "Availability provider failed"
        }
    }

    test("a resolution the working values make fail answers with a diagnostic naming the declaration") {
        withSetup(questTag, catalog = withSuffix) { handle ->
            val tag = handle.id.toSkir()
            val routes = ResourceOperationRoutes(ResourceOperationRuntime(views), RealmRouteScope("organization", "realm"))
            val failing = resources.getValue(tag).with("name", DataValue.StringValueWrapper("availability-failure"))
            val request =
                ResolveResourceOperationsRequest(
                    invocation =
                        WireInvocation(
                            invocationId = InvocationId(value = "suffix"),
                            catalog = generation,
                            targets = listOf(tag),
                            origin = OperationOrigin(container = null, occurrences = emptyList()),
                        ),
                    context =
                        OperationWorkingContext(
                            confirmedObservation = AuthoringObservationId(value = views.read { it.observationId }),
                            overlay =
                                OperationWorkingOverlay(
                                    upserts = listOf(OperationResourceUpsert(resource = tag, content = failing)),
                                    removals = emptyList(),
                                ),
                        ),
                )

            routes
                .resolve(request)
                .shouldBeInstanceOf<ResolveResourceOperationsResult.FailedErrorWrapper>()
                .value.diagnostics
                .single()
                .message shouldContain DECLARATION
        }
    }
}
