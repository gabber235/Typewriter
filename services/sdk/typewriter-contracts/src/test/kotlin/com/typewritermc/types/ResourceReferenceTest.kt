package com.typewritermc.types

import com.typewritermc.authoring.field
import com.typewritermc.authoring.root
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import kotlinx.serialization.json.Json
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

    test("a ref stores its target and, when it has one, its opposite path, and reads back the same") {
        val bare = LinkHolder(Ref(ResourceId("smith")))
        val placed = LinkHolder(Ref(ResourceId("smith"), ValuePath.root.field("giver")))
        val everyField = Json { encodeDefaults = true }

        Json.encodeToString(LinkHolder.serializer(), bare) shouldBe """{"link":{"target":"smith"}}"""
        everyField.encodeToString(LinkHolder.serializer(), bare) shouldBe """{"link":{"target":"smith","opposite":null}}"""
        Json.encodeToString(LinkHolder.serializer(), placed) shouldBe
            """{"link":{"target":"smith","opposite":{"segments":[{"kind":"field","value":{"name":"giver"}}]}}}"""
        Json.decodeFromString(LinkHolder.serializer(), """{"link":{"target":"smith"}}""").link.opposite shouldBe null
        Json.decodeFromString(LinkHolder.serializer(), Json.encodeToString(LinkHolder.serializer(), placed)).link.opposite shouldBe
            ValuePath.root.field("giver")
    }

    test("a link that admits any resource of a generic definition is stored like any other link") {
        val holder = StarLinkHolder(Ref(ResourceId("board")))

        Json.encodeToString(StarLinkHolder.serializer(), holder) shouldBe """{"link":{"target":"board"}}"""
        Json.decodeFromString(StarLinkHolder.serializer(), """{"link":{"target":"board"}}""") shouldBe holder
    }
}
