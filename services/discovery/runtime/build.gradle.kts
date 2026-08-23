plugins {
    id("com.typewritermc.basic-conventions")
    `java-library`
}

dependencies {
    api(project(":discovery-model"))
    api(platform(libs.koin.bom))
    api(libs.koin.core)
    api(libs.kotlin.coroutines.core)
    testImplementation(libs.bundles.basic.test)
}
