package com.typewritermc.authoring

import com.typewritermc.types.TEXT_TEMPLATE
import com.typewritermc.types.catalog
import com.typewritermc.types.catalog.misfits
import com.typewritermc.types.field
import com.typewritermc.types.id
import com.typewritermc.types.linkDefinition
import com.typewritermc.types.namedUse
import com.typewritermc.types.recordDefinition
import com.typewritermc.types.referenceTo
import com.typewritermc.types.resourceDefinition
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.diagnostic.ValueProblem
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId

val MisfitCauseTest by testSuite {
    val owner = ResourceId(value = "owner")
    val resource = resourceDefinition()
    val home = linkDefinition(id("home_link"))
    val holder = recordDefinition("holder", field("holder", "home", referenceTo(home.id, resource.id)))
    val catalog = catalog(resource, home, holder)
    val smith = ResourceId(value = "smith")

    val misplacedLink =
        DataValue.createLink(
            endpoint = EndpointId(value = "elsewhere"),
            target = LinkTarget(resource = smith, opposite = null),
        )

    test("a misfit where a link is stored names that link's target") {
        val record = AuthoringRecord.of(TypeSelection.of(holder.id.namedUse()), mapOf("home" to misplacedLink))

        record.misfits(owner, catalog).map { it.cause } shouldBe listOf(MisfitCause.Link(smith))
    }

    test("a value at a position its type does not declare is undeclared, even when it holds a link") {
        val record =
            AuthoringRecord.of(
                TypeSelection.of(holder.id.namedUse()),
                mapOf("home" to DataValue.UNFILLED, "stray" to misplacedLink),
            )

        record.misfits(owner, catalog).map { it.cause } shouldBe listOf(MisfitCause.Undeclared)
    }

    test("a misfit link that points at another target is new, and one whose link was removed is not") {
        val problem = ValueProblem(location = ValueLocation.of(owner), code = "wrong_endpoint")
        val before = setOf(Misfit(problem, MisfitCause.Link(ResourceId(value = "anvil"))))

        Misfit(problem, MisfitCause.Link(smith)).isNewAgainst(before) shouldBe true
        Misfit(problem, MisfitCause.Shape).isNewAgainst(before) shouldBe false
    }
}
