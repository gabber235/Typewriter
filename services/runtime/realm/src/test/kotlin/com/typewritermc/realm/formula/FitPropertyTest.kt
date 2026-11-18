package com.typewritermc.realm.formula

import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.realm.routeFixtureCatalog
import com.typewritermc.realm.testing.errorCodesOn
import com.typewritermc.realm.testing.staticPage
import com.typewritermc.realm.testing.storeByHand
import com.typewritermc.realm.testing.storedCase
import com.typewritermc.realm.testing.storedCaseConfig
import com.typewritermc.realm.testing.withSetup
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.withClue
import io.kotest.matchers.collections.shouldNotBeEmpty
import io.kotest.matchers.ints.shouldBeGreaterThan
import io.kotest.property.checkAll

val FitPropertyTest by testSuite {
    test("every stored value complete() refuses has a fit finding on its holder") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            var refused = 0
            var index = 0
            checkAll(storedCaseConfig, storedCase) { case ->
                val (held, complete) = storeByHand("held-${index++}", case)
                if (complete is CompletenessResult.Invalid) {
                    refused++
                    withClue("$case refused for ${complete.problems}") { errorCodesOn(held).shouldNotBeEmpty() }
                }
            }
            // The generator must reach the property: a run where nothing is refused proves nothing.
            refused shouldBeGreaterThan 10
        }
    }
}
