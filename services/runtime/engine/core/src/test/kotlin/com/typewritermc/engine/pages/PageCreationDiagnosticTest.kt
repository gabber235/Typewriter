package com.typewritermc.engine.pages

import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.DefaultInitializationRuntime
import com.typewritermc.authoring.InitializationRequest
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.PreparationTarget
import com.typewritermc.authoring.PreparedContent
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.complete
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.discovery.GeneratedProviderIndex
import com.typewritermc.discovery.GeneratedProviderKind
import com.typewritermc.discovery.GeneratedTypeProvider
import com.typewritermc.library.ChapterPathDefinition
import com.typewritermc.types.DataValue
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.LinkTarget
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.ResourceId
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.ResolvedRepresentation
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
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
                    target = PreparationTarget.Record(TypeSelection.Complete(SequencePageDefinition.use)),
                    supplied =
                        DataValue.Record(
                            mapOf(
                                "chapter" to DataValue.Named(ChapterPathDefinition.use, DataValue.StringValue("")),
                                "priority" to DataValue.Integer(BigInteger.ZERO),
                            ),
                        ),
                ),
            )
        val fields = (prepared.content as PreparedContent.Record).record.fields
        fields.filterValues { it == DataValue.Unfilled }.keys shouldBe setOf("book", "name", "elements")
        prepared.findings.map { it.code } shouldBe listOf("unfinished_constructor_input")
        val page = (catalog.resolve(SequencePageDefinition.use) as Resolution.Ready).value
        val bookType =
            page.schema.fields
                .single { it.key == "book" }
                .type
        val bookSchema = (catalog.resolve(bookType) as Resolution.Ready).value
        val endpoint = (bookSchema.schema.representation as ResolvedRepresentation.Link).endpoint
        val connected =
            DataValue.Named(
                SequencePageDefinition.use,
                DataValue.Record(
                    fields +
                        (
                            "book" to
                                DataValue.Named(
                                    bookType as TypeUse.Named,
                                    DataValue.Link(endpoint, LinkTarget(ResourceId("book"), null)),
                                )
                        ),
                ),
            )
        val unfinished = page.complete(connected) as CompletenessResult.Unfinished
        unfinished.locations.map { location -> location.path.segments } shouldBe
            listOf(listOf(PathSegment.Field("name")), listOf(PathSegment.Field("elements")))
        val connectedFields = (connected.payload as DataValue.Record).fields
        val preparedWithBook =
            DefaultInitializationRuntime(catalog, bindings).prepareNow(
                InitializationRequest(
                    catalog = generation,
                    target = PreparationTarget.Record(TypeSelection.Complete(SequencePageDefinition.use)),
                    supplied = DataValue.Record(connectedFields.filterKeys { it in setOf("book", "chapter", "priority") }),
                ),
            )
        val withBookFields = (preparedWithBook.content as PreparedContent.Record).record.fields
        withBookFields.filterValues { it == DataValue.Unfilled }.keys shouldBe emptySet()
        preparedWithBook.findings shouldBe emptyList()
        withBookFields.getValue("name") shouldBe DataValue.StringValue("")
        (
            page.complete(
                DataValue.Named(SequencePageDefinition.use, DataValue.Record(withBookFields)),
            ) is CompletenessResult.Complete
        ) shouldBe
            true
    }
}
