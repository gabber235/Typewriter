plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.kotlin.serialize)
    `java-library`
    `java-test-fixtures`
}

dependencies {
    api(project(":messaging"))
    implementation(project(":protocol-transport"))
    api(project(":telemetry"))
    api(project(":internal-utils"))
    api(platform(libs.koin.bom))
    api(platform(libs.opentelemetry.bom))
    api(libs.koin.core)
    api(libs.kotlin.coroutines.core)
    api(libs.opentelemetry.api)
    implementation(libs.kotlin.serialize.cbor)
    implementation(libs.kotlin.serialize.json)
    implementation(libs.mordant)
    testFixturesApi(testFixtures(project(":messaging")))
    testFixturesApi(testFixtures(project(":telemetry")))
    testFixturesApi(testFixtures(project(":internal-utils")))
    testFixturesApi(libs.kotlin.coroutines.test)
}
