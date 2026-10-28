package com.typewritermc.buildlogic

import org.gradle.api.DefaultTask
import org.gradle.api.file.ConfigurableFileCollection
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.tasks.InputFiles
import org.gradle.api.tasks.OutputFile
import org.gradle.api.tasks.PathSensitive
import org.gradle.api.tasks.PathSensitivity
import org.gradle.api.tasks.TaskAction
import org.w3c.dom.Element
import java.io.File
import javax.xml.parsers.DocumentBuilderFactory
import javax.xml.transform.OutputKeys
import javax.xml.transform.TransformerFactory
import javax.xml.transform.dom.DOMSource
import javax.xml.transform.stream.StreamResult

/**
 * Combines merged Kover reports into one JaCoCo XML report without the classes compiled from generated sources.
 *
 * Kover merges projects of one Gradle build only, so each build contributes its own merged report; this task
 * appends their packages and adds up their totals.
 *
 * Kover filters classes by name only, and generated files share packages with handwritten ones. This task
 * therefore removes every `sourcefile` and `class` element whose package and file name belong to a generated
 * source, and subtracts the removed class counters from their package and from the report totals.
 */
abstract class CoverageReport : DefaultTask() {
    /** JaCoCo format XML reports written by Kover's merged `koverXmlReport`, one per Gradle build. */
    @get:InputFiles
    @get:PathSensitive(PathSensitivity.NONE)
    abstract val koverReports: ConfigurableFileCollection

    /** Generated Kotlin and Java sources whose classes are left out of the report. */
    @get:InputFiles
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val generatedSources: ConfigurableFileCollection

    @get:OutputFile
    abstract val report: RegularFileProperty

    @TaskAction
    fun write() {
        val generated = generatedSources.files.mapNotNullTo(mutableSetOf(), File::sourceKey)
        val factory =
            DocumentBuilderFactory.newInstance().apply {
                // JaCoCo reports declare a DTD that is neither bundled nor needed to read them.
                setFeature("http://apache.org/xml/features/nonvalidating/load-external-dtd", false)
                isValidating = false
            }
        val builder = factory.newDocumentBuilder()
        val (document, others) = koverReports.files.map(builder::parse).let { it.first() to it.drop(1) }
        val root = document.documentElement
        for (other in others) {
            val otherRoot = other.documentElement
            for (pack in otherRoot.children("package")) {
                root.insertBefore(document.importNode(pack, true), root.firstCounter())
            }
            root.add(otherRoot.counters())
        }
        val removedFromReport = mutableMapOf<String, Counter>()

        for (pack in root.children("package")) {
            val packageName = pack.getAttribute("name")
            fun isGenerated(fileName: String) = "$packageName/$fileName" in generated

            val removedFromPackage = mutableMapOf<String, Counter>()
            for (type in pack.children("class").filter { isGenerated(it.getAttribute("sourcefilename")) }) {
                type.counters().forEach { (kind, counter) -> removedFromPackage.add(kind, counter) }
                pack.removeChild(type)
            }
            pack.children("sourcefile").filter { isGenerated(it.getAttribute("name")) }.forEach(pack::removeChild)

            if (pack.children("class").isEmpty()) {
                pack.counters().forEach { (kind, counter) -> removedFromReport.add(kind, counter) }
                root.removeChild(pack)
            } else {
                pack.subtract(removedFromPackage)
                removedFromPackage.forEach { (kind, counter) -> removedFromReport.add(kind, counter) }
            }
        }
        root.subtract(removedFromReport)

        val target = report.get().asFile
        target.parentFile.mkdirs()
        TransformerFactory.newInstance().newTransformer().apply {
            setOutputProperty(OutputKeys.ENCODING, "UTF-8")
            setOutputProperty(OutputKeys.STANDALONE, "yes")
        }.transform(DOMSource(document), StreamResult(target))
    }
}

private data class Counter(
    val missed: Long,
    val covered: Long,
) {
    operator fun plus(other: Counter) = Counter(missed + other.missed, covered + other.covered)

    operator fun unaryMinus() = Counter(-missed, -covered)
}

private val packageDeclaration = Regex("""^\s*package\s+([\w.]+)""", RegexOption.MULTILINE)

/** `package/path/File.kt`, the key JaCoCo XML gives a source file through its package and file name. */
private fun File.sourceKey(): String? {
    val packageName = packageDeclaration.find(readText())?.groupValues?.get(1) ?: return null
    return "${packageName.replace('.', '/')}/$name"
}

private fun Element.children(tag: String): List<Element> =
    (0 until childNodes.length).map(childNodes::item).filterIsInstance<Element>().filter { it.tagName == tag }

private fun Element.counters(): Map<String, Counter> =
    children("counter").associate {
        it.getAttribute("type") to Counter(it.getAttribute("missed").toLong(), it.getAttribute("covered").toLong())
    }

private fun MutableMap<String, Counter>.add(
    kind: String,
    counter: Counter,
) {
    merge(kind, counter, Counter::plus)
}

private fun Element.subtract(removed: Map<String, Counter>) = add(removed.mapValues { (_, counter) -> -counter })

private fun Element.firstCounter(): Element? = children("counter").firstOrNull()

private fun Element.add(added: Map<String, Counter>) {
    val existing = children("counter").associateBy { it.getAttribute("type") }
    for ((kind, counter) in added) {
        val element =
            existing[kind] ?: ownerDocument.createElement("counter").also {
                it.setAttribute("type", kind)
                it.setAttribute("missed", "0")
                it.setAttribute("covered", "0")
                appendChild(it)
            }
        element.setAttribute("missed", (element.getAttribute("missed").toLong() + counter.missed).toString())
        element.setAttribute("covered", (element.getAttribute("covered").toLong() + counter.covered).toString())
    }
}
