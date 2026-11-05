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
    implementation(project(":messaging"))
    implementation(project(":protocol-transport"))
    implementation(libs.kotlin.serialize.json)
    testFixturesApi(project(":loader-api"))
    testFixturesApi(testFixtures(project(":messaging")))
    testFixturesApi(testFixtures(project(":telemetry")))
    testFixturesApi(testFixtures(project(":file-transfer")))
    testFixturesApi(libs.kotlin.coroutines.test)
}

typewriter {
    engineCore()
}
