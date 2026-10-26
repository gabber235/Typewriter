package com.typewritermc.expression

import build.skir.JsonFlavor
import com.typewritermc.types.ColorDefinition
import com.typewritermc.types.actualType
import com.typewritermc.types.fields
import com.typewritermc.types.payload
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonArray
import skirout.editor.v1.catalog.DeclarationStatus
import skirout.editor.v1.catalog.PublishedType
import skirout.editor.v1.catalog.ResourceAppearance
import skirout.editor.v1.catalog.TypeDisplay
import skirout.editor.v1.type_catalog.ArgumentSelection
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldValue
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.QualifiedTypeId
import skirout.editor.v1.type_catalog.RecordRepresentationTemplate
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeUse
import skirout.kernel.v1.color.Color
import skirout.kernel.v1.icon.Icon
import java.nio.file.Files
import java.nio.file.Path

val CanonicalReadModelsTest by testSuite {
    test("the read schema derived from Skir matches the schema the panel derives") {
        val committed =
            Json
                .parseToJsonElement(Files.readString(fixtureDirectory().resolve(CANONICAL_READ_MODELS_FIXTURE)))
                .jsonArray
                .map { TypeDefinition.serializer.fromJsonCode(it.toString()) }

        committed shouldBe canonicalReadSchema()
    }

    test("a resource appearance reads its accent as the declared framework color") {
        val appearance =
            CanonicalReadModels.resourceAppearance.encode(
                ResourceAppearance(label = "Book", accent = Color(argb = 0xFF336699u.toInt()), icon = Icon.IconifyWrapper("lucide:book")),
            )
        val payload = ((appearance as DataValue.NamedWrapper).value.payload as DataValue.RecordWrapper).value.fields
        payload.single { it.name == "accent" }.value shouldBe
            DataValue.createNamed(actualType = declaredUse(ColorDefinition.id), payload = DataValue.IntegerWrapper("4281558681"))
    }

    test("read values round trip through every root") {
        val text = TypeUse.ScalarWrapper(ScalarKind.TEXT)
        val use =
            TypeUse.createNamed(
                definition = readId("example:Book"),
                arguments =
                    listOf(
                        TypeUse.createNullable(
                            value = TypeUse.ScalarWrapper(ScalarKind.createInteger(width = IntegerWidth.UNSIGNED_SIXTY_FOUR)),
                        ),
                        text,
                    ),
            )
        CanonicalReadModels.typeUse.decode(CanonicalReadModels.typeUse.encode(use)) shouldBe use
        val selection =
            TypeSelection.createPending(
                definition = readId("example:Book"),
                arguments = listOf(ArgumentSelection.UNFILLED, ArgumentSelection.ChosenWrapper(text)),
            )
        CanonicalReadModels.typeSelection.decode(CanonicalReadModels.typeSelection.encode(selection)) shouldBe selection
        val published =
            PublishedType(
                definition =
                    TypeDefinition.partial(
                        id = readId("example:Book"),
                        representation =
                            RepresentationTemplate.RecordWrapper(
                                RecordRepresentationTemplate(fields = emptyList(), abstract_ = false),
                            ),
                    ),
                status = DeclarationStatus.READY,
                effectiveFields = emptyList(),
                ancestorTemplates = emptyList(),
                display =
                    TypeDisplay(name = "Book", description = "", icon = Icon.SvgWrapper("<svg/>"), color = Color(argb = -1)),
                searchKey = "book",
                placementField = null,
            )
        CanonicalReadModels.publishedType.decode(CanonicalReadModels.publishedType.encode(published)) shouldBe published
    }

    test("field projection reads the Skir field and a null value is unfilled below it") {
        val selection = TypeSelection.CompleteWrapper(NamedTypeUse(definition = readId("example:Book"), arguments = emptyList()))
        CanonicalReadModels.encode(selection, TypeSelection.serializer.typeDescriptor, listOf("value", "arguments")) shouldBe
            DataValue.createListValue(items = emptyList())
        CanonicalReadModels.encode(null, PublishedType.serializer.typeDescriptor, listOf("display")) shouldBe DataValue.UNFILLED
        val record = CanonicalReadModels.typeSelection.encode(selection) as DataValue.NamedWrapper
        record.value.actualType.definition shouldBe readId("editor/v1/type_catalog.skir:TypeSelection.complete")
        ((record.value.payload as DataValue.RecordWrapper).value.fields.map(FieldValue::name)) shouldBe listOf("value")
    }
}

/** The committed schema fixture the panel compares its own derivation with. */
internal const val CANONICAL_READ_MODELS_FIXTURE = "canonical_read_models.json"

/** Every read model definition: the Skir derived roots and the framework types they read. */
internal fun canonicalReadSchema(): List<TypeDefinition> = CanonicalReadModels.definitions + CanonicalReadModels.frameworkDefinitions

/** The text of [CANONICAL_READ_MODELS_FIXTURE]: [canonicalReadSchema] as readable Skir JSON. */
internal fun renderCanonicalReadSchema(): String =
    canonicalReadSchema().joinToString(",\n", "[\n", "\n]\n") { TypeDefinition.serializer.toJsonCode(it, JsonFlavor.READABLE) }

private fun readId(record: String) =
    TypeDefinitionId(typeId = TypeId.QualifiedWrapper(QualifiedTypeId(namespace = CANONICAL_READ_NAMESPACE, name = record)), revision = 1)

private fun declaredUse(id: TypeDefinitionId) = NamedTypeUse(definition = id, arguments = emptyList())

private fun fixtureDirectory(): Path =
    generateSequence(Path.of("").toAbsolutePath()) { it.parent }
        .map { it.resolve("skir-src/editor/v1/fixtures") }
        .first(Files::isDirectory)
