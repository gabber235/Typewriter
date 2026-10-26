package com.typewritermc.realm.publication

import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.authoring_facts.EditExpectation
import skirout.editor.v1.publication.DiagnosticEvidence
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId

val PublicationViewTest by testSuite {
    test("a publication blocker carries the finding's location and the evidence it was captured with") {
        val location = ValueLocation.of(ResourceId(value = "page"), ValuePath.root.field("name"))
        val finding = compilationDiagnostic("unfinished_value", "A required value is unfinished.", location = location)
        val captured =
            DiagnosticEvidence(
                catalog = CatalogGeneration(value = "catalog"),
                expectations = listOf(EditExpectation.createValue(at = location, expected = DataValue.UNFILLED)),
            )

        val details = finding.blocker(captured).details

        details.primary shouldBe location
        details.evidence shouldBe captured
        finding.blocker(evidence = null).details.evidence shouldBe null
    }
}
