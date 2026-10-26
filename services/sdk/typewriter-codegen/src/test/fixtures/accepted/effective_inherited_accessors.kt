package fixture

import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.DraftList
import com.typewritermc.authoring.EditContext
import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.elements.Element
import com.typewritermc.expression.Expr
import com.typewritermc.expression.MayBeMissing
import com.typewritermc.types.TypewriterRecordContract
import com.typewritermc.types.TypewriterTypeImports
import kotlinx.serialization.SerialName
import com.typewritermc.discovery.CatalogAssemblyContext
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.GeneratedProviderArtifact
import com.typewritermc.discovery.GeneratedProviderLoader
import com.typewritermc.discovery.assemble
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.presentation.DefaultPresentationRuntime
import com.typewritermc.presentation.PresentationRuntime
import java.nio.file.Path
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.integerScalar
import com.typewritermc.types.use
import io.kotest.assertions.withClue
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.PathSegment

interface ImportedEntry : Element {
    override val placement: GraphPlacement
}

@TypewriterRecordContract
interface Parent<T> {
    @SerialName("wire_payload")
    val payload: T
}

interface Middle<A, B> : Parent<List<B>>

interface GenericChild<C> : Middle<String, C>

interface NullableChild<C> : Parent<C?>

@TypewriterRecordContract
interface Left {
    val title: String
}

@TypewriterRecordContract
interface Right {
    val title: String
}

interface ResolvedDiamond :
    Left,
    Right {
    override val title: String
}

@TypewriterTypeImports(ImportedEntry::class, GenericChild::class, NullableChild::class, ResolvedDiamond::class)
object ImportedTypes

fun inheritedPresentation(scope: ImportedEntryPresentationScope) {
    with(scope) {
        name { textInput() }
        placement { recordInput { fields { x { numericInput() } } } }
    }
}

fun inheritedConfiguration(scope: ImportedEntryConfigurationScope) {
    scope.name { nonEmpty() }
}

fun inheritedExpression(scope: ImportedEntryExpressions): Expr<String, MayBeMissing> = scope.name

context(reads: AuthoredReads)
fun inheritedDraft(draft: ImportedEntryDraft): Availability<String> = draft.name

context(edits: EditContext)
suspend fun inheritedEdit(draft: ImportedEntryDraft) {
    draft.setName("Changed")
}

fun <C> genericExpression(scope: GenericChildExpressions<C>): Expr<List<C>, MayBeMissing> = scope.payload

fun <C> nullableExpression(scope: NullableChildExpressions<C>): Expr<C?, MayBeMissing> = scope.payload

fun <C> genericPresentation(scope: GenericChildPresentationScope<C>) {
    scope.payload { listInput() }
}

fun <C> genericConfiguration(scope: GenericChildConfigurationScope<C>) {
    scope.payload {}
}

context(reads: AuthoredReads)
fun <D> genericDraft(draft: GenericChildDraft<D>): Availability<DraftList<D>> = draft.payload

context(reads: AuthoredReads)
fun <D> nullableDraft(draft: NullableChildDraft<D>): Availability<D?> = draft.payload

context(edits: EditContext)
suspend fun <C, D> genericEdit(
    draft: GenericChildExactDraft<C, D>,
    replacement: List<C>,
) {
    draft.setPayload(replacement)
}

context(edits: EditContext)
suspend fun <C, D> nullableEdit(
    draft: NullableChildExactDraft<C, D>,
    replacement: C?,
) {
    draft.setPayload(replacement)
}

/**
 * The checked catalog shows each inherited field once under the wire name its declaration gives, and generated
 * accessors read that wire name.
 */
fun main(args: Array<String>) {
    GeneratedProviderLoader()
        .load(
            listOf(
                GeneratedProviderArtifact(ArtifactId("fixture"), Path.of(args.single())),
                GeneratedProviderArtifact(ArtifactId("core"), Path.of(Element::class.java.protectionDomain.codeSource.location.toURI())),
            ),
            DeploymentFacts(emptyMap()),
            DiscoveryDomains.Realm,
            runtimeServices = mapOf(PresentationRuntime::class.java to DefaultPresentationRuntime()),
        ).use { deployment ->
            val assembly = deployment.providers.contributions.assemble(CatalogAssemblyContext(CatalogGeneration(value = "fixture")))
            fun fieldKeys(use: TypeUse): List<String> =
                when (val resolved = assembly.checked.resolve(use)) {
                    is Resolution.Ready -> resolved.value.schema.fields.map { it.key }
                    is Resolution.Invalid -> error("${resolved.diagnostics} ${assembly.editorCatalog.diagnostics}")
                }
            val integer = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).use
            withClue("GenericChild<Int>") { fieldKeys(GenericChildDefinition.applied(listOf(integer)).use) shouldBe listOf("wire_payload") }
            withClue("NullableChild<Int>") { fieldKeys(NullableChildDefinition.applied(listOf(integer)).use) shouldBe listOf("wire_payload") }
            withClue("ImportedEntry") { fieldKeys(ImportedEntryDefinition.use.use).count { it == "placement" } shouldBe 1 }
        }
    GenericChildFields.payload.path.segments.single() shouldBe PathSegment.createField(name = "wire_payload")
    ImportedEntryFields.name.path.segments.single() shouldBe PathSegment.createField(name = "name")
}
