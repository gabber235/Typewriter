package com.typewritermc.realm.formula

import com.typewritermc.realm.routeFixtureCatalog
import com.typewritermc.realm.testing.commit
import com.typewritermc.realm.testing.createEntry
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.realm.testing.staticPage
import com.typewritermc.realm.testing.withSetup
import de.infix.testBalloon.framework.core.testSuite

val BuildFoundationTest by testSuite {
    test("a static entry commits on a static page") {
        withSetup(staticPage, catalog = routeFixtureCatalog) { commit(createEntry("smith")).shouldBeCommitted() }
    }
}
