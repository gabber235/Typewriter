package com.typewritermc.expression

import build.skir.JsonFlavor
import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.BoundCollectionPath
import com.typewritermc.authoring.BoundPath
import com.typewritermc.authoring.LocatedPortableValue
import com.typewritermc.authoring.locate
import com.typewritermc.authoring.name
import com.typewritermc.authoring.root
import com.typewritermc.checking.PartialSelection
import com.typewritermc.checking.TypedSelection
import com.typewritermc.configuration.ExpressionInference
import com.typewritermc.configuration.PortableExpressionChecker
import com.typewritermc.configuration.ruleProfileViolations
import com.typewritermc.expression.operations.CatalogPortableTypes
import com.typewritermc.expression.operations.EvaluatorFailure
import com.typewritermc.expression.operations.PortableOperationCatalog
import com.typewritermc.expression.operations.entryValue
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
import io.kotest.assertions.withClue
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
import skirout.editor.v1.type_catalog.CatalogGeneration
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
import java.nio.file.Files
import java.nio.file.Path
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
            case.expression.roundTrips()
            case.check?.let { case.checkWith(it) }
            if (case.expression.ruleProfileViolations().isEmpty()) case.evaluate()
        }
    }
}

private val CASE_KEYS = setOf("id", "expression", "inputs", "check", "typeDefinitions", "resources", "budget", "expected")
private val INPUT_KEYS = setOf("value", "type", "located")
private val CHECK_KEYS = setOf("resultType", "failures", "inferredType")
private val BUDGET_KEYS = setOf("maxSteps", "maxCollectionItems")
private val OUTCOME_KEYS = setOf("available", "unavailable", "failed")

private class FixtureInput(
    val value: DataValue,
    val type: ExpressionType?,
    val located: Boolean,
)

private class FixtureCase(
    val file: String,
    val id: String,
    val expression: ExpressionNode,
    val inputs: Map<ExpressionBindingId, FixtureInput>,
    val check: JsonObject?,
    val definitions: List<TypeDefinition>,
    val budget: EvaluationBudget,
    val expected: JsonObject,
) {
    val expectedFailure: String? get() = expected["failed"]?.jsonPrimitive?.content

    val catalog by lazy { testCatalog(definitions) }
}

private fun fixtureCases(): List<FixtureCase> =
    fixtureDirectory()
        .listDirectoryEntries()
        .filter { it.extension == "json" }
        .sortedBy { it.name }
        .flatMap { file ->
            val document = Json.parseToJsonElement(file.readText()).jsonObject
            require(document.keys == setOf("cases")) { "${file.name} has keys besides cases: ${document.keys}." }
            document.getValue("cases").jsonArray.map { it.jsonObject.fixtureCase(file.name) }
        }

private fun fixtureDirectory(): Path =
    generateSequence(Path.of("").toAbsolutePath()) { it.parent }
        .map { it.resolve("skir-src/editor/v1/fixtures/operations") }
        .first(Files::isDirectory)

private fun JsonObject.fixtureCase(file: String): FixtureCase {
    val id = getValue("id").jsonPrimitive.content
    requireKeys(CASE_KEYS, "$file case $id")
    val check = this["check"]?.jsonObject?.also { it.requireKeys(CHECK_KEYS, "$file case $id check") }
    val budget = this["budget"]?.jsonObject?.also { it.requireKeys(BUDGET_KEYS, "$file case $id budget") }
    val expected = getValue("expected").jsonObject
    expected.requireKeys(OUTCOME_KEYS + "reads", "$file case $id expected")
    require("reads" in expected) { "$file case $id expects no reads; write an empty list." }
    require(expected.keys.count { it in OUTCOME_KEYS } == 1) { "$file case $id expects exactly one outcome." }
    return FixtureCase(
        file = file,
        id = id,
        expression = ExpressionNode.serializer.fromJson(getValue("expression")),
        inputs =
            this["inputs"]
                ?.jsonObject
                .orEmpty()
                .map { (name, encoded) ->
                    val input = encoded.jsonObject
                    input.requireKeys(INPUT_KEYS, "$file case $id input $name")
                    ExpressionBindingId(value = name) to
                        FixtureInput(
                            value = input.getValue("value").jsonObject.compactValue(),
                            type = input["type"]?.let { ExpressionType.serializer.fromJson(it) },
                            located = input["located"]?.jsonPrimitive?.boolean ?: true,
                        )
                }.toMap(),
        check = check,
        definitions =
            this["typeDefinitions"]?.jsonArray.orEmpty().map { TypeDefinition.serializer.fromJson(it).requireValid() },
        budget =
            EvaluationBudget(
                maxSteps = budget?.get("maxSteps")?.jsonPrimitive?.long ?: 1000,
                maxCollectionItems = budget?.get("maxCollectionItems")?.jsonPrimitive?.long ?: 1000,
            ),
        expected = expected,
    )
}

private fun JsonObject.requireKeys(
    allowed: Set<String>,
    owner: String,
) {
    val unknown = keys - allowed
    require(unknown.isEmpty()) { "$owner has unknown keys $unknown." }
}

/** Compares encodings rather than values, so a non portable literal such as NaN still round trips. */
private fun ExpressionNode.roundTrips() {
    val serializer = ExpressionNode.serializer
    val readable = serializer.toJsonCode(this, JsonFlavor.READABLE)
    withClue("readable JSON") { serializer.toJsonCode(serializer.fromJsonCode(readable), JsonFlavor.READABLE) shouldBe readable }
    withClue("dense JSON") {
        serializer.toJsonCode(serializer.fromJsonCode(serializer.toJsonCode(this)), JsonFlavor.READABLE) shouldBe readable
    }
    withClue("binary") { serializer.toJsonCode(serializer.fromBytes(serializer.toBytes(this)), JsonFlavor.READABLE) shouldBe readable }
}

private fun FixtureCase.checkWith(check: JsonObject) {
    val bindings =
        inputs.mapValues { (name, input) -> requireNotNull(input.type) { "Input ${name.value} of $id needs a type for check." } }
    val checker = PortableExpressionChecker(catalog::resolve)
    val failures =
        checker
            .checkExpressionCodes(expression, bindings, ExpressionType.serializer.fromJson(check.getValue("resultType")))
            .map { it.value }
    failures.sorted() shouldBe
        check
            .getValue("failures")
            .jsonArray
            .map { it.jsonPrimitive.content }
            .sorted()
    check["inferredType"]?.let {
        checker.inferExpression(expression, bindings) shouldBe
            ExpressionInference.Typed(ExpressionType.serializer.fromJson(it))
    }
}

private fun FixtureCase.evaluate() {
    val located = inputs.filterValues { it.located }
    val reads = mutableListOf<ValueLocation>()
    val evaluator =
        DefaultExpressionEvaluator(
            ExpressionValueReader { location ->
                reads += location
                val root = located.getValue(ExpressionBindingId(value = location.resource.value)).value
                when (val selected = root.locate(location.path)) {
                    is LocatedPortableValue.Value -> Availability.Available(selected.value)
                    is LocatedPortableValue.Row -> Availability.Available(entryValue(selected.row.key, selected.row.value))
                    else -> Availability.Unavailable(listOf(location))
                }
            },
            CatalogPortableTypes(catalog),
        )
    val result =
        with(FixtureReads) {
            evaluator.evaluateScoped(
                expression,
                ExpressionBindings(
                    located.keys.associateWith { ValueLocation(resource = ResourceId(value = it.value), path = ValuePath.root) },
                ),
                inputs.filterValues { !it.located }.mapValues { it.value.value },
                budget,
            )
        }
    when {
        "available" in expected -> {
            result shouldBe Availability.Available(expected.getValue("available").jsonObject.compactValue())
        }

        "unavailable" in expected -> {
            (result as? Availability.Unavailable)?.locations?.map { it.compact() } shouldBe expected.locations("unavailable")
        }

        else -> {
            (result as? Availability.Failed)?.diagnostic?.failure?.value shouldBe expectedFailure
        }
    }
    reads.distinct().map { it.compact() } shouldBe expected.locations("reads")
}

private fun JsonObject.locations(key: String): List<String>? = this[key]?.jsonArray?.map { it.jsonPrimitive.content }

/** The compact location of the fixture format: the resource, then `.field`, `[item]`, `.#key` and `.#value`. */
private fun ValueLocation.compact(): String =
    resource.value +
        path.segments.joinToString("") { segment ->
            when (segment) {
                is PathSegment.FieldWrapper -> ".${segment.name}"
                is PathSegment.ItemWrapper -> "[${segment.value.id.value}]"
                PathSegment.MAP_KEY -> ".#key"
                PathSegment.MAP_VALUE -> ".#value"
                else -> error("Unknown path segment $segment.")
            }
        }

/** Decodes the compact value notation of the fixture format, one key per value. */
private fun JsonObject.compactValue(): DataValue {
    require(size == 1) { "A compact value has exactly one key: $this." }
    val (kind, encoded) = entries.single()
    return when (kind) {
        "null" -> DataValue.NULL
        "unfilled" -> DataValue.UNFILLED
        "unit" -> DataValue.UNIT
        "boolean" -> DataValue.BooleanWrapper(encoded.jsonPrimitive.boolean)
        "integer" -> DataValue.integer(encoded.jsonPrimitive.content.toBigInteger())
        "float" -> DataValue.FloatWrapper(encoded.jsonPrimitive.double)
        "decimal" -> DataValue.DecimalWrapper(encoded.jsonPrimitive.content)
        "string" -> DataValue.StringValueWrapper(encoded.jsonPrimitive.content)
        "bytes" -> DataValue.BytesWrapper(requireNotNull(encoded.jsonPrimitive.content.decodeBase64()) { "Invalid base64 bytes." })
        "timestamp" -> DataValue.timestamp(Instant.parse(encoded.jsonPrimitive.content))
        "duration" -> DataValue.duration(encoded.jsonPrimitive.long.milliseconds)
        "enum_case" -> DataValue.EnumCaseWrapper(encoded.jsonPrimitive.content)
        "record" -> DataValue.record(encoded.jsonObject.mapValues { (_, value) -> value.jsonObject.compactValue() })
        "list" -> DataValue.listValue(encoded.items())
        "set" -> DataValue.setValue(encoded.items())
        "map" -> DataValue.mapValue(encoded.rows())
        "link" -> encoded.jsonObject.link()
        "named" -> encoded.jsonObject.named()
        else -> error("Unknown compact value kind $kind.")
    }
}

private fun JsonElement.items(): List<ListItem> =
    jsonArray.map { element ->
        val item = element.jsonObject
        item.requireKeys(setOf("id", "value"), "item")
        ListItem(id = ItemId(value = item.getValue("id").jsonPrimitive.content), value = item.getValue("value").jsonObject.compactValue())
    }

private fun JsonElement.rows(): List<MapRow> =
    jsonArray.map { element ->
        val row = element.jsonObject
        row.requireKeys(setOf("id", "key", "value"), "row")
        MapRow(
            id = ItemId(value = row.getValue("id").jsonPrimitive.content),
            key = row.getValue("key").jsonObject.compactValue(),
            value = row.getValue("value").jsonObject.compactValue(),
        )
    }

private fun JsonObject.link(): DataValue {
    requireKeys(setOf("endpoint", "resource"), "link")
    return DataValue.LinkWrapper(
        LinkValue(
            endpoint = EndpointId(value = getValue("endpoint").jsonPrimitive.content),
            target = LinkTarget(resource = ResourceId(value = getValue("resource").jsonPrimitive.content), opposite = null),
        ),
    )
}

private fun JsonObject.named(): DataValue {
    requireKeys(setOf("declared", "namespace", "name", "revision", "arguments", "payload"), "named value")
    val definition =
        this["declared"]?.let { TypeDefinitionId.declared(it.jsonPrimitive.content) }
            ?: TypeDefinitionId.qualified(
                getValue("namespace").jsonPrimitive.content,
                getValue("name").jsonPrimitive.content,
                this["revision"]?.jsonPrimitive?.int ?: 1,
            )
    val arguments = this["arguments"]?.jsonArray.orEmpty().map { TypeUse.serializer.fromJson(it).requireValid() }
    return DataValue.named(definition.namedUse(arguments), getValue("payload").jsonObject.compactValue())
}

internal object FixtureReads : AuthoredReads {
    override val catalog = CatalogGeneration(value = "expression fixture")
    override val readContext = com.typewritermc.authoring.ReadContext(catalog)

    override fun <T> read(path: BoundPath<T>): Availability<T> = error("Fixture expressions use ExpressionValueReader.")

    override fun <T> readRepresentation(
        path: BoundPath<*>,
        representation: TypeUse,
    ): Availability<T> = error("Fixture expressions use ExpressionValueReader.")

    override fun presence(path: BoundPath<*>): Availability<Boolean> = error("Fixture expressions use ExpressionValueReader.")

    override fun binding(path: BoundPath<*>): Availability<com.typewritermc.authoring.DraftBinding> =
        error("Fixture expressions use ExpressionValueReader.")

    override fun canonicalValueKey(path: BoundPath<*>): Availability<String> = error("Fixture expressions use ExpressionValueReader.")

    override fun members(path: BoundCollectionPath): List<ItemId> = emptyList()

    override fun <D> select(query: TypedSelection<D>): PartialSelection<D> = error("Fixture expressions do not select resources.")
}
