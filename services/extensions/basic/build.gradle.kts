plugins {
    id("com.typewritermc.basic-conventions")
    id("com.typewritermc.imprint")
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
}
