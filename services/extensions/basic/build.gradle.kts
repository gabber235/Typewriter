plugins {
    id("com.typewritermc.basic-conventions")
    id("com.typewritermc.imprint")
    id("com.typewritermc.paper-api")
    alias(libs.plugins.kotlin.serialize)
}

typewriter {
    extension {
        id = "typewritermc:basic"
        version = "1.0.0"

        sourceSet("enginePaper") {
            engine(project(":engine-paper"), version = "^1")
        }
    }
}

dependencies {
    imprintExtensionApi(project(":typewriter-api"))
    imprintEngineCore(project(":engine-core"))

    testImplementation(project(":typewriter-api"))
    testImplementation(project(":engine-core"))
    testImplementation(testFixtures(project(":engine-core")))
}
