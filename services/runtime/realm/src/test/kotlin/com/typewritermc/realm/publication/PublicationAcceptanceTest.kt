package com.typewritermc.realm.publication

import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.of
import com.typewritermc.checking.RealmCheckProvider
import com.typewritermc.checking.RealmChecks
import com.typewritermc.checking.ResourceTypeMatch
import com.typewritermc.checking.TypedSelection
import com.typewritermc.checking.check
import com.typewritermc.realm.authoring.CapturedAuthoringReads
import com.typewritermc.realm.authoring.RealmServices
import com.typewritermc.realm.authoring.SelectionPredicateEvaluator
import com.typewritermc.realm.authoring.TEST_DEFINITIONS
import com.typewritermc.realm.authoring.TEST_TYPE
import com.typewritermc.realm.authoring.TestDraftType
import com.typewritermc.realm.authoring.record
import com.typewritermc.realm.checking.RealmCheckRuntime
import com.typewritermc.realm.testing.DefinitionCatalog
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.checksOf
import com.typewritermc.realm.testing.recordBinding
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId

val PublicationAcceptanceTest by testSuite {
    val firstResource = ResourceId(value = "first")

    test("a resource whose native construction fails blocks publication with native_construction_failed") {
        val catalog =
            DefinitionCatalog(
                TEST_DEFINITIONS,
                nativeBindingFactories = listOf(recordBinding(TEST_TYPE) { error("The native resource cannot be built.") }),
            )

        val assessment =
            RealmFixture.of(catalog, mapOf(firstResource to record(name = "ready"))).use { realm ->
                RealmCheckRuntime(realm.views).use { checks ->
                    val acceptance = AuthoringAcceptance(realm.views, checks)
                    acceptance.capture().use { captured -> acceptance.evaluate(captured) }
                }
            }

        assessment.resources.getValue(firstResource).shouldBeInstanceOf<ResourceReadiness.Blocked>()
        assessment.findings.map { Triple(it.code, it.message, it.primary) } shouldBe
            listOf(Triple("native_construction_failed", "The native resource cannot be built.", ValueLocation.of(firstResource)))
    }

    test("a captured check that cannot complete blocks publication with check_incomplete and check_coverage_incomplete") {
        val provider =
            object : RealmCheckProvider {
                override fun RealmChecks.register() {
                    realm {
                        select(
                            TypedSelection(
                                TestDraftType(ResourceTypeMatch.Definition(TEST_TYPE)),
                                ExpressionNode.LiteralWrapper(DataValue.BooleanWrapper(true)),
                            ),
                        )
                        check(Availability.Available(true)) { it }
                            .error("Never reported.", ValueLocation.of(firstResource))
                    }
                }
            }
        val catalog =
            DefinitionCatalog(
                TEST_DEFINITIONS,
                providers = checksOf(1, provider),
                nativeBindingFactories = listOf(recordBinding(TEST_TYPE)),
            )
        val traversalLimit =
            SelectionPredicateEvaluator { _, _, reads ->
                (reads as CapturedAuthoringReads).recordIncomplete("graph traversal limit exceeded")
                Availability.Available(true)
            }

        val assessment =
            RealmFixture
                .of(
                    catalog,
                    mapOf(firstResource to record(name = "ready")),
                    services = RealmServices(predicates = traversalLimit),
                ).use { realm ->
                    RealmCheckRuntime(realm.views).use { checks ->
                        val acceptance = AuthoringAcceptance(realm.views, checks)
                        acceptance.capture().use { captured -> acceptance.evaluate(captured) }
                    }
                }

        assessment.resources.getValue(firstResource).shouldBeInstanceOf<ResourceReadiness.Ready>()
        assessment.findings.map { it.code to it.message } shouldBe
            listOf(
                "check_incomplete" to "graph traversal limit exceeded",
                "check_coverage_incomplete" to "Required captured checks did not complete.",
            )
    }
}
