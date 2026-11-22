package com.typewritermc.engine.paper

import com.typewritermc.engine.pages.definition
import com.typewritermc.engine.pages.staticPage
import com.typewritermc.formula.Var
import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.ProtagonistDefinition
import com.typewritermc.library.Book
import com.typewritermc.library.BookSetup
import com.typewritermc.library.book
import com.typewritermc.playtest.AttemptContent
import com.typewritermc.playtest.ContentLiveness
import com.typewritermc.playtest.GamePlayer
import com.typewritermc.playtest.LiveContent
import com.typewritermc.playtest.WrittenContent
import com.typewritermc.playtest.awaitApplied
import com.typewritermc.playtest.awaitPublication
import com.typewritermc.realm.testing.boundFormula
import com.typewritermc.setup.SetupList
import com.typewritermc.setup.SetupRoot
import com.typewritermc.setup.setup
import com.typewritermc.types.toSkir
import com.typewritermc.types.use
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.withContext
import java.util.UUID

/**
 * Content a game requirement owns in the stack's Realm, declared with the setup DSL: `content("e1-join-reward") { copy
 * -> library { books.book(copy.book) { ... } } }`. Each attempt writes a copy of its own for its claimed players,
 * publishes it, and once the body ended deletes it and publishes again. The block may read [AttemptCopy.changed] to
 * declare a changed form, which the body asks for with `content.single().change()`.
 */
fun content(
    key: String,
    block: SetupRoot.(AttemptCopy) -> Unit,
): AttemptContent = StackContent(key, block)

/**
 * One attempt's copy of a requirement's content: the [players] it is for, the [book] key its books use, which no other
 * attempt's copy uses, and whether it is the [changed] form the body asked for. Setup ids derive from keys, so a copy
 * keyed with [book] never meets another attempt's, and its changed form changes the fields of the same parts.
 */
class AttemptCopy internal constructor(
    val players: List<GamePlayer>,
    val book: String,
    val changed: Boolean = false,
)

/**
 * This attempt's book, applied only to its one player, as every requirement scopes its book: a Definition on a static
 * page of an audience book holds the player's Protagonist, and the book's condition `protagonist == player` names it.
 * The audience lives in a book of its own because a setup creates each part with its references, so a reference must
 * name a part created before it.
 */
fun SetupList<Book>.attemptBook(
    copy: AttemptCopy,
    configure: BookSetup.() -> Unit,
) {
    val uuid = copy.players.single().uuid
    val protagonist = Protagonist(PrincipalId(PrincipalId.MINECRAFT, uuid.toString()))
    val player =
        book("${copy.book}-audience") {
            title = "${copy.book} audience"
            pages.staticPage("audience") {
                elements.definition<Protagonist>("player", ProtagonistDefinition.id.use()) {
                    name = "player"
                    value = Var.Value(protagonist)
                }
            }
        }
    book(copy.book) {
        title = copy.book
        condition = Var.Computed(boundFormula("protagonist == player", mapOf("player" to player.id.toSkir())))
        configure()
    }
}

/**
 * Says when the stack's content runs on Paper: once the Typewriter engine there applies every root the content
 * publishes and none it removed, and the publication the Realm selects now, which carries every change saved before it,
 * as the playtest bridge extension on that engine reports.
 *
 * TODO(node 9): replace with the engine's reported active publication ("applied on N of M").
 */
private val StackLiveness =
    ContentLiveness { paper, content ->
        paper.awaitApplied(content)
        paper.awaitPublication { StackAuthor.shared().selectedPublication() }
    }

private class StackContent(
    override val key: String,
    private val block: SetupRoot.(AttemptCopy) -> Unit,
) : AttemptContent {
    override val liveness: ContentLiveness = StackLiveness

    override suspend fun write(players: List<GamePlayer>): WrittenContent {
        val copy = AttemptCopy(players, "$key-${UUID.randomUUID().toString().take(COPY_SUFFIX)}")
        var content = setup(copy.book) { block(copy) }
        val author = StackAuthor.shared()
        author.write(content)
        val roots =
            try {
                author.publishPresent(content.resources.mapTo(mutableSetOf()) { it.value })
            } catch (
                @Suppress("TooGenericExceptionCaught") unpublished: Throwable,
            ) {
                withContext(NonCancellable) { runCatching { author.remove(content) }.exceptionOrNull()?.let(unpublished::addSuppressed) }
                throw unpublished
            }
        return object : WrittenContent {
            override val live = LiveContent(present = roots)
            private var removed = false

            override suspend fun change(): LiveContent {
                val changed = setup(copy.book) { block(AttemptCopy(copy.players, copy.book, changed = true)) }
                author.change(content, changed)
                content = changed
                return LiveContent(present = roots)
            }

            override suspend fun remove(): LiveContent {
                if (!removed) {
                    author.remove(content)
                    author.publishAbsent(roots)
                    removed = true
                }
                return LiveContent(absent = roots)
            }
        }
    }
}

/** How many characters of a random id set one attempt's copy apart. */
private const val COPY_SUFFIX = 8
