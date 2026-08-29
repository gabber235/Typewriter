plugins {
    id("com.typewritermc.basic-conventions")
    `java-library`
}

dependencies {
    api(project(":presentation-types"))
    api(libs.bundles.basic.test)
}
