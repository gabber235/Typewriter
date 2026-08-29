plugins {
    id("com.typewritermc.basic-conventions")
    `java-library`
}

dependencies {
    api(project(":element-types"))
    api("com.typewritermc:discovery-testing")
    api(libs.bundles.basic.test)
}
