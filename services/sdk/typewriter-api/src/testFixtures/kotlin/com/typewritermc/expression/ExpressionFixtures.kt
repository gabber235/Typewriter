package com.typewritermc.expression

import build.skir.JsonFlavor
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.LocatedPortableValue
import com.typewritermc.authoring.locate
import com.typewritermc.authoring.name
import com.typewritermc.authoring.root
import com.typewritermc.configuration.ExpressionInference
import com.typewritermc.configuration.PortableExpressionChecker
import com.typewritermc.configuration.ruleProfileViolations
import com.typewritermc.expression.operations.CatalogPortableTypes
import com.typewritermc.expression.operations.CheckFailure
import com.typewritermc.expression.operations.EvaluatorFailure
import com.typewritermc.expression.operations.PortableOperationCatalog
import com.typewritermc.expression.operations.RoundingMode
import com.typewritermc.expression.operations.entryValue
import com.typewritermc.expression.operations.toDataValue
import com.typewritermc.testkit.repositoryFixture
import com.typewritermc.types.ColorDefinition
import com.typewritermc.types.actualType
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.resolve
import com.typewritermc.types.declared
import com.typewritermc.types.duration
import com.typewritermc.types.fields
import com.typewritermc.types.floatScalar
import com.typewritermc.types.integer
import com.typewritermc.types.integerScalar
import com.typewritermc.types.listValue
import com.typewritermc.types.mapValue
import com.typewritermc.types.named
import com.typewritermc.types.namedUse
import com.typewritermc.types.payload
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import com.typewritermc.types.requireValid
import com.typewritermc.types.setValue
import com.typewritermc.types.template
import com.typewritermc.types.timestamp
import com.typewritermc.types.use
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
import skirout.editor.v1.catalog.DeclarationStatus
import skirout.editor.v1.catalog.PublishedType
import skirout.editor.v1.catalog.ResourceAppearance
import skirout.editor.v1.catalog.TypeDisplay
import skirout.editor.v1.expression.EvaluationBudget
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.expression.ExpressionType
import skirout.editor.v1.expression.OperationId
import skirout.editor.v1.type_catalog.ArgumentSelection
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.FieldValue
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.LinkValue
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.MapRow
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.QualifiedTypeId
import skirout.editor.v1.type_catalog.RecordRepresentationTemplate
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.color.Color
import skirout.kernel.v1.icon.Icon
import skirout.kernel.v1.resource_id.ResourceId
import java.nio.file.Files
import kotlin.io.path.extension
import kotlin.io.path.listDirectoryEntries
import kotlin.io.path.name
import kotlin.io.path.readText
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Instant

/** Every read model definition: the Skir derived roots and the framework types they read. */
internal fun canonicalReadSchema(): List<TypeDefinition> = CanonicalReadModels.definitions + CanonicalReadModels.frameworkDefinitions

/** The text of [CANONICAL_READ_MODELS_FIXTURE]: [canonicalReadSchema] as readable Skir JSON. */
internal fun renderCanonicalReadSchema(): String =
    canonicalReadSchema().joinToString(",\n", "[\n", "\n]\n") { TypeDefinition.serializer.toJsonCode(it, JsonFlavor.READABLE) }

internal fun readId(record: String) =
    TypeDefinitionId(typeId = TypeId.QualifiedWrapper(QualifiedTypeId(namespace = CANONICAL_READ_NAMESPACE, name = record)), revision = 1)

internal fun declaredUse(id: TypeDefinitionId) = NamedTypeUse(definition = id, arguments = emptyList())

internal fun checkInput(
    binding: ExpressionBindingId,
    path: ValuePath = ValuePath.root,
): ExpressionNode = ExpressionNode.createInput(binding = binding, path = path)

internal fun checkLiteral(value: DataValue): ExpressionNode = ExpressionNode.LiteralWrapper(value)

internal fun checkCall(
    operation: String,
    vararg arguments: ExpressionNode,
    typeArguments: List<TypeTemplate> = emptyList(),
): ExpressionNode =
    ExpressionNode.createCall(operation = OperationId(value = operation), typeArguments = typeArguments, arguments = arguments.toList())

internal fun checkLambda(
    arity: Int,
    body: ExpressionNode,
): ExpressionNode = ExpressionNode.createLambda(arity = arity, body = body)

internal fun checkLocal(
    slot: Int,
    depth: Int = 0,
): ExpressionNode = ExpressionNode.createLocal(depth = depth, slot = slot, path = ValuePath.root)

internal val CASE_KEYS = setOf("id", "expression", "inputs", "check", "typeDefinitions", "resources", "budget", "expected")

internal val INPUT_KEYS = setOf("value", "type", "located")

internal val CHECK_KEYS = setOf("resultType", "failures", "inferredType")

internal val BUDGET_KEYS = setOf("maxSteps", "maxCollectionItems")

internal val OUTCOME_KEYS = setOf("available", "unavailable", "failed")

internal class FixtureInput(
    val value: DataValue,
    val type: ExpressionType?,
    val located: Boolean,
)

internal class FixtureCase(
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

internal fun fixtureCases(): List<FixtureCase> =
    repositoryFixture("skir-src/editor/v1/fixtures/operations")
        .listDirectoryEntries()
        .filter { it.extension == "json" }
        .sortedBy { it.name }
        .flatMap { file ->
            val document = Json.parseToJsonElement(file.readText()).jsonObject
            require(document.keys == setOf("cases")) { "${file.name} has keys besides cases: ${document.keys}." }
            document.getValue("cases").jsonArray.map { it.jsonObject.fixtureCase(file.name) }
        }

internal fun JsonObject.fixtureCase(file: String): FixtureCase {
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
        expression = ExpressionNode.serializer.fromJsonCode(getValue("expression").toString()),
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
                            type = input["type"]?.let { ExpressionType.serializer.fromJsonCode(it.toString()) },
                            located = input["located"]?.jsonPrimitive?.boolean ?: true,
                        )
                }.toMap(),
        check = check,
        definitions =
            this["typeDefinitions"]?.jsonArray.orEmpty().map { TypeDefinition.serializer.fromJsonCode(it.toString()).requireValid() },
        budget =
            EvaluationBudget(
                maxSteps = budget?.get("maxSteps")?.jsonPrimitive?.long ?: 1000,
                maxCollectionItems = budget?.get("maxCollectionItems")?.jsonPrimitive?.long ?: 1000,
            ),
        expected = expected,
    )
}

internal fun JsonObject.requireKeys(
    allowed: Set<String>,
    owner: String,
) {
    val unknown = keys - allowed
    require(unknown.isEmpty()) { "$owner has unknown keys $unknown." }
}

internal fun FixtureCase.checkWith(check: JsonObject) {
    val bindings =
        inputs.mapValues { (name, input) -> requireNotNull(input.type) { "Input ${name.value} of $id needs a type for check." } }
    val checker = PortableExpressionChecker(catalog::resolve)
    val failures =
        checker
            .checkExpressionCodes(expression, bindings, ExpressionType.serializer.fromJsonCode(check.getValue("resultType").toString()))
            .map { it.value }
    failures.sorted() shouldBe
        check
            .getValue("failures")
            .jsonArray
            .map { it.jsonPrimitive.content }
            .sorted()
    check["inferredType"]?.let {
        checker.inferExpression(expression, bindings) shouldBe
            ExpressionInference.Typed(ExpressionType.serializer.fromJsonCode(it.toString()))
    }
}

internal fun FixtureCase.evaluate() {
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

internal fun JsonObject.locations(key: String): List<String>? = this[key]?.jsonArray?.map { it.jsonPrimitive.content }

/** The compact location of the fixture format: the resource, then `.field`, `[item]`, `.#key` and `.#value`. */
internal fun ValueLocation.compact(): String =
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
internal fun JsonObject.compactValue(): DataValue {
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

internal fun JsonElement.items(): List<ListItem> =
    jsonArray.map { element ->
        val item = element.jsonObject
        item.requireKeys(setOf("id", "value"), "item")
        ListItem(id = ItemId(value = item.getValue("id").jsonPrimitive.content), value = item.getValue("value").jsonObject.compactValue())
    }

internal fun JsonElement.rows(): List<MapRow> =
    jsonArray.map { element ->
        val row = element.jsonObject
        row.requireKeys(setOf("id", "key", "value"), "row")
        MapRow(
            id = ItemId(value = row.getValue("id").jsonPrimitive.content),
            key = row.getValue("key").jsonObject.compactValue(),
            value = row.getValue("value").jsonObject.compactValue(),
        )
    }

internal fun JsonObject.link(): DataValue {
    requireKeys(setOf("endpoint", "resource"), "link")
    return DataValue.LinkWrapper(
        LinkValue(
            endpoint = EndpointId(value = getValue("endpoint").jsonPrimitive.content),
            target = LinkTarget(resource = ResourceId(value = getValue("resource").jsonPrimitive.content), opposite = null),
        ),
    )
}

internal fun JsonObject.named(): DataValue {
    requireKeys(setOf("declared", "namespace", "name", "revision", "arguments", "payload"), "named value")
    val definition =
        this["declared"]?.let { TypeDefinitionId.declared(it.jsonPrimitive.content) }
            ?: TypeDefinitionId.qualified(
                getValue("namespace").jsonPrimitive.content,
                getValue("name").jsonPrimitive.content,
                this["revision"]?.jsonPrimitive?.int ?: 1,
            )
    val arguments = this["arguments"]?.jsonArray.orEmpty().map { TypeUse.serializer.fromJsonCode(it.toString()).requireValid() }
    return DataValue.named(definition.namedUse(arguments), getValue("payload").jsonObject.compactValue())
}
