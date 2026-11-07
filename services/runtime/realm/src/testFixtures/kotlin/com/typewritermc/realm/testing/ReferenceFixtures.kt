package com.typewritermc.realm.testing

import com.typewritermc.authoring.bind
import com.typewritermc.authoring.orNull
import com.typewritermc.elements.ElementFields
import com.typewritermc.formula.Formula
import com.typewritermc.formula.FormulaReference
import com.typewritermc.formula.TextSpan
import com.typewritermc.formula.VarDefinition
import com.typewritermc.library.PageFields
import com.typewritermc.realm.authoring.CapturedAuthoringReads
import com.typewritermc.realm.authoring.readNow
import com.typewritermc.realm.formula.DisplayOf
import com.typewritermc.realm.formula.FormulaSite
import com.typewritermc.realm.formula.FormulasOf
import com.typewritermc.types.FORMULA_USE
import com.typewritermc.types.Ref
import com.typewritermc.types.functionUse
import com.typewritermc.types.member
import com.typewritermc.types.named
import com.typewritermc.types.namedUse
import com.typewritermc.types.record
import com.typewritermc.types.toResourceId
import com.typewritermc.types.toSkir
import com.typewritermc.types.use
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.TypeUse
import skirout.kernel.v1.resource_id.ResourceId
import com.typewritermc.types.ResourceId as AuthorResourceId

/*
 * The reference kit: what the realm stored for a resource's formula, the text a creator reads, and the edits a panel
 * sends for formula text, references included, so a test can send ones a panel never would.
 */

/** The one formula [resource] stores, as the realm reads it now. */
private fun RealmFixture.formulaOf(resource: ResourceId): FormulaSite = readNow(FormulasOf(resource)).single()

/** The references the formula of [resource] stores, in order: each span with its target, or null once a delete emptied it. */
fun RealmFixture.references(resource: ResourceId): List<Pair<TextSpan, ResourceId?>> =
    formulaOf(resource).formula.references.map { it.at to it.target?.toSkir() }

/** The resources the formula references of [resource] point at. */
fun RealmFixture.referenceTargets(resource: ResourceId): List<ResourceId> = references(resource).mapNotNull { it.second }

/** The source text the formula of [resource] stores. */
fun RealmFixture.storedSource(resource: ResourceId): String = formulaOf(resource).formula.source

/** The formula text of [resource] as a creator reads it, with references shown by their targets' current names. */
fun RealmFixture.displayOf(resource: ResourceId): String = readNow(DisplayOf(formulaOf(resource).at))

/**
 * Replaces the formula of [resource] with the text [source], carrying [references] as a client sent them, each span
 * pointing at its resource.
 */
fun RealmFixture.setFormula(
    resource: ResourceId,
    source: String,
    references: List<Pair<TextSpan, ResourceId>> = emptyList(),
): EditIntent = EditIntent.createSetValue(at = formulaOf(resource).at, value = encoder.encode(FORMULA_USE.use, spanned(source, references)))

/** A Definition's value computed by [source] with [references] as a client sent them, each span pointing at its resource. */
fun RealmFixture.spannedComputedVar(
    type: TypeUse,
    source: String,
    references: List<Pair<TextSpan, ResourceId>>,
): DataValue =
    DataValue.named(
        VarDefinition.id.member("Computed").namedUse(listOf(type, functionUse(result = type))),
        DataValue.record("formula" to encoder.encode(FORMULA_USE.use, spanned(source, references))),
    )

/** Duplicates [resource] with everything it owns, as the Duplicate operation does, and returns the copy. */
suspend fun RealmFixture.duplicate(resource: ResourceId): ResourceId {
    var copy: ResourceId? = null
    operate(listOf(resource)) { copy = duplicate(listOf(resource.toResourceId())).single().toSkir() }.shouldBeCommitted()
    return checkNotNull(copy)
}

/** The element of [page] whose name is [name]. */
fun RealmFixture.elementNamed(
    page: ResourceId,
    name: String,
): ResourceId =
    views.capture().use { lease ->
        val reads = CapturedAuthoringReads(lease.originalView())
        reads
            .read(PageFields.elements.bind(page.toResourceId()))
            .orNull()
            .orEmpty()
            .map { it.target }
            .single { reads.read(ElementFields.name.bind(it)).orNull() == name }
            .toSkir()
    }

private fun spanned(
    source: String,
    references: List<Pair<TextSpan, ResourceId>>,
): Formula = Formula(source, references.map { (at, target) -> FormulaReference(at, Ref(AuthorResourceId(target.value))) })
