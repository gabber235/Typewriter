package com.typewritermc.realm

import com.typewritermc.realm.testing.RealmCatalog
import java.nio.file.Path

/**
 * The core catalog plus the route fixture extension, whose concrete pages, entries and capabilities core does not
 * declare. The build hands over the extension JAR's path; the realm build file explains why it is no classpath entry.
 */
internal val routeFixtureCatalog =
    RealmCatalog(
        artifacts =
            listOf(
                RealmCatalog.extension("typewritermc:realm-route-fixtures", Path.of(System.getProperty("typewriter.realm.routeFixtures"))),
            ),
    )
