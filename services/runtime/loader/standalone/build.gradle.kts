plugins {
    id("com.typewritermc.basic-conventions")
}

version = "1000.0.0"

dependencies {
    implementation(project(":loader-core"))
    implementation(libs.clikt)
    implementation(libs.jline)
    testImplementation(libs.kotlin.coroutines.test)
    testImplementation("com.typewritermc:service-telemetry-testing")
    testImplementation(libs.mockk)
}
