package com.typewritermc.realm.authoring

import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.realm.edit.NESTED_FIRST
import com.typewritermc.realm.edit.PAIR_SECOND
import com.typewritermc.realm.edit.PARENT_FIRST
import com.typewritermc.realm.edit.at
import com.typewritermc.realm.edit.node
import com.typewritermc.realm.edit.nodeCatalog
import com.typewritermc.realm.edit.path
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId

private val resource = ResourceId(value = "counterpart")

/** Where a node holds the inverse of a link through [endpoint]. */
private fun bindingOf(endpoint: EndpointId): CounterpartBinding =
    nodeCatalog().lease().use { ResourceValueMapper.counterpartBinding(endpoint, resource, node(), it.checked) }

val CounterpartBindingTest by testSuite {
    test("the inverse of a scalar endpoint is its scalar field") {
        bindingOf(PAIR_SECOND) shouldBe CounterpartBinding.Scalar(at(resource, "second"))
    }

    test("the inverse of a collection endpoint is its collection field") {
        bindingOf(PARENT_FIRST) shouldBe CounterpartBinding.Collection(at(resource, "children"))
    }

    test("the inverse of an endpoint inside a record field is the nested field") {
        bindingOf(NESTED_FIRST) shouldBe CounterpartBinding.Scalar(ValueLocation.of(resource, path("wrapper").field("inner")))
    }

    test("an endpoint the resource declares no field for has no inverse") {
        bindingOf(EndpointId(value = "absent")) shouldBe CounterpartBinding.Missing
    }
}
