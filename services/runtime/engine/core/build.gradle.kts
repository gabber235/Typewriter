plugins {
    id("com.typewritermc.basic-conventions")
    id("com.typewritermc.imprint")
    `java-library`
    `java-test-fixtures`
}

dependencies {
    api(project(":engine-api"))
    compileOnlyApi(project(":loader-api"))
    api(project(":typewriter-api"))
    api(libs.kotlin.coroutines.core)
    api(platform(libs.koin.bom))
    api(libs.koin.core)
    // Engine kinds reach messaging, its key value buckets and the generated contracts through engine-core.
    api(project(":messaging"))
    api(project(":protocol-transport"))
    implementation(libs.kotlin.serialize.json)
    testFixturesApi(project(":loader-api"))
    testFixturesApi(testFixtures(project(":loader-api")))
    testFixturesApi(project(":messaging"))
    testFixturesImplementation(project(":protocol-transport"))
    testFixturesApi(testFixtures(project(":messaging")))
    testFixturesApi(testFixtures(project(":telemetry")))
    testFixturesApi(testFixtures(project(":file-transfer")))
    testFixturesApi(libs.kotlin.coroutines.test)
}

typewriter {
    engineCore()
}
