package com.typewritermc.types.catalog

import com.typewritermc.authoring.of
import com.typewritermc.types.TEXT
import com.typewritermc.types.catalog
import com.typewritermc.types.id
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.recordDefinition
import com.typewritermc.types.resourceDefinition
import com.typewritermc.types.rewardDefinition
import com.typewritermc.types.template
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ResourceMatch
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeSelection

val ResourceMatchTest by testSuite {
    val resource = resourceDefinition()
    val reward = rewardDefinition(resource.id)
    val ledger = recordDefinition("ledger")
    val pairId = id("pair")
    val first = ParameterKey(owner = pairId, index = 0)
    val second = ParameterKey(owner = pairId, index = 1)
    val pair =
        TypeDefinition.partial(
            id = pairId,
            parameters = listOf(TypeParameter.partial(key = first, name = "A"), TypeParameter.partial(key = second, name = "B")),
            representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.CONCRETE),
            parents = listOf(resource.id.namedTemplate()),
        )
    val labelledId = id("labelled")
    val labelled =
        TypeDefinition.partial(
            id = labelledId,
            parameters = listOf(TypeParameter.partial(key = ParameterKey(owner = labelledId, index = 0), name = "B")),
            representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.CONCRETE),
            parents = listOf(pair.id.namedTemplate(listOf(ScalarKind.TEXT.template, ParameterKey(owner = labelledId, index = 0).template))),
        )
    val board = boardDefinition()
    val catalog =
        catalog(resource, reward, ledger, pair, labelled, board)
            .withContent(derives(DerivedTarget.Declared(derivedRecord("gold" to TEXT))))
    val boolean = ScalarKind.BOOLEAN.use

    test("any resource fits every resource, whatever its choices") {
        catalog.fits(TypeSelection.of(ledger.id), ResourceMatch.ANY_RESOURCE, owner = null) shouldBe Fit.YES
        catalog.fits(TypeSelection.of(board.id), ResourceMatch.ANY_RESOURCE, owner = null) shouldBe Fit.YES
    }

    test("a definition fits its nominal subtypes whatever their arguments, before any argument is chosen") {
        val any = ResourceMatch.DefinitionWrapper(resource.id)

        catalog.fits(TypeSelection.of(reward.id), any, owner = null) shouldBe Fit.YES
        catalog.fits(TypeSelection.of(pair.id), any, owner = null) shouldBe Fit.YES
        catalog.fits(TypeSelection.of(pair.id, mapOf(0 to TEXT, 1 to boolean)), any, owner = null) shouldBe Fit.YES
        catalog.fits(TypeSelection.of(ledger.id), any, owner = null) shouldBe Fit.NO
    }

    test("a definition fits a resource whose parameter a bind computes, with no computed type") {
        catalog.fits(TypeSelection.of(board.id), ResourceMatch.DefinitionWrapper(board.id), owner = null) shouldBe Fit.YES
    }

    test("a type fits a complete resource readable as it") {
        val exact = ResourceMatch.TypeWrapper(pair.id.namedUse(listOf(TEXT, boolean)))

        catalog.fits(TypeSelection.of(pair.id, mapOf(0 to TEXT, 1 to boolean)), exact, owner = null) shouldBe Fit.YES
        catalog.fits(TypeSelection.of(pair.id, mapOf(0 to TEXT, 1 to TEXT)), exact, owner = null) shouldBe Fit.NO
        catalog.fits(TypeSelection.of(reward.id), ResourceMatch.TypeWrapper(resource.id.namedUse()), owner = null) shouldBe Fit.YES
    }

    test("a type is undecided for a pending resource of its definition, and fits once a known application reads as it") {
        val exact = ResourceMatch.TypeWrapper(pair.id.namedUse(listOf(TEXT, boolean)))

        catalog.fits(TypeSelection.of(pair.id, mapOf(0 to TEXT)), exact, owner = null) shouldBe Fit.UNDECIDED
        catalog.fits(TypeSelection.of(pair.id, mapOf(0 to TEXT)), ResourceMatch.TypeWrapper(resource.id.namedUse()), owner = null) shouldBe
            Fit.YES
        catalog.fits(TypeSelection.of(ledger.id), exact, owner = null) shouldBe Fit.NO
    }

    test("a type does not fit a pending resource whose chosen argument does not read as the expected one") {
        val chosenText = TypeSelection.of(pair.id, mapOf(0 to TEXT))

        catalog.fits(chosenText, ResourceMatch.TypeWrapper(pair.id.namedUse(listOf(boolean, boolean))), owner = null) shouldBe Fit.NO
        catalog.fits(chosenText, ResourceMatch.TypeWrapper(pair.id.namedUse(listOf(TEXT, boolean))), owner = null) shouldBe Fit.UNDECIDED
    }

    test("a type does not fit a pending subtype whose parent fixes an argument that does not read as the expected one") {
        val pending = TypeSelection.of(labelled.id)

        catalog.fits(pending, ResourceMatch.TypeWrapper(pair.id.namedUse(listOf(boolean, boolean))), owner = null) shouldBe Fit.NO
        catalog.fits(pending, ResourceMatch.TypeWrapper(pair.id.namedUse(listOf(TEXT, boolean))), owner = null) shouldBe Fit.UNDECIDED
    }

    test("with an owner, a type reads the computed type its binds answer") {
        val computed = ResourceMatch.TypeWrapper(board.id.namedUse(listOf(DERIVED_V.use())))

        catalog.fits(TypeSelection.of(board.id), computed, owner = null) shouldBe Fit.UNDECIDED
        catalog.fits(TypeSelection.of(board.id), computed, owner = DERIVING_BOARD) shouldBe Fit.YES
    }
}
