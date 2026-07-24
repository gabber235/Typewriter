package com.typewritermc.services.libs.communicator.address

/** A validated concrete transport address. */
@JvmInline
value class MessageAddress private constructor(val value: String) {
    override fun toString(): String = value

    /** Creates a concrete address from [value]. */
    companion object {
        fun of(value: String): MessageAddress = MessageAddress(validateConcreteAddress(value))
    }
}

/** A validated transport subscription pattern containing literal and `*` segments. */
@JvmInline
value class AddressPattern private constructor(val value: String) {
    override fun toString(): String = value

    /** Creates a subscription pattern from [value]. */
    companion object {
        fun of(value: String): AddressPattern {
            require(value.isNotBlank()) { "Address pattern must not be blank" }
            value.split('.').forEach { segment ->
                require(segment == "*" || validateToken(segment, "Pattern segment") == segment) {
                    "Invalid pattern segment '$segment'"
                }
            }
            return AddressPattern(value)
        }
    }
}

/** Immutable values used to render or parse a typed address. */
class AddressValues private constructor(private val entries: Map<String, String>) {
    /** Names present in this collection. */
    val keys: Set<String> get() = entries.keys

    /** Returns the value for [name], failing when absent. */
    fun require(name: String): String = entries[name] ?: throw IllegalArgumentException("Missing address value '$name'")

    internal fun value(name: String): String? = entries[name]

    /** Creates values with unique names. */
    companion object {
        fun of(vararg values: Pair<String, String>): AddressValues {
            require(values.map { it.first }.distinct().size == values.size) { "Address value keys must be unique" }
            return AddressValues(linkedMapOf(*values))
        }
    }
}

/** Creates immutable typed-address values. */
fun addressValuesOf(vararg values: Pair<String, String>): AddressValues = AddressValues.of(*values)

/** A validated typed address renderer, parser, and transport subscription definition. */
class AddressTemplate<Address : Any> internal constructor(
    template: String,
    private val renderValues: (Address) -> AddressValues,
    private val parseValues: (AddressValues) -> Address,
) {
    private val segments = parseTemplate(template)
    private val placeholders = segments.mapNotNull { it.placeholder }.toSet()

    /** Stable human-readable and telemetry template. */
    val template: String = segments.joinToString(".") { it.source }

    /** Validated wildcard pattern used by transports for subscriptions. */
    val subscriptionPattern: AddressPattern = AddressPattern.of(
        segments.joinToString(".") { if (it.placeholder == null) it.source else "*" },
    )

    /** Renders [address] as a concrete transport address. */
    fun render(address: Address): MessageAddress {
        val values = renderValues(address)
        require(values.keys == placeholders) { "Renderer keys must exactly match placeholders $placeholders" }
        return MessageAddress.of(segments.joinToString(".") { segment ->
            segment.placeholder?.let { validateToken(values.require(it), "Rendered value '$it'") } ?: segment.source
        })
    }

    /** Structurally parses [address], returning null when it does not match. */
    fun match(address: MessageAddress): Address? {
        val actual = address.value.split('.')
        if (actual.size != segments.size) return null
        val values = linkedMapOf<String, String>()
        segments.zip(actual).forEach { (expected, value) ->
            if (expected.placeholder == null && expected.source != value) return null
            expected.placeholder?.let { values[it] = value }
        }
        return parseValues(AddressValues.of(*values.map { it.key to it.value }.toTypedArray()))
    }

    /** Appends a validated literal segment. */
    operator fun div(literal: String): AddressTemplate<Address> {
        validateLiteral(literal)
        return AddressTemplate("$template.$literal", renderValues, parseValues)
    }
}

/** Creates a typed address template. */
fun <Address : Any> addressTemplate(
    pattern: String,
    render: (Address) -> AddressValues,
    parse: (AddressValues) -> Address,
): AddressTemplate<Address> = AddressTemplate(pattern, render, parse)

private data class PatternSegment(val source: String, val placeholder: String?)

private val placeholderName = Regex("[A-Za-z][A-Za-z0-9_]*")

private fun parseTemplate(pattern: String): List<PatternSegment> {
    require(pattern.isNotBlank()) { "Address pattern must not be blank" }
    val raw = pattern.split('.')
    require(raw.none(String::isBlank)) { "Address pattern contains an empty segment" }
    val seen = mutableSetOf<String>()
    return raw.map { token ->
        if (token.startsWith('{') || token.endsWith('}')) {
            require(
                token.startsWith('{') && token.endsWith('}') && token.count { it == '{' } == 1 && token.count { it == '}' } == 1,
            ) { "Malformed placeholder '$token'" }
            val name = token.substring(1, token.lastIndex)
            require(placeholderName.matches(name)) { "Invalid placeholder '$name'" }
            require(seen.add(name)) { "Duplicate placeholder '$name'" }
            PatternSegment(token, name)
        } else {
            validateLiteral(token)
            PatternSegment(token, null)
        }
    }
}

private fun validateConcreteAddress(value: String): String {
    require(value.isNotBlank()) { "Address must not be blank" }
    value.split('.').forEach { validateToken(it, "Address segment") }
    return value
}

private fun validateLiteral(value: String): String = validateToken(value, "Literal segment")

private fun validateToken(value: String, label: String): String {
    require(value.isNotBlank() && value.none(Char::isWhitespace) && value.none { it in ".*>{}" }) {
        "$label is invalid: '$value'"
    }
    return value
}
