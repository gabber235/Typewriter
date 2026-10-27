package com.typewritermc.expression

import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.LocatedPortableValue
import com.typewritermc.authoring.locate
import com.typewritermc.authoring.name
import com.typewritermc.authoring.root
import com.typewritermc.configuration.ExpressionInference
import com.typewritermc.configuration.PortableExpressionChecker
import com.typewritermc.configuration.ruleProfileViolations
import com.typewritermc.expression.operations.CatalogPortableTypes
import com.typewritermc.expression.operations.EvaluatorFailure
import com.typewritermc.expression.operations.PortableOperationCatalog
import com.typewritermc.expression.operations.entryValue
import com.typewritermc.testkit.repositoryFixture
import com.typewritermc.types.catalog.resolve
import com.typewritermc.types.declared
import com.typewritermc.types.duration
import com.typewritermc.types.integer
import com.typewritermc.types.listValue
import com.typewritermc.types.mapValue
import com.typewritermc.types.named
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import com.typewritermc.types.requireValid
import com.typewritermc.types.setValue
import com.typewritermc.types.timestamp
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.boolean
import kotlinx.serialization.json.double
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.long
import okio.ByteString.Companion.decodeBase64
import skirout.editor.v1.expression.EvaluationBudget
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.expression.ExpressionType
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.LinkValue
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.MapRow
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId
import kotlin.io.path.extension
import kotlin.io.path.listDirectoryEntries
import kotlin.io.path.name
import kotlin.io.path.readText
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Instant

/**
 * Runs the shared operation fixture (skir-src/editor/v1/fixtures/operations) on Kotlin: every case round trips through
 * JSON and binary, cases with a `check` run through the checker, and cases whose calls are all profile rule evaluate
 * against the expected result and reads. The panel runs the same cases, so both hosts agree with one expectation.
 */
val PortableExpressionFixtureTest by testSuite {
    val cases = fixtureCases()

    test("fixture case ids are unique across every file") {
        cases.groupBy { it.id }.filterValues { it.size > 1 }.keys shouldBe emptySet()
    }

    test("every declared operation and failure has a fixture case") {
        val called =
            cases
                .flatMap { case ->
                    case.expression
                        .descendants()
                        .filterIsInstance<ExpressionNode.CallWrapper>()
                        .toList()
                }.map { it.value.operation.value }
                .toSet()
        val failed = cases.mapNotNull { it.expectedFailure }.toSet()
        PortableOperationCatalog.declarations.map { it.id.value }.filterNot(called::contains) shouldBe emptyList()
        PortableOperationCatalog.declarations
            .flatMap { it.failures }
            .map { it.value }
            .distinct()
            .filterNot(failed::contains) shouldBe emptyList()
        val uncoverable = setOf(EvaluatorFailure.OutsideRuleProfile.value, EvaluatorFailure.UnknownExpression.value)
        EvaluatorFailure.all.map { it.value }.filterNot { it in uncoverable || it in failed } shouldBe emptyList()
    }

    cases.forEach { case ->
        test("${case.file}: ${case.id}") {
            case.check?.let { case.checkWith(it) }
            if (case.expression.ruleProfileViolations().isEmpty()) case.evaluate()
        }
    }
}
