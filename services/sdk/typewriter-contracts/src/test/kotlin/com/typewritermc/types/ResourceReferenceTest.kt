package com.typewritermc.types

import com.typewritermc.authoring.field
import com.typewritermc.authoring.root
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import skirout.editor.v1.type_catalog.ValuePath

val ResourceReferenceTest by testSuite {
    test("two refs to one resource are equal whatever opposite path they store, and are one item in a set") {
        val stored = Ref<RelationshipEndpoint<Resource, Resource>, Resource>(ResourceId("smith"), ValuePath.root.field("giver"))
        val built = Ref<RelationshipEndpoint<Resource, Resource>, Resource>(ResourceId("smith"))
        stored shouldBe built
        setOf(stored, built) shouldHaveSize 1
    }

    test("refs to different resources stay different") {
        Ref<RelationshipEndpoint<Resource, Resource>, Resource>(ResourceId("smith")) shouldNotBe
            Ref<RelationshipEndpoint<Resource, Resource>, Resource>(ResourceId("baker"))
    }

    test("a copy keeps the stored opposite path") {
        val stored = Ref<RelationshipEndpoint<Resource, Resource>, Resource>(ResourceId("smith"), ValuePath.root.field("giver"))
        stored.copy().opposite shouldBe ValuePath.root.field("giver")
    }
}
