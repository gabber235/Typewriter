plugins {
    id("com.typewritermc.basic-conventions")
    alias(libs.plugins.ksp)
    alias(libs.plugins.kotlin.serialize)
    `java-library`
    `java-test-fixtures`
}

kotlin {
    sourceSets.named("main") {
        kotlin.srcDir("src/main/skirout")
    }
}

dependencies {
    api(project(":typewriter-contracts"))
    api(platform(libs.koin.bom))
    api(libs.koin.core)
    api(libs.kotlin.coroutines.core)
    implementation(libs.kotlin.reflect)
    ksp(project(":typewriter-codegen"))
    testFixturesApi(libs.kotlin.serialize.json)
    testFixturesApi(libs.kotest.property)
    // The kit builds on this module; its own jar must not join the test classpath beside the main classes.
    testFixturesApi(project(":typewriter-test-kit")) { exclude(module = "typewriter-api") }
}

ksp {
    arg("typewriter.artifactId", "typewritermc:core")
    arg("typewriter.sourcePart", "main")
    arg("typewriter.claimDependencyClosure", "true")
}

tasks.test {
    // The structural depth fixtures nest expressions about a thousand levels deep, and the Skir JSON
    // codecs they round trip through recurse once per level. The default thread stack is too small for
    // that on some platforms, so test threads get a stack with room to spare.
    jvmArgs("-Xss8m")
}

val writeSdkFixtures by tasks.registering(JavaExec::class) {
    group = "build"
    description = "Writes the canonical read schema, the compiled control fixtures and the expression differential corpus."
    classpath = sourceSets.testFixtures.get().runtimeClasspath
    mainClass = "com.typewritermc.fixtures.SdkFixtureWriterKt"
    val fixtures = layout.buildDirectory.dir("fixtures")
    args(
        rootDir.resolve("../skir-src/editor/v1/fixtures/canonical_read_models.json").absolutePath,
        fixtures
            .get()
            .dir("controls")
            .asFile.absolutePath,
        fixtures
            .get()
            .file("expression_corpus.json")
            .asFile.absolutePath,
    )
}
