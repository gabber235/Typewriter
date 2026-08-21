plugins {
    id("com.typewritermc.basic-conventions")
}

dependencies {
    implementation(project(":loader-core"))
    implementation(platform(libs.koin.bom))
    implementation(libs.koin.core)
    testImplementation(libs.kotlin.coroutines.test)
}
