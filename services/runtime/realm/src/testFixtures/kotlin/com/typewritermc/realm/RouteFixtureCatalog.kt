package com.typewritermc.realm

import com.typewritermc.realm.testing.RealmCatalog
import com.typewritermc.testing.routes.FixtureGraphPage

/**
 * The catalog route and formula tests share: the core catalog, the real engine core the way a deployment lists it among
 * its catalog artifacts, and the route fixture extension, whose concrete pages and entries core does not declare.
 */
internal val routeFixtureCatalog =
    RealmCatalog(
        artifacts =
            listOf(
                RealmCatalog.engineCore,
                RealmCatalog.extension("typewritermc:realm-route-fixtures", FixtureGraphPage::class),
            ),
    )
