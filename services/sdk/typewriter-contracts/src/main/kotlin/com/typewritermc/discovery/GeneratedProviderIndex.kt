package com.typewritermc.discovery

/** Kind of a generated provider. [key] is the stable token stored in the provider index. */
enum class GeneratedProviderKind(
    val key: String,
) {
    Type("type"),
    NativeBinding("nativeBinding"),
    Relation("relation"),
    EndpointBindings("endpointBindings"),
    Configuration("configuration"),
    Presentation("presentation"),
    Check("check"),
    Capability("capability"),
    Registrar("registrar"),
    CollectionProjection("collectionProjection"),
    ResourceOperation("resourceOperation"),
    ResourceDisplay("resourceDisplay"),
}

/** Classpath resource that lists the generated providers of one compiled source part. */
const val GENERATED_PROVIDER_INDEX_PATH: String = "META-INF/typewriter/generated-providers"

/** One provider index row. [providerClass] is a binary class name, so nested providers use `Outer$Inner`. */
data class GeneratedProviderIndexEntry(
    val kind: GeneratedProviderKind,
    val providerClass: String,
    val sourcePart: String,
)

/**
 * Owns the tab separated provider index format shared by the KSP writer and artifact discovery.
 *
 * Both directions reject malformed rows, so a writer cannot produce an index the reader refuses.
 */
object GeneratedProviderIndex {
    /** Source part names are safe index columns and safe identifiers in generated names. */
    val SOURCE_PART: Regex = Regex("[A-Za-z][A-Za-z0-9_]*")
    private val QUALIFIED_CLASS = Regex("[A-Za-z_$][A-Za-z0-9_$]*(\\.[A-Za-z_$][A-Za-z0-9_$]*)+")

    /** Parses index [content], rejecting unknown kinds, malformed columns, and duplicate rows. */
    fun parse(content: String): List<GeneratedProviderIndexEntry> {
        val kinds = GeneratedProviderKind.entries.associateBy(GeneratedProviderKind::key)
        val entries =
            content
                .lineSequence()
                .map(String::trim)
                .filter(String::isNotEmpty)
                .mapIndexed { index, line ->
                    val columns = line.split('\t')
                    require(columns.size == 3 && columns.none(String::isBlank)) {
                        "Generated provider index line ${index + 1} must contain kind, provider class, and source part."
                    }
                    val kind =
                        requireNotNull(kinds[columns[0]]) {
                            "Generated provider index line ${index + 1} uses unknown kind ${columns[0]}."
                        }
                    require(columns[1].matches(QUALIFIED_CLASS)) {
                        "Generated provider index line ${index + 1} has an invalid provider class."
                    }
                    require(columns[2].matches(SOURCE_PART)) {
                        "Generated provider index line ${index + 1} has an invalid source part."
                    }
                    GeneratedProviderIndexEntry(kind, columns[1], columns[2])
                }.toList()
        require(entries.distinct().size == entries.size) { "Generated provider index contains duplicate rows." }
        return entries
    }

    /** Renders [entries] in a deterministic order, so incremental and clean builds write identical bytes. */
    fun render(entries: Collection<GeneratedProviderIndexEntry>): String =
        entries
            .onEach { entry ->
                require(entry.providerClass.matches(QUALIFIED_CLASS)) { "Invalid provider class ${entry.providerClass}." }
                require(entry.sourcePart.matches(SOURCE_PART)) { "Invalid source part ${entry.sourcePart}." }
            }.distinct()
            .sortedWith(compareBy({ it.kind.key }, { it.providerClass }, { it.sourcePart }))
            .joinToString("") { "${it.kind.key}\t${it.providerClass}\t${it.sourcePart}\n" }
}

/** A runtime registrar id; safe to use as one path segment. */
@JvmInline
value class RuntimeRegistrarId(
    val value: String,
) {
    init {
        require(isValid(value)) { "Runtime registrar ids must be safe path segments." }
    }

    override fun toString(): String = value

    companion object {
        private val PATTERN = Regex("[A-Za-z0-9][A-Za-z0-9_.]*")

        /** Returns whether [value] satisfies the registrar id rule, for callers that report instead of throwing. */
        fun isValid(value: String): Boolean = PATTERN.matches(value)
    }
}
