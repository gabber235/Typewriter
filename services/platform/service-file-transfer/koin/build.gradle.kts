plugins {
    id("com.typewritermc.basic-conventions")
}

dependencies {
    implementation(project(":service-file-transfer-core"))
    implementation(platform(libs.koin.bom))
    implementation(libs.koin.core)
}
