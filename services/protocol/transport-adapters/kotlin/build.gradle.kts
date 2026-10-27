plugins {
    id("com.typewritermc.basic-conventions")
    `java-library`
    `java-test-fixtures`
}

kotlin {
    sourceSets.named("main") {
        kotlin.srcDir("skirout")
    }
}

dependencies {
    api(project(":protocol"))
    api(project(":messaging"))
    testFixturesApi(testFixtures(project(":messaging")))
    testFixturesApi(testFixtures(project(":telemetry")))
}
