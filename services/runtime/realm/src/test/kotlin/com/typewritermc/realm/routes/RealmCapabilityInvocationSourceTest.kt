package com.typewritermc.realm.routes

import com.typewritermc.capability.RealmCapabilityRegistry
import com.typewritermc.realm.catalog.RealmCatalogStore
import com.typewritermc.realm.routeFixtureCatalog
import com.typewritermc.testing.routes.FixtureCapabilities
import com.typewritermc.testing.routes.FixtureMessage
import com.typewritermc.testkit.CatalogEncoder
import com.typewritermc.types.toTemplate
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.capability.CapabilityDefinition
import skirout.editor.v1.capability.CapabilityInvocationRequest
import skirout.editor.v1.capability.CommandResult
import skirout.editor.v1.capability.ComputationResult
import skirout.editor.v1.capability.InvocationId
import skirout.editor.v1.capability.NotificationSeverity
import skirout.editor.v1.capability.PanelInstruction
import skirout.editor.v1.diagnostic.Diagnostic
import skirout.editor.v1.type_catalog.CapabilityId
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue

val RealmCapabilityInvocationSourceTest by testSuite {
    test("a computation returns the value its capability computes") {
        capabilities {
            computation(echo).shouldBeInstanceOf<ComputationResult.SuccessWrapper>().value.value shouldBe
                message("hello")
        }
    }

    test("a computation for another catalog generation is stale and names the current generation") {
        capabilities {
            computation(echo.copy(generation = CatalogGeneration(value = "older")))
                .shouldBeInstanceOf<ComputationResult.StaleGenerationErrorWrapper>()
                .value.actualGeneration.value shouldBe GENERATION
        }
    }

    test("a computation without its expected result type is invalid") {
        capabilities {
            computation(echo.copy(expectedResultType = null))
                .shouldBeInstanceOf<ComputationResult.InvalidErrorWrapper>()
                .value.diagnostics.messages shouldContainExactly listOf("Realm computation result type is required")
        }
    }

    test("a computation addressed to a command capability is invalid") {
        capabilities {
            computation(echo.copy(capabilityId = announce.capabilityId))
                .shouldBeInstanceOf<ComputationResult.InvalidErrorWrapper>()
                .value.diagnostics.messages shouldContainExactly listOf("Realm computation capability is unavailable")
        }
    }

    test("a computation whose capability refuses the author is permission denied with the capability's reason") {
        capabilities {
            computation(echo.copy(payload = message(FixtureCapabilities.DENIED)))
                .shouldBeInstanceOf<ComputationResult.PermissionDeniedErrorWrapper>()
                .value.message shouldBe "Fixture capability denied"
        }
    }

    test("a computation whose capability fails is unavailable with the failure's reason") {
        capabilities {
            computation(echo.copy(payload = message(FixtureCapabilities.BROKEN)))
                .shouldBeInstanceOf<ComputationResult.UnavailableErrorWrapper>()
                .value.diagnostics.messages shouldContainExactly listOf("Fixture capability broke")
        }
    }

    test("a computation while no catalog is installed is unavailable") {
        runTest {
            RealmCatalogStore().use { catalogs ->
                RealmCapabilityInvocationSource(catalogs)
                    .computation(CapabilityInvocationRequest.partial())
                    .shouldBeInstanceOf<ComputationResult.UnavailableErrorWrapper>()
                    .value.diagnostics.messages shouldContainExactly listOf("Realm catalog is unavailable")
            }
        }
    }

    test("a command returns the instructions its capability sends the panel") {
        capabilities {
            command(announce).shouldBeInstanceOf<CommandResult.SuccessWrapper>().value.instructions shouldContainExactly
                listOf(PanelInstruction.createNotify(severity = NotificationSeverity.SUCCESS, message = "hello"))
        }
    }

    test("a command for another catalog generation is stale and names the current generation") {
        capabilities {
            command(announce.copy(generation = CatalogGeneration(value = "older")))
                .shouldBeInstanceOf<CommandResult.StaleGenerationErrorWrapper>()
                .value.actualGeneration.value shouldBe GENERATION
        }
    }

    test("a command that expects a result type is invalid") {
        capabilities {
            command(announce.copy(expectedResultType = echo.expectedResultType))
                .shouldBeInstanceOf<CommandResult.InvalidErrorWrapper>()
                .value.diagnostics.messages shouldContainExactly listOf("Realm command result type must be absent")
        }
    }

    test("a command without a payload is invalid") {
        capabilities {
            command(announce.copy(payload = DataValue.UNKNOWN))
                .shouldBeInstanceOf<CommandResult.InvalidErrorWrapper>()
                .value.diagnostics.messages shouldContainExactly listOf("Capability payload is missing")
        }
    }

    test("a command whose capability refuses the author is permission denied with the capability's reason") {
        capabilities {
            command(announce.copy(payload = message(FixtureCapabilities.DENIED)))
                .shouldBeInstanceOf<CommandResult.PermissionDeniedErrorWrapper>()
                .value.message shouldBe "Fixture capability denied"
        }
    }

    test("a command whose capability fails is unavailable with the failure's reason") {
        capabilities {
            command(announce.copy(payload = message(FixtureCapabilities.BROKEN)))
                .shouldBeInstanceOf<CommandResult.UnavailableErrorWrapper>()
                .value.diagnostics.messages shouldContainExactly listOf("Fixture capability broke")
        }
    }
}

private const val GENERATION = "capabilities"

/** The route fixture capabilities installed in a Realm catalog, with valid requests for each of them. */
private class Capabilities(
    private val source: RealmCapabilityInvocationSource,
    val message: (String) -> DataValue,
    val echo: CapabilityInvocationRequest,
    val announce: CapabilityInvocationRequest,
) {
    suspend fun computation(request: CapabilityInvocationRequest) = source.computation(request)

    suspend fun command(request: CapabilityInvocationRequest) = source.command(request)
}

private fun capabilities(block: suspend Capabilities.() -> Unit) =
    runTest {
        RealmCatalogStore().use { catalogs ->
            catalogs.replace(routeFixtureCatalog.incarnation(GENERATION))
            catalogs.captureCurrent().use { lease ->
                val definitions = RealmCapabilityRegistry(lease.capabilities).definitions
                val computation = definitions.filterIsInstance<CapabilityDefinition.ComputationWrapper>().single().value
                val command = definitions.filterIsInstance<CapabilityDefinition.CommandWrapper>().single().value
                val encoder = CatalogEncoder(lease.checked, lease.nativeBindings)
                val message = { value: String -> encoder.encode(computation.requestType, FixtureMessage(value)) }

                fun request(id: CapabilityId) =
                    CapabilityInvocationRequest(
                        invocationId = InvocationId(value = "invocation"),
                        generation = CatalogGeneration(value = GENERATION),
                        capabilityId = id,
                        payload = message("hello"),
                        expectedResultType = null,
                    )
                Capabilities(
                    source = RealmCapabilityInvocationSource(catalogs),
                    message = message,
                    echo = request(computation.capabilityId).copy(expectedResultType = computation.resultType.toTemplate()),
                    announce = request(command.capabilityId),
                ).block()
            }
        }
    }

private val List<Diagnostic>.messages get() = map(Diagnostic::message)
