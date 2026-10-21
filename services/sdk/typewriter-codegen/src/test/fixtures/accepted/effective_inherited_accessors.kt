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
import skirout.editor.v1.type_catalog.RepresentationTemplate
import com.typewritermc.types.template
import com.typewritermc.types.nullable
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

fun verifyCanonicalOwnership() {
    val imported = ImportedEntryDefinition.definition.representation as RepresentationTemplate.RecordWrapper
    check(imported.value.fields.map { it.owner.name } == listOf("placement"))
    val child = GenericChildDefinition.definition.representation as RepresentationTemplate.RecordWrapper
    check(child.value.fields.isEmpty())
    check(
        NullableChildDefinition.definition.parents.single().arguments.single() ==
            NullableChildDefinition.definition.parameters.single().key.template.nullable(),
    )
    check(
        GenericChildFields.payload.path.segments
            .single() ==
            PathSegment.createField(name = "wire_payload"),
    )
    check(
        ImportedEntryFields.name.path.segments
            .single() ==
            PathSegment.createField(name = "name"),
    )
}

context(edits: EditContext)
suspend fun <C, D> nullableEdit(
    draft: NullableChildExactDraft<C, D>,
    replacement: C?,
) {
    draft.setPayload(replacement)
}

fun main() = verifyCanonicalOwnership()
