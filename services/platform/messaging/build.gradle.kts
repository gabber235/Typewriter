plugins {
    id("com.typewritermc.basic-conventions")
    `java-library`
    `java-test-fixtures`
}

dependencies {
    implementation(project(":internal-utils"))
    implementation(project(":failures"))
    api(project(":telemetry"))
    api(project(":protocol"))
    api(platform(libs.koin.bom))
    api(platform(libs.opentelemetry.bom))
    api(libs.koin.core)
    api(libs.kotlin.coroutines.core)
    api(libs.okio)
    api(libs.opentelemetry.api)
    api(libs.skir.client)
    implementation(libs.cryptography.provider.jdk)
    implementation(libs.nats.core)
    testFixturesApi(testFixtures(project(":telemetry")))
    testFixturesApi(libs.kotlin.serialize.json)
    testImplementation(libs.kotlin.coroutines.test)
    testImplementation(libs.kotest.property)
}
