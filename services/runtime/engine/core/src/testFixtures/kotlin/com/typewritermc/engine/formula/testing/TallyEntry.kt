@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.engine.formula.testing

import com.typewritermc.authoring.AppliedNativeArguments
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.TypedPath
import com.typewritermc.authoring.field
import com.typewritermc.authoring.root
import com.typewritermc.authoring.typedPath
import com.typewritermc.elements.Entry
import com.typewritermc.engine.pages.SequencePage
import com.typewritermc.events.EventContext
import com.typewritermc.events.RecordScope
import com.typewritermc.events.readField
import com.typewritermc.formula.Var
import com.typewritermc.formula.VarDefinition
import com.typewritermc.identity.ProtagonistDefinition
import com.typewritermc.library.PageElements
import com.typewritermc.types.GeneratedNativeField
import com.typewritermc.types.GeneratedRecordNativeBinding
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.Ref
import com.typewritermc.types.ResourceId
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.declared
import com.typewritermc.types.integerScalar
import com.typewritermc.types.toTemplate
import com.typewritermc.types.use
import skirout.editor.v1.type_catalog.FunctionParameterUse
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.NativeBindingId
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValuePath
import kotlin.reflect.KClass

/** An entry about [Said] with two formula fields of different types, [count] an `Int` and [total] a `Long`. */
class TallyEntry(
    override val name: String,
    val count: Var<Int, EventContext<Said>>,
    val total: Var<Long, EventContext<Said>>,
    override val page: Ref<PageElements.Element, SequencePage> = Ref(ResourceId("sequence")),
    override val placement: GraphPlacement = GraphPlacement(),
) : Entry

/** The formula type `Long`, for [TallyEntry.total]. */
val long: TypeUse = integerScalar(IntegerWidth.SIGNED_SIXTY_FOUR).use

/** The catalog declaration of [TallyEntry], a record of its name and its two formula fields, as codegen declares one. */
object TallyEntryDefinition {
    val id: TypeDefinitionId = TypeDefinitionId.declared("e1f0000000000000000000000000a002")

    val definition: TypeDefinition =
        recordDefinition(
            id,
            "name" to ScalarKind.TEXT.use.toTemplate(),
            "count" to formulaOf(int).toTemplate(),
            "total" to formulaOf(long).toTemplate(),
        )
}

/** Binds [TallyEntry] as codegen binds a record: field by field through each field's own binding. */
object TallyEntryNativeBindingFactory : NativeBindingFactory {
    override val definition: TypeDefinitionId = TallyEntryDefinition.id
    override val provider: NativeBindingId = NativeBindingId(value = "test.tally")
    override val nativeClass: KClass<*> = TallyEntry::class

    @Suppress("UNCHECKED_CAST")
    override fun bind(
        actual: CheckedType,
        arguments: AppliedNativeArguments,
    ): NativeBinding<*> =
        GeneratedRecordNativeBinding<TallyEntry>(
            checked = actual,
            provider = provider,
            signature = "test.tally",
            nativeClass = TallyEntry::class,
            fields =
                listOf(
                    GeneratedNativeField("name", { arguments.resolver.bind(ScalarKind.TEXT.use) }, { it.name }),
                    GeneratedNativeField("count", { arguments.resolver.bind(formulaOf(int)) }, { it.count }),
                    GeneratedNativeField("total", { arguments.resolver.bind(formulaOf(long)) }, { it.total }),
                ),
            construct = { values ->
                TallyEntry(
                    name = values.getValue("name") as String,
                    count = values.getValue("count") as Var<Int, EventContext<Said>>,
                    total = values.getValue("total") as Var<Long, EventContext<Said>>,
                )
            },
        )
}

/** The paths of [TallyEntry]'s formula fields, as codegen emits a type's fields. */
object TallyEntryFields {
    val count: TypedPath<TallyEntry, Var<Int, EventContext<Said>>> =
        typedPath(TallyEntryDefinition.id, ValuePath.root.field("count"), formulaOf(int))

    val total: TypedPath<TallyEntry, Var<Long, EventContext<Said>>> =
        typedPath(TallyEntryDefinition.id, ValuePath.root.field("total"), formulaOf(long))
}

/** The accessors of [TallyEntry]'s fields, as codegen emits them. */
val RecordScope<TallyEntry>.count: Int get() = readField(TallyEntryFields.count)

val RecordScope<TallyEntry>.total: Long get() = readField(TallyEntryFields.total)

/** A [TallyEntry] named [id] holding [count] and [total]. */
fun tallyEntry(
    id: String,
    count: Var<Int, EventContext<Said>>,
    total: Var<Long, EventContext<Said>>,
): PublishedResource = PublishedResource(id, TallyEntryDefinition.id.use(), TallyEntry(id, count, total))

/** `Var<T, (event: Said, protagonist: Protagonist) -> T>`, the catalog type of a formula field about [Said]. */
internal fun formulaOf(result: TypeUse): TypeUse =
    VarDefinition.id.use(
        listOf(
            result,
            TypeUse.createFunction(
                context =
                    listOf(
                        FunctionParameterUse(name = "event", type = SaidDefinition.id.use()),
                        FunctionParameterUse(name = "protagonist", type = ProtagonistDefinition.id.use()),
                    ),
                parameters = emptyList(),
                result = result,
            ),
        ),
    )
