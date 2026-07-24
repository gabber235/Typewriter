package com.typewritermc.services.libs.communicator.transport

import com.typewritermc.services.libs.communicator.address.AddressPattern
import com.typewritermc.services.libs.communicator.address.MessageAddress
import kotlinx.coroutines.flow.Flow
import java.util.*
import kotlin.time.Duration

/** Immutable, case-insensitive, multi-value message headers with validated names and values. */
class MessageHeaders private constructor(
    private val entries: Map<String, HeaderEntry>,
) : Iterable<Pair<String, List<String>>> {
    /** Returns an immutable list of values for [name], in insertion order. */
    operator fun get(name: String): List<String> = entries[canonicalName(name)]?.values ?: emptyList()

    /** Returns the first value for [name], or null when absent. */
    fun first(name: String): String? = get(name).firstOrNull()

    /** Returns whether [name] is present, ignoring casing. */
    fun contains(name: String): Boolean = entries.containsKey(canonicalName(name))

    /** Returns a new collection with [value] appended under [name]. */
    fun plus(name: String, value: String): MessageHeaders {
        validateHeaderName(name)
        validateHeaderValue(value)
        val canonicalName = canonicalName(name)
        val current = entries[canonicalName]
        val values = immutableList(current?.values.orEmpty() + value)
        val updated = LinkedHashMap(entries)
        updated[canonicalName] = HeaderEntry(current?.displayName ?: name, values)
        return MessageHeaders(Collections.unmodifiableMap(updated))
    }

    /** Returns a new collection without values under [name]. */
    fun remove(name: String): MessageHeaders {
        val updated = LinkedHashMap(entries)
        updated.remove(canonicalName(name))
        return MessageHeaders(Collections.unmodifiableMap(updated))
    }

    /** Returns a new collection replacing all values under [name] with [value]. */
    fun set(name: String, value: String): MessageHeaders {
        validateHeaderName(name)
        validateHeaderValue(value)
        val updated = LinkedHashMap(entries)
        updated[canonicalName(name)] = HeaderEntry(name, immutableList(listOf(value)))
        return MessageHeaders(Collections.unmodifiableMap(updated))
    }

    /** Iterates stable display names and immutable value lists. */
    override fun iterator(): Iterator<Pair<String, List<String>>> =
        entries.values.map { it.displayName to it.values }.iterator()

    override fun equals(other: Any?): Boolean = other is MessageHeaders && canonicalValues() == other.canonicalValues()

    override fun hashCode(): Int = canonicalValues().hashCode()

    override fun toString(): String = entries.values.joinToString(
        prefix = "MessageHeaders(",
        postfix = ")",
    ) { "${it.displayName}=${it.values}" }

    private fun canonicalValues(): Map<String, List<String>> = entries.mapValues { it.value.values }

    /** Creates validated immutable headers. */
    companion object {
        val Empty: MessageHeaders = MessageHeaders(emptyMap())

        fun of(vararg headers: Pair<String, String>): MessageHeaders =
            headers.fold(Empty) { result, (name, value) -> result.plus(name, value) }
    }

    private data class HeaderEntry(val displayName: String, val values: List<String>)
}

/** Outbound envelope. The payload and headers are owned by the caller and compared by content. */
data class OutboundMessage(
    val address: MessageAddress,
    val payload: ByteArray,
    val replyTo: MessageAddress? = null,
    val headers: MessageHeaders = MessageHeaders.Empty,
) {
    override fun equals(other: Any?): Boolean =
        other is OutboundMessage && address == other.address && payload.contentEquals(other.payload) && replyTo == other.replyTo && headers == other.headers

    override fun hashCode(): Int {
        var result = address.hashCode()
        result = 31 * result + payload.contentHashCode()
        result = 31 * result + (replyTo?.hashCode() ?: 0)
        result = 31 * result + headers.hashCode()
        return result
    }
}

/** Inbound envelope. The payload and headers are owned by the transport and compared by content. */
data class InboundMessage(
    val address: MessageAddress,
    val payload: ByteArray,
    val replyTo: MessageAddress? = null,
    val headers: MessageHeaders = MessageHeaders.Empty,
) {
    override fun equals(other: Any?): Boolean =
        other is InboundMessage && address == other.address && payload.contentEquals(other.payload) && replyTo == other.replyTo && headers == other.headers

    override fun hashCode(): Int {
        var result = address.hashCode()
        result = 31 * result + payload.contentHashCode()
        result = 31 * result + (replyTo?.hashCode() ?: 0)
        result = 31 * result + headers.hashCode()
        return result
    }
}

/** Stable identifier for a messaging transport. */
@JvmInline
value class MessagingSystem private constructor(val value: String) {
    companion object {
        fun of(value: String): MessagingSystem {
            require(value.matches(Regex("[a-z][a-z0-9-]*"))) { "Invalid messaging system '$value'" }
            return MessagingSystem(value)
        }
    }
}

/** A validated transport-neutral subscription consumer group. */
@JvmInline
value class ConsumerGroup private constructor(val value: String) {
    /** Creates a non-blank consumer group. */
    companion object {
        fun of(value: String): ConsumerGroup {
            require(value.isNotBlank()) { "Consumer group must not be blank" }
            require(value.none(Char::isWhitespace)) { "Consumer group must not contain whitespace" }
            return ConsumerGroup(value)
        }
    }
}

/** Options applied while creating a transport subscription. */
data class SubscriptionOptions(val consumerGroup: ConsumerGroup? = null)

/** Explicit success or transport failure. */
sealed interface TransportResult<out Value> {
    data class Success<Value>(val value: Value) : TransportResult<Value>
    data class Failure(val error: TransportError) : TransportResult<Nothing>
}

/** Failures adapters return explicitly; cancellation is thrown unchanged. */
sealed interface TransportError {
    val cause: Throwable?

    data class Timeout(override val cause: Throwable? = null) : TransportError
    data class Unavailable(override val cause: Throwable? = null) : TransportError
    data class NoResponders(override val cause: Throwable? = null) : TransportError
    data class Failure(override val cause: Throwable) : TransportError
}

/** A delivered message, terminal failure, or clean completion. */
sealed interface TransportDelivery {
    data class Message(val message: InboundMessage) : TransportDelivery
    data class Failure(val error: TransportError) : TransportDelivery
    data object Completed : TransportDelivery
}

/** A subscription whose deliveries stop on cancellation or explicit suspending close. */
interface TransportSubscription {
    val deliveries: Flow<TransportDelivery>
    suspend fun close()
}

/** Adapter SPI whose operational failures are returned and whose cancellation remains explicit. */
interface MessageTransport {
    val system: MessagingSystem
    suspend fun publish(message: OutboundMessage): TransportResult<Unit>
    suspend fun request(message: OutboundMessage, timeout: Duration): TransportResult<InboundMessage>
    suspend fun subscribe(
        pattern: AddressPattern,
        options: SubscriptionOptions = SubscriptionOptions(),
    ): TransportResult<TransportSubscription>
}

private val headerNamePattern = Regex("[!#$%&'*+.^_`|~0-9A-Za-z-]+")

private fun canonicalName(name: String): String = name.lowercase(Locale.ROOT)

private fun validateHeaderName(name: String) {
    require(headerNamePattern.matches(name)) { "Invalid header name '$name'" }
}

private fun validateHeaderValue(value: String) {
    require(value.none { it == '\u007f' || (it < ' ' && it != '\t') }) { "Header value contains a disallowed control character" }
}

private fun <Value> immutableList(values: List<Value>): List<Value> = Collections.unmodifiableList(ArrayList(values))
