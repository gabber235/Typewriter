package com.typewritermc.engine.pages

import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.DefaultInitializationRuntime
import com.typewritermc.authoring.HierarchyPathDefinition
import com.typewritermc.authoring.InitializationRequest
import com.typewritermc.authoring.PreparationTarget
import com.typewritermc.authoring.complete
import com.typewritermc.authoring.fieldMap
import com.typewritermc.authoring.record
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.discovery.GeneratedProviderIndex
import com.typewritermc.discovery.GeneratedProviderKind
import com.typewritermc.discovery.GeneratedTypeProvider
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.ResourceId
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.endpoint
import com.typewritermc.types.fieldMap
import com.typewritermc.types.fields
import com.typewritermc.types.integer
import com.typewritermc.types.named
import com.typewritermc.types.payload
import com.typewritermc.types.record
import com.typewritermc.types.toSkir
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.catalog.PreparedContent
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeUse
import java.math.BigInteger
import java.util.Collections

val PageCreationDiagnosticTest by testSuite {
    test("page defaults use supplied book context and missing book remains actionable") {
        val entries =
            Collections
                .list(requireNotNull(Thread.currentThread().contextClassLoader).getResources("META-INF/typewriter/generated-providers"))
                .flatMap { resource -> resource.openStream().bufferedReader().use { GeneratedProviderIndex.parse(it.readText()) } }
                .distinct()

        fun instance(name: String): Any {
            val type = Class.forName(name)
            return type.fields.singleOrNull { it.name == "INSTANCE" }?.get(null) ?: type.getConstructor().newInstance()
        }
        val definitions =
            entries
                .filter { it.kind == GeneratedProviderKind.Type }
                .map { (instance(it.providerClass) as GeneratedTypeProvider).definition }
                .distinctBy(TypeDefinition::id)
        val factories =
            entries
                .filter { it.kind == GeneratedProviderKind.NativeBinding }
                .map { instance(it.providerClass) as NativeBindingFactory }
                .distinctBy(NativeBindingFactory::provider)
        val generation = CatalogGeneration("page creation diagnosis")
        val catalog = DefaultCheckedCatalog(generation, StandardTypes.definitions + definitions)
        val bindings = FactoryNativeBindingRegistry(catalog, factories)
        val prepared =
            DefaultInitializationRuntime(catalog, bindings).prepareNow(
                InitializationRequest(
                    catalog = generation,
                    target = PreparationTarget.Record(TypeSelection.CompleteWrapper(SequencePageDefinition.use)),
                    supplied =
                        DataValue.record(
                            mapOf(
                                "chapter" to DataValue.named(HierarchyPathDefinition.use, DataValue.StringValueWrapper("")),
                                "priority" to DataValue.integer(BigInteger.ZERO),
                            ),
                        ),
                ),
            )
        val fields = (prepared.content as PreparedContent.RecordWrapper).record.fieldMap
        fields.filterValues { it == DataValue.UNFILLED }.keys shouldBe setOf("book", "name", "elements")
        prepared.findings.map { it.code } shouldBe listOf("unfinished_constructor_input")
        val page = (catalog.resolve(SequencePageDefinition.use.use) as Resolution.Ready).value
        val bookType =
            page.schema.fields
                .single { it.key == "book" }
                .type
        val bookSchema = (catalog.resolve(bookType) as Resolution.Ready).value
        val endpoint = (bookSchema.schema.representation as ResolvedRepresentation.LinkWrapper).value.endpoint
        val connected =
            DataValue.named(
                SequencePageDefinition.use,
                DataValue.record(
                    fields +
                        (
                            "book" to
                                DataValue.named(
                                    (bookType as TypeUse.NamedWrapper).value,
                                    DataValue.createLink(
                                        endpoint = endpoint,
                                        target = LinkTarget(resource = ResourceId("book").toSkir(), opposite = null),
                                    ),
                                )
                        ),
                ),
            )
        val unfinished = page.complete(connected) as CompletenessResult.Unfinished
        unfinished.locations.map { location -> location.path.segments } shouldBe
            listOf(listOf(PathSegment.createField(name = "name")), listOf(PathSegment.createField(name = "elements")))
        val connectedFields = (connected.payload as DataValue.RecordWrapper).value.fieldMap
        val preparedWithBook =
            DefaultInitializationRuntime(catalog, bindings).prepareNow(
                InitializationRequest(
                    catalog = generation,
                    target = PreparationTarget.Record(TypeSelection.CompleteWrapper(SequencePageDefinition.use)),
                    supplied = DataValue.record(connectedFields.filterKeys { it in setOf("book", "chapter", "priority") }),
                ),
            )
        val withBookFields = (preparedWithBook.content as PreparedContent.RecordWrapper).record.fieldMap
        withBookFields.filterValues { it == DataValue.UNFILLED }.keys shouldBe emptySet()
        preparedWithBook.findings shouldBe emptyList()
        withBookFields.getValue("name") shouldBe DataValue.StringValueWrapper("")
        (
            page.complete(
                DataValue.named(SequencePageDefinition.use, DataValue.record(withBookFields)),
            ) is CompletenessResult.Complete
        ) shouldBe
            true
    }
}
