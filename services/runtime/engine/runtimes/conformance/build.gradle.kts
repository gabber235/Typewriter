plugins {
    id("com.typewritermc.basic-conventions")
    id("com.typewritermc.imprint")
}

dependencies {
    imprintEngineCore(project(":engine-core"))
    imprintHostApi("com.typewritermc:loader-api")
    testImplementation(libs.kotlin.coroutines.test)
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
