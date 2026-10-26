import com.typewritermc.buildlogic.CoverageReport
import com.typewritermc.buildlogic.xtaskResults
import kotlinx.kover.gradle.plugin.dsl.KoverProjectExtension

// Writes the services coverage report that `cargo xtask` reads. Apply it to the services root; the root adds the
// merged reports of its included builds to `coverageReport`, because Kover cannot merge across builds.
//
// Run it in the invocation that runs the tests, for example `./gradlew check coverageReport`.
plugins {
    id("com.typewritermc.coverage-merge")
}

val mergedReport = extensions.getByType<KoverProjectExtension>().reports.total.xml.xmlFile

tasks.register<CoverageReport>("coverageReport") {
    group = "verification"
    description = "Writes the merged services coverage, without generated sources, for cargo xtask."
    dependsOn("koverXmlReport")
    koverReports.from(mergedReport)
    // The same generated sources that the detekt and ktlint conventions skip.
    generatedSources.from(
        subprojects.map { project ->
            project.files(
                project.fileTree(project.layout.buildDirectory.dir("generated/ksp")) { include("**/*.kt", "**/*.java") },
                project.fileTree(project.projectDir) {
                    include("**/skirout/**/*.kt")
                    exclude("**/build/**")
                },
            )
        },
    )
    report.set(xtaskResults.resolve("coverage/services.xml"))
}
