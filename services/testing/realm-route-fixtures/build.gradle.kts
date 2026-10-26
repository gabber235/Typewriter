plugins {
    id("com.typewritermc.basic-conventions")
    id("com.typewritermc.imprint")
}

// Real page and entry types for Realm route tests. Its own extension because the realm test source set runs no
// Typewriter KSP; processing these declarations generates their setups like any extension's.
typewriter {
    extension {
        id = "typewritermc:realm-route-fixtures"
        version = "1.0.0"
    }
}

dependencies {
    imprintExtensionApi(project(":typewriter-api"))
}
