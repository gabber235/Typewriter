package com.typewritermc.realm.checking

import build.skir.JsonFlavor
import com.typewritermc.authoring.of
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.CapturedAuthoringReads
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.authoring.TEST_TYPE
import com.typewritermc.realm.authoring.TestCatalogLease
import com.typewritermc.realm.authoring.location
import com.typewritermc.realm.authoring.record
import com.typewritermc.types.integer
import com.typewritermc.types.listValue
import com.typewritermc.types.mapValue
import com.typewritermc.types.named
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import com.typewritermc.types.setValue
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.withClue
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import skirout.editor.v1.catalog.ConfigurationRecipe
import skirout.editor.v1.catalog.OwnedRule
import skirout.editor.v1.catalog.RuleDescriptor
import skirout.editor.v1.checking.CheckOutcome
import skirout.editor.v1.diagnostic.Diagnostic
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.diagnostic.DiagnosticTemplate
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.MapRow
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.RelativeFieldPattern
import skirout.editor.v1.type_catalog.RuleId
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId
import java.nio.file.Files
import java.nio.file.Path

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
            val store = InMemoryAuthoringViewStore(TestCatalogLease(), AuthoringSeed(mapOf(owner to case.ownerRecord())))
            val lease = store.capture()
            val expanded =
                CapturedAuthoringReads(lease.originalView()).expand(
                    ValueLocation.of(owner),
                    RelativeFieldPattern.serializer.fromJsonCode(case.getValue("pattern").toString()),
                )
            expanded shouldBe case.locations("expected")
            lease.close()
            store.close()
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
                val store =
                    InMemoryAuthoringViewStore(
                        TestCatalogLease(configuration = listOf(recipe)),
                        AuthoringSeed(
                            mapOf(owner to case.ownerRecord()),
                        ),
                    )
                val runtime = RealmCheckRuntime(store, StandardTestDispatcher(testScheduler))
                runtime.reloadCatalog()
                advanceUntilIdle()
                runtime.drain()

                val actual = runtime.findings().associateBy { it.ticket.instance.location }
                val expected = case.getValue("expected").jsonArray.map { it.jsonObject }
                actual.keys shouldBe expected.map { location(it.string("subject")) }.toSet()
                expected.forEach { entry ->
                    val subject = location(entry.string("subject"))
                    val set = actual.getValue(subject)
                    withClue("outcome of ${entry.string("subject")}") { set.outcome.compact() shouldBe entry.getValue("outcome") }
                    withClue("findings of ${entry.string("subject")}") {
                        set.findings.map { it.compact() } shouldBe entry.getValue("findings").jsonArray.toList()
                    }
                }
                runtime.close()
                store.close()
            }
        }
    }
}

private fun fixtureFile(): Path =
    generateSequence(Path.of("").toAbsolutePath()) { it.parent }
        .map { it.resolve("skir-src/editor/v1/fixtures/portable_pattern_conformance.json") }
        .first(Files::isRegularFile)

private fun JsonObject.string(key: String): String = getValue(key).jsonPrimitive.content

/** The owner resource: a record of [TEST_TYPE] whose fields are the case value's. */
private fun JsonObject.ownerRecord(): AuthoringRecord {
    val payload = (compactValue(getValue("value")) as DataValue.RecordWrapper).value
    return AuthoringRecord.of(configuration = TypeSelection.CompleteWrapper(TEST_TYPE.namedUse()), payload = payload)
}

private fun JsonObject.locations(key: String): List<ValueLocation> = getValue(key).jsonArray.map { location(it.jsonPrimitive.content) }

/** A compact value of the fixture format; see the fixture README. */
private fun compactValue(element: JsonElement): DataValue {
    val (kind, value) = element.jsonObject.entries.single()
    return when (kind) {
        "null" -> DataValue.NULL
        "unfilled" -> DataValue.UNFILLED
        "string" -> DataValue.StringValueWrapper(value.jsonPrimitive.content)
        "integer" -> DataValue.integer(value.jsonPrimitive.content.toBigInteger())
        "boolean" -> DataValue.BooleanWrapper(value.jsonPrimitive.content.toBooleanStrict())
        "record" -> DataValue.record(value.jsonObject.mapValues { (_, field) -> compactValue(field) })
        "list" -> DataValue.listValue(value.jsonArray.map { it.jsonObject.listItem() })
        "set" -> DataValue.setValue(value.jsonArray.map { it.jsonObject.listItem() })
        "map" -> DataValue.mapValue(value.jsonArray.map { it.jsonObject.mapRow() })
        "named" -> value.jsonObject.namedValue()
        else -> error("Unsupported compact value $kind.")
    }
}

private fun JsonObject.listItem(): ListItem = ListItem(id = ItemId(value = string("id")), value = compactValue(getValue("value")))

private fun JsonObject.mapRow(): MapRow =
    MapRow(id = ItemId(value = string("id")), key = compactValue(getValue("key")), value = compactValue(getValue("value")))

private fun JsonObject.namedValue(): DataValue {
    val definition =
        TypeDefinitionId.qualified(string("namespace"), string("name"), getValue("revision").jsonPrimitive.content.toInt())
    val arguments = getValue("arguments").jsonArray.map { TypeUse.serializer.fromJsonCode(it.toString()) }
    return DataValue.named(definition.namedUse(arguments), compactValue(getValue("payload")))
}

/** A compact location: the resource id, then `.field`, `[item]`, `.#key` and `.#value` steps. */
private fun location(text: String): ValueLocation {
    val resource = text.takeWhile { it != '.' && it != '[' }
    val segments = mutableListOf<PathSegment>()
    var rest = text.removePrefix(resource)
    while (rest.isNotEmpty()) {
        when {
            rest.startsWith(".#key") -> {
                segments += PathSegment.MAP_KEY
                rest = rest.removePrefix(".#key")
            }

            rest.startsWith(".#value") -> {
                segments += PathSegment.MAP_VALUE
                rest = rest.removePrefix(".#value")
            }

            rest.startsWith(".") -> {
                val name = rest.drop(1).takeWhile { it != '.' && it != '[' }
                segments += PathSegment.createField(name = name)
                rest = rest.drop(1 + name.length)
            }

            else -> {
                val id = rest.drop(1).substringBefore(']')
                segments += PathSegment.createItem(id = ItemId(value = id))
                rest = rest.drop(id.length + 2)
            }
        }
    }
    return ValueLocation.of(ResourceId(value = resource), ValuePath(segments = segments))
}

private fun ValueLocation.compact(): JsonPrimitive =
    JsonPrimitive(
        resource.value +
            path.segments.joinToString("") { segment ->
                when (segment) {
                    is PathSegment.FieldWrapper -> ".${segment.value.name}"
                    is PathSegment.ItemWrapper -> "[${segment.value.id.value}]"
                    PathSegment.MAP_KEY -> ".#key"
                    PathSegment.MAP_VALUE -> ".#value"
                    else -> error("Unsupported path segment $segment.")
                }
            },
    )

private fun CheckOutcome.compact(): JsonElement =
    when (this) {
        CheckOutcome.FINISHED -> {
            JsonPrimitive("finished")
        }

        is CheckOutcome.NeedsInputWrapper -> {
            JsonObject(mapOf("needs_input" to kotlinx.serialization.json.JsonArray(value.map { it.compact() })))
        }

        is CheckOutcome.FailedWrapper -> {
            val failure = value.single()
            JsonObject(
                mapOf(
                    "failed" to
                        JsonObject(
                            mapOf(
                                "failure" to JsonPrimitive(failure.code),
                                "primary" to (failure.primary?.compact() ?: JsonNull),
                                "related" to kotlinx.serialization.json.JsonArray(failure.related.map { it.compact() }),
                            ),
                        ),
                ),
            )
        }

        else -> {
            JsonPrimitive(toString())
        }
    }

private fun Diagnostic.compact(): JsonElement =
    JsonObject(
        mapOf(
            "code" to JsonPrimitive(code),
            "message" to JsonPrimitive(message),
            "severity" to Json.parseToJsonElement(DiagnosticSeverity.serializer.toJsonCode(severity, JsonFlavor.READABLE)),
            "primary" to (primary?.compact() ?: JsonNull),
            "related" to kotlinx.serialization.json.JsonArray(related.map { it.compact() }),
        ),
    )
