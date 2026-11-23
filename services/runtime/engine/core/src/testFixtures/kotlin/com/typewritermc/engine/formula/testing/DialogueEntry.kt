@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.engine.formula.testing

import com.typewritermc.authoring.AppliedNativeArguments
import com.typewritermc.authoring.GeneratedConstructorField
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.NativeConstructionPlan
import com.typewritermc.authoring.TypedPath
import com.typewritermc.authoring.constructorDefaults
import com.typewritermc.authoring.field
import com.typewritermc.authoring.root
import com.typewritermc.authoring.typedPath
import com.typewritermc.elements.Entry
import com.typewritermc.engine.pages.SequencePage
import com.typewritermc.events.EventContext
import com.typewritermc.events.RecordScope
import com.typewritermc.events.optionalRecordField
import com.typewritermc.events.readField
import com.typewritermc.events.recordField
import com.typewritermc.events.recordList
import com.typewritermc.formula.Var
import com.typewritermc.library.PageElements
import com.typewritermc.types.GeneratedNativeField
import com.typewritermc.types.GeneratedRecordNativeBinding
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.Ref
import com.typewritermc.types.ResourceId
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.declared
import com.typewritermc.types.nullable
import com.typewritermc.types.toTemplate
import com.typewritermc.types.use
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.NativeBindingId
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValuePath
import kotlin.reflect.KClass

// An entry with records inside it, as a dialogue holds them: a nested record with a formula field, and a list of
// records with a formula field each. Its catalog types, bindings, paths and accessors are written as codegen emits them.

/** How a line is spoken: at least [minLines] lines, read as a formula about [Said], and at most [maxLineLength] wide. */
class Spoken(
    val minLines: Var<Int, EventContext<Said>>,
    val maxLineLength: Int = 40,
)

/** One answer a player can pick, whose [text] is a formula about [Said]. */
class Choice(
    val text: Var<String, EventContext<Said>>,
)

/**
 * A dialogue entry: how it is [spoken], how an optional [aside] is spoken, whether it [opens] with a greeting, and the
 * [choices] it offers.
 */
class DialogueEntry(
    override val name: String,
    val spoken: Spoken,
    val aside: Spoken? = null,
    val choices: List<Choice> = emptyList(),
    val opens: Var<Boolean, EventContext<Said>> = Var.Value(true),
    val greeting: Var<String, EventContext<Said>> = Var.Value(""),
    val farewell: Var<String, EventContext<Said>> = Var.Value(""),
    override val page: Ref<PageElements.Element, SequencePage> = Ref(ResourceId("sequence")),
    override val placement: GraphPlacement = GraphPlacement(),
) : Entry

object SpokenDefinition {
    val id: TypeDefinitionId = TypeDefinitionId.declared("e1f0000000000000000000000000a003")

    val definition: TypeDefinition =
        recordDefinition(
            id,
            "minLines" to formulaOf(int).toTemplate(),
            "maxLineLength" to int.toTemplate(),
            defaulted = setOf("maxLineLength"),
        )
}

object ChoiceDefinition {
    val id: TypeDefinitionId = TypeDefinitionId.declared("e1f0000000000000000000000000a004")

    val definition: TypeDefinition = recordDefinition(id, "text" to formulaOf(text).toTemplate())
}

object DialogueEntryDefinition {
    val id: TypeDefinitionId = TypeDefinitionId.declared("e1f0000000000000000000000000a005")

    val definition: TypeDefinition =
        recordDefinition(
            id,
            "name" to ScalarKind.TEXT.use.toTemplate(),
            "spoken" to SpokenDefinition.id.use().toTemplate(),
            "aside" to asideType.toTemplate(),
            "choices" to choicesType.toTemplate(),
            "opens" to formulaOf(boolean).toTemplate(),
            "greeting" to formulaOf(text).toTemplate(),
            "farewell" to formulaOf(text).toTemplate(),
        )
}

private val boolean: TypeUse = ScalarKind.BOOLEAN.use
private val asideType: TypeUse = SpokenDefinition.id.use().nullable()
private val choicesType: TypeUse = StandardTypes.list.use(listOf(ChoiceDefinition.id.use()))

object SpokenNativeBindingFactory : NativeBindingFactory {
    override val definition: TypeDefinitionId = SpokenDefinition.id
    override val provider: NativeBindingId = NativeBindingId(value = "test.spoken")
    override val nativeClass: KClass<*> = Spoken::class
    override val constructionPlan: NativeConstructionPlan =
        Spoken::class.constructorDefaults(
            listOf(
                GeneratedConstructorField(
                    owner = FieldOwner(definition = SpokenDefinition.id, name = "minLines"),
                    sourceName = "minLines",
                    hasDefault = false,
                    type = { formulaOf(int) },
                    read = { it.minLines },
                ),
                GeneratedConstructorField(
                    owner = FieldOwner(definition = SpokenDefinition.id, name = "maxLineLength"),
                    sourceName = "maxLineLength",
                    hasDefault = true,
                    type = { int },
                    read = { it.maxLineLength },
                ),
            ),
        )

    @Suppress("UNCHECKED_CAST")
    override fun bind(
        actual: CheckedType,
        arguments: AppliedNativeArguments,
    ): NativeBinding<*> =
        GeneratedRecordNativeBinding<Spoken>(
            checked = actual,
            provider = provider,
            signature = "test.spoken",
            nativeClass = Spoken::class,
            fields =
                listOf(
                    GeneratedNativeField("minLines", { arguments.resolver.bind(formulaOf(int)) }, { it.minLines }),
                    GeneratedNativeField("maxLineLength", { arguments.resolver.bind(int) }, { it.maxLineLength }),
                ),
            defaults = constructionPlan,
            construct = { values ->
                Spoken(values.getValue("minLines") as Var<Int, EventContext<Said>>, values.getValue("maxLineLength") as Int)
            },
        )
}

object ChoiceNativeBindingFactory : NativeBindingFactory {
    override val definition: TypeDefinitionId = ChoiceDefinition.id
    override val provider: NativeBindingId = NativeBindingId(value = "test.choice")
    override val nativeClass: KClass<*> = Choice::class

    @Suppress("UNCHECKED_CAST")
    override fun bind(
        actual: CheckedType,
        arguments: AppliedNativeArguments,
    ): NativeBinding<*> =
        GeneratedRecordNativeBinding<Choice>(
            checked = actual,
            provider = provider,
            signature = "test.choice",
            nativeClass = Choice::class,
            fields = listOf(GeneratedNativeField("text", { arguments.resolver.bind(formulaOf(text)) }, { it.text })),
            construct = { values -> Choice(values.getValue("text") as Var<String, EventContext<Said>>) },
        )
}

object DialogueEntryNativeBindingFactory : NativeBindingFactory {
    override val definition: TypeDefinitionId = DialogueEntryDefinition.id
    override val provider: NativeBindingId = NativeBindingId(value = "test.dialogue")
    override val nativeClass: KClass<*> = DialogueEntry::class

    @Suppress("UNCHECKED_CAST")
    override fun bind(
        actual: CheckedType,
        arguments: AppliedNativeArguments,
    ): NativeBinding<*> =
        GeneratedRecordNativeBinding<DialogueEntry>(
            checked = actual,
            provider = provider,
            signature = "test.dialogue",
            nativeClass = DialogueEntry::class,
            fields =
                listOf(
                    GeneratedNativeField("name", { arguments.resolver.bind(ScalarKind.TEXT.use) }, { it.name }),
                    GeneratedNativeField("spoken", { arguments.resolver.bind(SpokenDefinition.id.use()) }, { it.spoken }),
                    GeneratedNativeField("aside", { arguments.resolver.bind(asideType) }, { it.aside }),
                    GeneratedNativeField("choices", { arguments.resolver.bind(choicesType) }, { it.choices }),
                    GeneratedNativeField("opens", { arguments.resolver.bind(formulaOf(boolean)) }, { it.opens }),
                    GeneratedNativeField("greeting", { arguments.resolver.bind(formulaOf(text)) }, { it.greeting }),
                    GeneratedNativeField("farewell", { arguments.resolver.bind(formulaOf(text)) }, { it.farewell }),
                ),
            construct = { values ->
                DialogueEntry(
                    name = values.getValue("name") as String,
                    spoken = values.getValue("spoken") as Spoken,
                    aside = values["aside"] as Spoken?,
                    choices = values.getValue("choices") as List<Choice>,
                    opens = values.getValue("opens") as Var<Boolean, EventContext<Said>>,
                    greeting = values.getValue("greeting") as Var<String, EventContext<Said>>,
                    farewell = values.getValue("farewell") as Var<String, EventContext<Said>>,
                )
            },
        )
}

/** The paths of the fields of [Spoken], [Choice] and [DialogueEntry], as codegen emits a type's fields. */
object SpokenFields {
    val minLines: TypedPath<Spoken, Var<Int, EventContext<Said>>> =
        typedPath(SpokenDefinition.id, ValuePath.root.field("minLines"), formulaOf(int))
    val maxLineLength: TypedPath<Spoken, Int> = typedPath(SpokenDefinition.id, ValuePath.root.field("maxLineLength"), int)
}

object ChoiceFields {
    val text: TypedPath<Choice, Var<String, EventContext<Said>>> =
        typedPath(ChoiceDefinition.id, ValuePath.root.field("text"), formulaOf(ScalarKind.TEXT.use))
}

object DialogueEntryFields {
    val spoken: TypedPath<DialogueEntry, Spoken> =
        typedPath(DialogueEntryDefinition.id, ValuePath.root.field("spoken"), SpokenDefinition.id.use())
    val aside: TypedPath<DialogueEntry, Spoken?> =
        typedPath(DialogueEntryDefinition.id, ValuePath.root.field("aside"), asideType)
    val choices: TypedPath<DialogueEntry, List<Choice>> =
        typedPath(DialogueEntryDefinition.id, ValuePath.root.field("choices"), choicesType)
    val opens: TypedPath<DialogueEntry, Var<Boolean, EventContext<Said>>> =
        typedPath(DialogueEntryDefinition.id, ValuePath.root.field("opens"), formulaOf(boolean))
    val greeting: TypedPath<DialogueEntry, Var<String, EventContext<Said>>> =
        typedPath(DialogueEntryDefinition.id, ValuePath.root.field("greeting"), formulaOf(text))
    val farewell: TypedPath<DialogueEntry, Var<String, EventContext<Said>>> =
        typedPath(DialogueEntryDefinition.id, ValuePath.root.field("farewell"), formulaOf(text))
}

// The accessors of the three records, as codegen emits them.

val RecordScope<Spoken>.minLines: Int get() = readField(SpokenFields.minLines)

val RecordScope<Spoken>.maxLineLength: Int get() = readField(SpokenFields.maxLineLength)

val RecordScope<Choice>.text: String get() = readField(ChoiceFields.text)

val RecordScope<DialogueEntry>.spoken: RecordScope<Spoken> get() = recordField(DialogueEntryFields.spoken)

val RecordScope<DialogueEntry>.aside: RecordScope<Spoken>? get() = optionalRecordField(DialogueEntryFields.aside)

val RecordScope<DialogueEntry>.choices: List<RecordScope<Choice>> get() = recordList(DialogueEntryFields.choices)

val RecordScope<DialogueEntry>.opens: Boolean get() = readField(DialogueEntryFields.opens)

val RecordScope<DialogueEntry>.greeting: String get() = readField(DialogueEntryFields.greeting)

val RecordScope<DialogueEntry>.farewell: String get() = readField(DialogueEntryFields.farewell)

/** A [DialogueEntry] named [id], with [spoken], an optional [aside], [choices] and its three formula fields. */
fun dialogueEntry(
    id: String,
    spoken: Spoken,
    aside: Spoken? = null,
    choices: List<Choice> = emptyList(),
    opens: Var<Boolean, EventContext<Said>> = Var.Value(true),
    greeting: Var<String, EventContext<Said>> = Var.Value(""),
    farewell: Var<String, EventContext<Said>> = Var.Value(""),
): PublishedResource =
    PublishedResource(id, DialogueEntryDefinition.id.use(), DialogueEntry(id, spoken, aside, choices, opens, greeting, farewell))

/**
 * A publication of one dialogue entry, `dialogue`, spoken in at least [minLines] lines of at most [maxLineLength], with a
 * choice per text in [choices], the written [opens], [greeting] and [farewell], and an optional [aside].
 */
fun dialoguePublication(
    minLines: Var<Int, EventContext<Said>> = Var.Value(1),
    maxLineLength: Int = 40,
    choices: List<Var<String, EventContext<Said>>> = emptyList(),
    opens: Boolean = true,
    greeting: String = "hello",
    farewell: String = "goodbye",
    aside: Spoken? = null,
): FormulaPublication =
    FormulaPublication(
        dialogueEntry(
            "dialogue",
            Spoken(minLines, maxLineLength),
            aside,
            choices.map(::Choice),
            Var.Value(opens),
            Var.Value(greeting),
            Var.Value(farewell),
        ),
    )
