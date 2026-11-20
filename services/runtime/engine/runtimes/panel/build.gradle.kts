plugins {
    id("com.typewritermc.basic-conventions")
    `java-test-fixtures`
    id("com.typewritermc.imprint")
}

dependencies {
    imprintEngineCore(project(":engine-core"))
    imprintHostApi(project(":loader-api"))
    imprintPlatformApi(project(":typewriter-api"))
    testFixturesApi(testFixtures(project(":engine-core")))
    testFixturesImplementation(project(":protocol-transport"))
}

typewriter {
    engine {
        id = "typewritermc:panel"
        version = "1.0.0"
        hostApi = "^1"
    }
}
