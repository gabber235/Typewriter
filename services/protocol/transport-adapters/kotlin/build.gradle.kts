plugins {
    id("com.typewritermc.basic-conventions")
    `java-library`
}

kotlin {
    sourceSets.named("main") {
        kotlin.srcDir("skirout")
    }
}

dependencies {
    api(project(":protocol"))
    api(project(":messaging"))
}
