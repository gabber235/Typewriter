package com.typewritermc.expression

import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.BoundCollectionPath
import com.typewritermc.authoring.BoundPath
import com.typewritermc.authoring.ItemId
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.PartialSelection
import com.typewritermc.checking.TypedSelection
import com.typewritermc.presentation.ExpressionNode
import com.typewritermc.types.DataValue
import com.typewritermc.types.ListItem
import com.typewritermc.types.MapRow
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeUse
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.boolean
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import java.nio.file.Files
import java.nio.file.Path
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Instant

val PortableExpressionFixtureTest by testSuite {
    test("local candidates use the shared evaluator without authored reads") {
        var reads = 0
        val evaluator = DefaultExpressionEvaluator(ExpressionValueReader { reads++; Availability.Available(DataValue.StringValue("stored")) })
        val candidate = ExpressionBindingId("candidate")
        val expression = ExpressionNode.Call(OperationId("typewriter.text.trim"), listOf(ExpressionNode.Read(candidate, ValuePath())))
        with(FixtureReads) {
            evaluator.evaluateScoped(expression, ExpressionBindings(emptyMap()), mapOf(candidate to DataValue.StringValue("  local  ")), EvaluationBudget(20, 20))
        } shouldBe Availability.Available(DataValue.StringValue("local"))
        reads shouldBe 0
    }
    test("handled candidates retain runtime operation failures") {
        val evaluator = DefaultExpressionEvaluator(ExpressionValueReader { error("Local candidates must not read authored storage") })
        val candidate = ExpressionBindingId("candidate")
        val expression = ExpressionNode.Call(OperationId("typewriter.number.divide"), listOf(ExpressionNode.Read(candidate, ValuePath()), ExpressionNode.Literal(DataValue.Integer(java.math.BigInteger.ZERO))))
        val result = with(FixtureReads) { evaluator.evaluateScoped(expression, ExpressionBindings(emptyMap()), mapOf(candidate to DataValue.Integer(java.math.BigInteger.ONE)), EvaluationBudget(20, 20)) }
        (result is Availability.Failed) shouldBe true
    }
    val fixture = Json.parseToJsonElement(Files.readString(fixturePath())).jsonObject
    fixture["version"]!!.jsonPrimitive.content shouldBe "1"
    fixture["cases"]!!.jsonArray.forEach { element ->
        val case = element.jsonObject
        test(case["id"]!!.jsonPrimitive.content) {
            val observed = mutableListOf<String>()
            val configuredReads = case["reads"]!!.jsonObject
            val evaluator =
                DefaultExpressionEvaluator(
                    ExpressionValueReader { location ->
                        val key = location.fixtureKey()
                        observed += key
                        val configured = configuredReads[key]!!.jsonObject
                        if (configured["unavailable"]?.jsonPrimitive?.boolean == true) {
                            Availability.Unavailable(listOf(location))
                        } else {
                            Availability.Available(configured.value())
                        }
                    },
                )
            val bindings =
                ExpressionBindings(
                    mapOf(
                        ExpressionBindingId("subject") to ValueLocation(ResourceId("subject"), ValuePath()),
                    ),
                )
            val result = with(FixtureReads) { evaluator.evaluate(case["expression"]!!.expression(), bindings, EvaluationBudget(100, 100)) }
            val expected = case["expectedByHost"]?.jsonObject?.get("kotlin")?.jsonObject ?: case["expected"]!!.jsonObject
            observed shouldBe expected["evaluatedReads"]!!.jsonArray.map { it.jsonPrimitive.content }
            when {
                "available" in expected -> {
                    result shouldBe Availability.Available(expected["available"]!!.jsonObject.value())
                }

                "failed" in expected -> {
                    val failure = result as Availability.Failed
                    val expectedFailure = expected["failed"]!!.jsonObject
                    failure.diagnostic.code shouldBe expectedFailure["code"]!!.jsonPrimitive.content
                    failure.diagnostic.locations.map(ValueLocation::fixtureKey) shouldBe
                        expectedFailure["locations"]!!.jsonArray.map { it.jsonPrimitive.content }
                }

                "unavailable" in expected -> {
                    val unavailable = result as Availability.Unavailable
                    val expectedUnavailable = expected["unavailable"]!!.jsonObject
                    unavailable.locations.map(ValueLocation::fixtureKey) shouldBe
                        expectedUnavailable["locations"]!!.jsonArray.map { it.jsonPrimitive.content }
                }
            }
        }
    }
}

private fun fixturePath(): Path =
    generateSequence(Path.of("").toAbsolutePath()) { it.parent }
        .map { it.resolve("skir-src/editor/v1/fixtures/portable_expression_conformance.json") }
        .first(Files::exists)

private fun JsonObject.value(): DataValue =
    when {
        "unfilled" in this -> {
            DataValue.Unfilled
        }

        "boolean" in this -> {
            DataValue.Boolean(getValue("boolean").jsonPrimitive.boolean)
        }

        "integer" in this -> {
            DataValue.Integer(getValue("integer").jsonPrimitive.content.toBigInteger())
        }

        "decimal" in this -> {
            DataValue.Decimal(getValue("decimal").jsonPrimitive.content)
        }

        "duration" in this -> DataValue.Duration(getValue("duration").jsonPrimitive.content.toLong().milliseconds)
        "timestamp" in this -> DataValue.Timestamp(Instant.parse(getValue("timestamp").jsonPrimitive.content))
        "float" in this -> DataValue.Float(getValue("float").jsonPrimitive.content.toDouble())

        "string" in this -> {
            DataValue.StringValue(getValue("string").jsonPrimitive.content)
        }

        "named" in this -> {
            val named = getValue("named").jsonObject
            DataValue.Named(
                TypeUse.Named(
                    TypeDefinitionId(
                        TypeId.Qualified(
                            named.getValue("namespace").jsonPrimitive.content,
                            named.getValue("name").jsonPrimitive.content,
                        ),
                        named
                            .getValue("revision")
                            .jsonPrimitive.content
                            .toInt(),
                    ),
                ),
                named.getValue("payload").jsonObject.value(),
            )
        }

        "record" in this -> {
            DataValue.Record(getValue("record").jsonObject.mapValues { (_, value) -> value.jsonObject.value() })
        }

        "list" in this -> {
            DataValue.ListValue(
                getValue("list").jsonArray.map { item ->
                    val encoded = item.jsonObject
                    ListItem(
                        ItemId(encoded.getValue("id").jsonPrimitive.content),
                        encoded.getValue("value").jsonObject.value(),
                    )
                },
            )
        }

        "set" in this -> {
            DataValue.SetValue(
                getValue("set").jsonArray.map { item ->
                    val encoded = item.jsonObject
                    ListItem(
                        ItemId(encoded.getValue("id").jsonPrimitive.content),
                        encoded.getValue("value").jsonObject.value(),
                    )
                },
            )
        }

        "map" in this -> {
            DataValue.MapValue(
                getValue("map").jsonArray.map { row ->
                    val encoded = row.jsonObject
                    MapRow(
                        ItemId(encoded.getValue("id").jsonPrimitive.content),
                        encoded.getValue("key").jsonObject.value(),
                        encoded.getValue("value").jsonObject.value(),
                    )
                },
            )
        }

        else -> {
            error("Unknown fixture value $this")
        }
    }

private fun JsonElement.expression(): ExpressionNode {
    val value = jsonObject
    return when {
        "boolean" in value ||
            "unfilled" in value ||
            "integer" in value ||
            "decimal" in value ||
            "string" in value ||
            "duration" in value ||
            "timestamp" in value ||
            "float" in value ||
            "named" in value ||
            "record" in value ||
            "list" in value ||
            "set" in value ||
            "map" in value -> {
            ExpressionNode.Literal(value.value())
        }

        "read" in value -> {
            ExpressionNode.Read(
                ExpressionBindingId(value.getValue("read").jsonPrimitive.content),
                ValuePath(value.getValue("path").jsonArray.map { PathSegment.Field(it.jsonPrimitive.content) }),
            )
        }

        "call" in value -> {
            ExpressionNode.Call(
                OperationId(value.getValue("call").jsonPrimitive.content),
                value.getValue("arguments").jsonArray.map(JsonElement::expression),
            )
        }

        "and" in value -> {
            value.binary(ExpressionNode::And)
        }

        "orElse" in value -> {
            value.binary(ExpressionNode::OrElse)
        }

        else -> {
            error("Unknown fixture expression $value")
        }
    }
}

private fun JsonObject.binary(create: (ExpressionNode, ExpressionNode) -> ExpressionNode): ExpressionNode {
    val parts = values.single() as JsonArray
    return create(parts[0].expression(), parts[1].expression())
}

private fun ValueLocation.fixtureKey(): String {
    val fields = path.segments.map { (it as PathSegment.Field).name }
    return if (fields.isEmpty()) resource.value else "${resource.value}:${fields.joinToString(".")}"
}

private object FixtureReads : AuthoredReads {
    override val catalog = CatalogGeneration("expression fixture")
    override val readContext = com.typewritermc.authoring.ReadContext(catalog)

    override fun <T> read(path: BoundPath<T>): Availability<T> = error("Fixture expressions use ExpressionValueReader.")

    override fun <T> readRepresentation(
        path: BoundPath<*>,
        representation: com.typewritermc.types.TypeUse,
    ): Availability<T> = error("Fixture expressions use ExpressionValueReader.")

    override fun presence(path: BoundPath<*>): Availability<Boolean> = error("Fixture expressions use ExpressionValueReader.")

    override fun binding(path: BoundPath<*>): Availability<com.typewritermc.authoring.DraftBinding> =
        error("Fixture expressions use ExpressionValueReader.")

    override fun canonicalValueKey(path: BoundPath<*>): Availability<String> = error("Fixture expressions use ExpressionValueReader.")

    override fun members(path: BoundCollectionPath): List<ItemId> = emptyList()

    override fun <D> select(query: TypedSelection<D>): PartialSelection<D> = error("Fixture expressions do not select resources.")
}
