package com.typewritermc.realm.authoring

import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.realm.edit.NESTED_FIRST
import com.typewritermc.realm.edit.PAIR_SECOND
import com.typewritermc.realm.edit.PARENT_FIRST
import com.typewritermc.realm.edit.at
import com.typewritermc.realm.edit.counterpartOf
import com.typewritermc.realm.edit.path
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId

val CounterpartBindingTest by testSuite {
    val resource = ResourceId(value = "counterpart")

    test("the inverse of a scalar endpoint is its scalar field") {
        counterpartOf(PAIR_SECOND, resource) shouldBe CounterpartBinding.Scalar(at(resource, "second"))
    }

    test("the inverse of a collection endpoint is its collection field") {
        counterpartOf(PARENT_FIRST, resource) shouldBe CounterpartBinding.Collection(at(resource, "children"))
    }

    test("the inverse of an endpoint inside a record field is the nested field") {
        counterpartOf(NESTED_FIRST, resource) shouldBe CounterpartBinding.Scalar(ValueLocation.of(resource, path("wrapper").field("inner")))
    }

    test("an endpoint the resource declares no field for has no inverse") {
        counterpartOf(EndpointId(value = "absent"), resource) shouldBe CounterpartBinding.Missing
    }
}
