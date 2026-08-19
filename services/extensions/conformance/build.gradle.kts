plugins {
    id("com.typewritermc.basic-conventions")
    id("com.typewritermc.imprint")
}

typewriter {
    extension {
        id = "typewritermc:conformance"
        version = "1.0.0"

        targets {
            realm(version = "1.0.0")
            panel(version = "1.0.0")
            engine("paper", version = "1.0.0")
            engine("conformance", version = "1.0.0")
        }
    }
}

dependencies {
    testImplementation(project(":extension-types"))
}
