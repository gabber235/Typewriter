package com.typewritermc.realm.testing

import com.typewritermc.setup.SetupRoot
import com.typewritermc.types.use
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.checking.CheckInstanceId
import skirout.editor.v1.diagnostic.Diagnostic
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeUse
import skirout.kernel.v1.resource_id.ResourceId

/*
 * The formula demos' kit: one static page of Definitions, formulas and custom types, committed through the stored forms
 * the panel sends, and the reads that observe what the realm made of it. Bodies arrive with the layer step that needs
 * them; until then they throw NotImplementedError, so the demos are red for that reason alone.
 */

/** The text type, as a field or a Definition declares it. */
val stringUse: TypeUse = ScalarKind.TEXT.use

/** The text type a field added to a custom type holds. */
val textUse: TypeUse = ScalarKind.TEXT.use

/**
 * A static page holding what [block] declares, returning its handles by name. A setup is built while its suite is
 * configured, so this stub builds nothing and its handles throw instead, which keeps a demo red inside its own tests.
 */
@Suppress("UnusedParameter")
fun SetupRoot.formulaPage(block: FormulaPageBuilder.() -> Unit): FormulaPage = FormulaPage()

/** Declares Definitions, formulas, custom types and entries on one static page. */
class FormulaPageBuilder {
    /** A Definition named [name] of [type] holding the plain [value]. */
    fun definition(
        name: String,
        type: TypeUse,
        value: DataValue,
    ): ResourceId = TODO("Definition with a plain value")

    /** A Definition named [name] of [type] whose value is the formula [source]. */
    fun formula(
        name: String,
        type: TypeUse,
        source: String,
    ): ResourceId = TODO("Definition with a formula")

    /** A Definition named [name] holding the custom type [build] declares. */
    fun customType(
        name: String,
        build: TypeDefinitionBuilder.() -> Unit,
    ): ResourceId = TODO("Definition holding a custom type")

    /** A FixtureStaticEntry named [name], a real entry next to the Definitions. */
    fun smith(name: String = "smith"): ResourceId = TODO("static entry on the formula page")
}

/** The fields and cases of one custom type declaration. */
class TypeDefinitionBuilder {
    /** A field [name] holding [type]. */
    fun field(
        name: String,
        type: TypeUse,
    ): Unit = TODO("custom type field")
}

/** Demo 1, the roadmap's acceptance goal: base_reward, bonus and total. */
fun FormulaPageBuilder.demoOneDefinitions(): Unit = TODO("demo one content")

/** Demo 2: the Reward type, first_reward, giver_name, gift and door; needs [FormulaPageBuilder.smith] and demo 1. */
fun FormulaPageBuilder.demoTwoDefinitions(): Unit = TODO("demo two content")

/** The handles of a formula page: the page and every resource the demos name. */
class FormulaPage internal constructor() {
    val pageId: ResourceId get() = TODO("formula page handles")
    val baseReward: ResourceId get() = TODO("formula page handles")
    val bonus: ResourceId get() = TODO("formula page handles")
    val total: ResourceId get() = TODO("formula page handles")
    val smith: ResourceId get() = TODO("formula page handles")
    val reward: ResourceId get() = TODO("formula page handles")
    val firstReward: ResourceId get() = TODO("formula page handles")
    val giverName: ResourceId get() = TODO("formula page handles")
    val gift: ResourceId get() = TODO("formula page handles")
    val door: ResourceId get() = TODO("formula page handles")
}

/** What the realm computed for formulas: a value at a path, the text as an author reads it, and the checked type. */
class FormulaReads internal constructor() {
    /** The evaluated value of [resource], or of the field at [path] inside it, as a plain Kotlin value. */
    fun value(
        resource: ResourceId,
        vararg path: String,
    ): Any? = TODO("formula evaluation")

    /** The formula text of [resource] with references shown by their targets' current names. */
    fun display(resource: ResourceId): String = TODO("formula display")

    /** The checked type of [resource]'s value. */
    fun type(resource: ResourceId): TypeUse = TODO("formula type")
}

/** The formula reads on this realm. */
val RealmFixture.formulas: FormulaReads get() = FormulaReads()

/** The error findings whose primary location is on [resource], after the checks settled. */
fun RealmFixture.errorsOn(resource: ResourceId): List<Diagnostic> = TODO("findings by resource")

/** How often the graph computed each CheckRun so far, per check instance, counting an equal rerun too. */
fun RealmFixture.settledRuns(): Map<CheckInstanceId, Long> = TODO("graph run counts")

/** The check instances the graph computed again since [before]. */
fun RealmFixture.rerunSince(before: Map<CheckInstanceId, Long>): Set<CheckInstanceId> = TODO("graph reruns")

/** The resources these check instances judge. */
fun Set<CheckInstanceId>.resources(): Set<ResourceId> = TODO("check instance resources")

/** Waits until every check the last commit started has finished. */
suspend fun RealmFixture.settle(): Unit = TODO("check settling")

/** Changes the type of the Definition [resource] to [to] with the repair the preview proposes, as the panel commits it. */
suspend fun RealmFixture.commitPreparedTypeChange(
    resource: ResourceId,
    to: TypeUse,
): CommitPreparedEditResponse = TODO("Definition type change")

/** The saved record of [resource]. */
fun RealmFixture.record(resource: ResourceId): AuthoringRecord = TODO("saved record")

/** The saved records of [resources], in order. */
fun RealmFixture.records(vararg resources: ResourceId): List<AuthoringRecord> = TODO("saved records")

/** The saved value at the field [path] of [resource]. */
fun RealmFixture.value(
    resource: ResourceId,
    vararg path: String,
): DataValue? = TODO("saved value")

/** The resources the formula references of [resource] point at. */
fun RealmFixture.referenceTargets(resource: ResourceId): List<ResourceId> = TODO("formula reference targets")

/** The findings that block publishing now. */
fun RealmFixture.publicationBlockers(): List<Diagnostic> = TODO("publication blockers")

/** Asserts that one of these findings points at [resource]. */
infix fun List<Diagnostic>.shouldContainLocation(resource: ResourceId): Unit = TODO("blocker location")

/** Renames [resource] to [name]. */
fun rename(
    resource: ResourceId,
    name: String,
): EditIntent = TODO("rename intent")

/** Deletes [resource]. */
fun delete(resource: ResourceId): EditIntent = TODO("delete intent")

/** Points the plain giver link of the gift Definition [gift] at [to]. */
fun setGiver(
    gift: ResourceId,
    to: ResourceId,
): EditIntent = TODO("set giver intent")

/** Replaces the formula text of [resource] with [source]. */
fun setFormula(
    resource: ResourceId,
    source: String,
): EditIntent = TODO("set formula intent")

/** Adds the field [name] holding [type] to the custom type the Definition [type] declares. */
fun addField(
    type: ResourceId,
    name: String,
    field: TypeUse,
): EditIntent = TODO("add field intent")
