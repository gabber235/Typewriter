package com.typewritermc.realm

import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.discovery.CatalogAssemblyContext
import com.typewritermc.discovery.CatalogCallback
import com.typewritermc.discovery.CatalogCallbackFailure
import com.typewritermc.discovery.CatalogContributions
import com.typewritermc.discovery.ContributionKey
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.discovery.assemble
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.mainSpanBlocking
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import com.typewritermc.types.DeclarationOwner
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.catalog.toWire
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.string.shouldNotContain
import io.opentelemetry.api.common.AttributeKey
import skirout.editor.v1.catalog.EditorCatalog

val RealmCatalogReportingTest by testSuite {
    test("a callback cause has one correlated operator report") {
        val origin =
            ProviderOrigin(
                DeclarationOwner(
                    ContributionKey(ContributionSourceId("test"), "main", ProducerId("sdk"), ContributionName("failure")),
                    "ArticleConfiguration",
                ),
                ArtifactId("test:article"),
                "main",
            )
        val cause = IllegalArgumentException("fixture explanation")
        val target = TypeDefinitionId(TypeId.Qualified("test", "Article"), 1)
        val assembly =
            CatalogContributions(emptyList())
                .assemble(
                    CatalogAssemblyContext(CatalogGeneration("report")),
                ).copy(
                    callbackFailures =
                        listOf(
                            CatalogCallbackFailure(
                                origin,
                                CatalogCallback.Configuration(target),
                                cause,
                            ),
                        ),
                )
        TelemetryTestHarness.create().use { harness ->
            harness.telemetry.mainSpanBlocking("realm.catalog.assemble", ErrorSlug.of("realm-catalog-assembly-failed")) { main ->
                with(main) { assembly.reportCallbackFailures() }
            }
            val event =
                harness
                    .finishedSpans()
                    .single()
                    .events
                    .single { it.name == "catalog.callback.failed" }
            val log = harness.finishedLogs().single { it.eventName == "catalog.callback.failed" }
            event.attributes shouldBe log.attributes
            event.attributes
                .get(AttributeKey.stringKey("exception.stacktrace"))!!
                .shouldContain("fixture explanation")
            event.attributes.get(AttributeKey.stringKey("catalog.provider")) shouldBe "ArticleConfiguration"
            assembly.snapshot.toWire().let { wire ->
                EditorCatalog.serializer.toJsonCode(wire).shouldNotContain("fixture explanation")
            }
            harness.assertNoActiveSpans()
        }
    }
}
