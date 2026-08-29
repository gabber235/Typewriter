plugins {
    id("com.typewritermc.basic-conventions")
    `java-library`
}

dependencies {
    api(project(":discovery-model"))
    api(project(":discovery-runtime"))
    api(libs.bundles.basic.test)
}
