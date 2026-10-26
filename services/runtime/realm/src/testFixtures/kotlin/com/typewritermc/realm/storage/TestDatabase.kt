package com.typewritermc.realm.storage

import com.surrealdb.Surreal
import java.util.UUID

/** Opens a fresh embedded in memory database named after [name], so storage scenarios never share state. */
internal fun Surreal.openTestDatabase(name: String) {
    connect("mem://")
    useNs("typewriter_tests").useDb(name + "_" + UUID.randomUUID().toString().replace("-", ""))
}
