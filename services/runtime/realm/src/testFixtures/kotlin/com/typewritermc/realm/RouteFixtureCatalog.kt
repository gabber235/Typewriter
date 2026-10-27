package com.typewritermc.realm

import com.typewritermc.realm.testing.RealmCatalog
import com.typewritermc.testing.routes.FixtureGraphPage

/** The core catalog plus the route fixture extension, whose concrete pages and entries core does not declare. */
internal val routeFixtureCatalog =
    RealmCatalog(artifacts = listOf(RealmCatalog.extension("typewritermc:realm-route-fixtures", FixtureGraphPage::class)))
