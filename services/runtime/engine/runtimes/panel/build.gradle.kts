plugins {
    id("com.typewritermc.basic-conventions")
    id("com.typewritermc.imprint")
}

dependencies {
    imprintEngineCore(project(":engine-core"))
    imprintHostApi(project(":loader-api"))
}

typewriter {
    engine {
        id = "typewritermc:panel"
        version = "1.0.0"
        hostApi = "^1"
    }
}
