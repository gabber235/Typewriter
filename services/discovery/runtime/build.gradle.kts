plugins {
    id("com.typewritermc.basic-conventions")
    `java-library`
}

dependencies {
    api(project(":discovery-model"))
    api(platform(libs.koin.bom))
    api(libs.koin.core)
    testImplementation(libs.bundles.basic.test)
}
