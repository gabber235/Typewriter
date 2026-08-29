plugins { id("com.typewritermc.basic-conventions") }

dependencies {
    api(platform(libs.opentelemetry.bom))
    api(libs.opentelemetry.sdk)
    implementation(libs.logback)
    testImplementation(libs.opentelemetry.sdk.testing)
}
