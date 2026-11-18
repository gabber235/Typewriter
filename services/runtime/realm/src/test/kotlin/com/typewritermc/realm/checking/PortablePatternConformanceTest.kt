package com.typewritermc.realm.checking

import com.typewritermc.authoring.of
import com.typewritermc.realm.authoring.CapturedAuthoringReads
import com.typewritermc.realm.authoring.TEST_DEFINITIONS
import com.typewritermc.realm.authoring.TEST_TYPE
import com.typewritermc.realm.authoring.captured
import com.typewritermc.realm.authoring.location
import com.typewritermc.realm.catalog.CONTENT_RULE
import com.typewritermc.realm.testing.DefinitionCatalog
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.withClue
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import skirout.editor.v1.catalog.ConfigurationRecipe
import skirout.editor.v1.catalog.OwnedRule
import skirout.editor.v1.catalog.RuleDescriptor
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.diagnostic.DiagnosticTemplate
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.RelativeFieldPattern
import skirout.editor.v1.type_catalog.RuleId
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId

/**
 * Runs the shared pattern fixture (skir-src/editor/v1/fixtures/portable_pattern_conformance.json) on Realm: expansion
 * cases through [CapturedAuthoringReads.expand], rule cases through the portable rule branch of [RealmCheckRuntime].
 * The panel runs the same file, so both sides expand patterns and report rule outcomes alike.
 */
@OptIn(ExperimentalCoroutinesApi::class)
val PortablePatternConformanceTest by testSuite {
    val document = Json.parseToJsonElement(fixtureFile().toFile().readText()).jsonObject
    document.keys shouldBe setOf("expansions", "rules")

    document.getValue("expansions").jsonArray.map { it.jsonObject }.forEach { case ->
        val id = case.string("id")
        test("expansion $id") {
            case.keys shouldBe setOf("id", "value", "owner", "pattern", "expected")
            val owner = ResourceId(value = case.string("owner"))
            val expanded =
                captured(mapOf(owner to case.ownerRecord())) { lease ->
                    CapturedAuthoringReads(lease.originalView()).expand(
                        ValueLocation.of(owner),
                        RelativeFieldPattern.serializer.fromJsonCode(case.getValue("pattern").toString()),
                    )
                }
            expanded shouldBe case.locations("expected")
        }
    }

    document.getValue("rules").jsonArray.map { it.jsonObject }.forEach { case ->
        val id = case.string("id")
        test("rule $id") {
            runTest {
                case.keys shouldBe setOf("id", "value", "owner", "recipe", "predicate", "diagnostic", "expected")
                val owner = ResourceId(value = case.string("owner"))
                val origin = RuleOrigin(owner = TEST_TYPE, ordinal = 0)
                val diagnostic = case.getValue("diagnostic").jsonObject
                val recipe =
                    ConfigurationRecipe(
                        origin = origin,
                        relativePath = RelativeFieldPattern.serializer.fromJsonCode(case.getValue("recipe").toString()),
                        representationCondition = null,
                        rules =
                            listOf(
                                OwnedRule(
                                    id = RuleId(origin = origin, localIndex = 0),
                                    descriptor =
                                        RuleDescriptor(
                                            predicate = ExpressionNode.serializer.fromJsonCode(case.getValue("predicate").toString()),
                                        ),
                                    diagnostic =
                                        DiagnosticTemplate(
                                            code = diagnostic.string("code"),
                                            message = diagnostic.string("message"),
                                            severity =
                                                DiagnosticSeverity.serializer.fromJsonCode(
                                                    diagnostic.getValue("severity").toString(),
                                                ),
                                            targets =
                                                diagnostic.getValue("targets").jsonArray.map {
                                                    RelativeFieldPattern.serializer.fromJsonCode(it.toString())
                                                },
                                        ),
                                ),
                            ),
                    )
                checking(
                    DefinitionCatalog(TEST_DEFINITIONS, configuration = listOf(recipe)),
                    mapOf(owner to case.ownerRecord()),
                    StandardTestDispatcher(testScheduler),
                ) { _, runtime ->
                    runtime.settle()

                    // The cases seed records the test catalog does not fully declare; the content rule reports those apart.
                    val actual =
                        runtime
                            .findings()
                            .filter { it.ticket.instance.rule != CONTENT_RULE }
                            .associateBy { it.ticket.instance.location }
                    val expected = case.getValue("expected").jsonArray.map { it.jsonObject }
                    actual.keys shouldBe expected.map { compactLocation(it.string("subject")) }.toSet()
                    expected.forEach { entry ->
                        val subject = compactLocation(entry.string("subject"))
                        val set = actual.getValue(subject)
                        withClue("outcome of ${entry.string("subject")}") { set.outcome.compact() shouldBe entry.getValue("outcome") }
                        withClue("findings of ${entry.string("subject")}") {
                            set.findings.map { it.compact() } shouldBe entry.getValue("findings").jsonArray.toList()
                        }
                    }
                }
            }
        }
    }
}
