plugins {
    id("com.typewritermc.basic-conventions")
    `java-library`
}

dependencies {
    api(project(":realm-capability-types"))
    api(libs.bundles.basic.test)
}
