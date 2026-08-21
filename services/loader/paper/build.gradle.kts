plugins {
    id("com.typewritermc.basic-conventions")
}

repositories {
    maven("https://repo.papermc.io/repository/maven-public/")
}

dependencies {
    implementation(project(":loader-core"))
    implementation(project(":loader-standalone"))
    compileOnly(libs.paper.api)
    testImplementation(libs.paper.api)
}
