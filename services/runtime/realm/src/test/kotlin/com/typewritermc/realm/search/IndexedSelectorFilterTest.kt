package com.typewritermc.realm.search

import com.typewritermc.types.ResourceId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe

val IndexedSelectorFilterTest by testSuite {
    test("negated selector filters require a bounded definition universe") {
        IndexedSelectorFilter
            .Not(
                IndexedSelectorFilter.Match("status", "draft"),
            ).requiresDefinitionUniverse shouldBe true
        IndexedSelectorFilter
            .And(
                IndexedSelectorFilter.Match("status", "draft"),
                IndexedSelectorFilter.Match("kind", "quest"),
            ).requiresDefinitionUniverse shouldBe false
    }

    test("selector record ids do not use the JVM hash collision domain") {
        selectorId(ResourceId("resource"), "status", "Aa") shouldNotBe
            selectorId(ResourceId("resource"), "status", "BB")
    }
}
