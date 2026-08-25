plugins {
    id("com.typewritermc.basic-conventions")
    `java-library`
}

dependencies {
    api(project(":page-types"))
    api(libs.bundles.basic.test)
}
