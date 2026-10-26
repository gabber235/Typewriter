plugins {
    id("com.typewritermc.basic-conventions")
    `java-library`
    `java-test-fixtures`
}

dependencies {
    implementation(project(":internal-utils"))
    api(platform(libs.koin.bom))
    api(platform(libs.opentelemetry.bom))
    api(libs.koin.core)
    api(libs.kotlin.coroutines.core)
    api(libs.opentelemetry.api)
    api(libs.opentelemetry.sdk)
    implementation(libs.logback)
    implementation(libs.opentelemetry.kotlin)
    implementation(libs.opentelemetry.semconv)
    testFixturesApi(libs.opentelemetry.sdk.testing)
    testImplementation(libs.kotlin.coroutines.test)
}
