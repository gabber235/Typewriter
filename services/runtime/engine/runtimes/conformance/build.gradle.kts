plugins {
    id("com.typewritermc.basic-conventions")
    id("com.typewritermc.imprint")
}

dependencies {
    imprintEngineCore(project(":engine-core"))
    imprintHostApi(project(":loader-api"))
    imprintPlatformApi(project(":typewriter-api"))
}

typewriter {
    engine {
        id = "typewritermc:conformance"
        version = "1.0.0"
        hostApi = "^1"
        implements {
            capability(project(":engine-conformance-composite"), version = "1.0.0")
        }
    }
}
